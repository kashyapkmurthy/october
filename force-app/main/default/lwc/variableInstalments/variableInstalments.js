import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import momentJs from '@salesforce/resourceUrl/momentjs_2_29_1';
import { loadStyle, loadScript} from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ID_FIELD  from '@salesforce/schema/Case.Id';
import INSTALMNT_FIELD from '@salesforce/schema/Case.LSC_InstalmentDetails__c';
import isRecordLocked from '@salesforce/apex/LSC_LevyPaymentUtility.checkRecordLocked';
import { refreshApex } from '@salesforce/apex';
import formFactorPropertyName from '@salesforce/client/formFactor';
const maxStageLimit = 10;
const minStageLimit = 2;
const minAmoutForLevyPay = 25000;
const FIELDS = [
  'Case.LSC_InstalmentDetails__c',
  'Case.LSC_LevyId__r.LSC_ConstructionStartDate__c',
  'Case.LSC_LevyId__r.LSC_ConstructionEndDate__c',
  'Case.LSC_LevyId__r.LSC_CostOfWorks__c',
  'Case.LSC_LevyId__r.LSC_LevyPayable__c',
  'Case.Type',
  'Case.Status',
  'Case.IsClosed'
]

export default class VariableInstalments extends LightningElement {
  @api recordId;
  @api developCostsData;
  developCostsDataForPresetInstalment = {};
  estimatedCost;
  proposdStartDate;
  @api variableInstalData = [];
  @track data = [];
  tempData = [];
  index = 0;
  totalLevyAmt=0;
  instalmentDetails = [];
  existingInstalmentDetails = [];
  existingCurrentIndex = 0;
  error = false;
  caseType = "Staged instalments";
  caseClosed;
  caseStatus;
  result;
  //Used for Salesforce UI
  appNumber;
  readOnly = false;
  saveButtnDisabled = true;
  cancelButtnDisabled = true; 
  //Holds Development details and costs screen values
  startDate;
  endDate;
  totalCost;
  levyAmount;

  @wire(isRecordLocked, {recordId : '$recordId'})
  recordLocked(result) {
    this.result = result;
    if(result.data) {
      console.log('data retrieved islocked');
        this.readOnly = result.data;
    }
    if(result.error) {
        console.log('error...'+JSON.stringify(result.error));
    }
  }

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  caseRecordDetails(result) {
      if (result.error) {
          this.error = result.error;
      } else if (result.data) {
        this.index = 0;
        this.instalmentDetails = JSON.parse(result.data.fields.LSC_InstalmentDetails__c.value);
        this.startDate = result.data.fields.LSC_LevyId__r.value.fields.LSC_ConstructionStartDate__c.value;
        this.endDate = result.data.fields.LSC_LevyId__r.value.fields.LSC_ConstructionEndDate__c.value;
        this.totalCost = result.data.fields.LSC_LevyId__r.value.fields.LSC_CostOfWorks__c.value;
        this.levyAmount = result.data.fields.LSC_LevyId__r.value.fields.LSC_LevyPayable__c.value;
        this.caseType = result.data.fields.Type.value;
        this.caseClosed = result.data.fields.IsClosed.value;
        this.caseStatus = result.data.fields.Status.value;
        if(this.caseClosed === true)
          this.readOnly = true;
        else if(this.caseStatus != 'Pending Approval')
          this.readOnly = false;
        this.parseInputData();
        if (this.caseType === 'Equal instalments') {
          this.developCostsDataForPresetInstalment = {
            ...this.developCostsDataForPresetInstalment,
            ...{
              levyPayable: this.levyAmount,
              totalBuildConstCost: this.totalCost,
              startDate: this.startDate,
              endDate: this.endDate
            }
          };
        }
      }
  }

  parseInputData(){
    if(this.instalmentDetails && this.instalmentDetails.length > 0){
      let tempArray = [];
      let appNo;
      for(let i = 0 ; i < this.instalmentDetails.length; i++){
        let tempObj = {};
        if(i==0)
          appNo = this.instalmentDetails[i].payNo; 
        tempObj.id = i;
        tempObj.stage = this.instalmentDetails[i].payNo;
        tempObj.startDate = this.instalmentDetails[i].startDate;
        tempObj.estimatedCost = this.instalmentDetails[i].estimatedCost;
        tempObj.levyAmt = this.instalmentDetails[i].levyAmt;
        tempObj.showDel = this.instalmentDetails[i].showDel;
        tempObj.totalCost = this.instalmentDetails[i].totalCost;
        tempObj.totalLevyAmt = this.instalmentDetails[i].totalLevyAmt;
        tempArray.push(tempObj);
      }
      this.appNumber = appNo.substring(0, appNo.lastIndexOf('/'));
      this.createArrayData(tempArray.length - 1);
      this.createArrayLastRow();
      this.data = tempArray;
      this.existingInstalmentDetails = tempArray;
      this.existingCurrentIndex = this.index;
    }
  }
  connectedCallback() {
    console.log('In variable instalments connected callback');
    //Execute below if the lwc is in Experience builder context
    if(!this.recordId){
      this.appNumber = this.developCostsData.appNumber;
      this.startDate = this.developCostsData.startDate;
      this.endDate = this.developCostsData.endDate;
      this.totalCost = this.developCostsData.totalBuildingCost;
      this.levyAmount = this.developCostsData.levyPayable;
      if(this.variableInstalData.length > 0){
        this.createArrayData(this.variableInstalData.length-1);
        this.createArrayLastRow();
        this.data = this.variableInstalData;
      } else{
          this.createArrayData(4);
          this.createArrayLastRow();
      }
    }
  }

  get horizontalPaddingDelICon() {
    return formFactorPropertyName !== 'Large' ? 'horizontal-medium' : '';
  }

  get smallMediumDevView() {
    return formFactorPropertyName !== 'Large' ? true : false;
  }

  get experienceBuilder(){
    return this.recordId ? false : true;
  }

  get verticalPaddingDelIcon(){
    return this.experienceBuilder? (formFactorPropertyName === 'Large'? 'slds-var-p-top_xx-large' : 'slds-var-p-vertical_small') : 'slds-var-p-top_x-large';
  }

  get equalInstalments(){
    return this.caseType == 'Equal instalments'? true : false;
  }

  renderedCallback(){
    console.log('In rendered callback');
    Promise.all([loadScript(this,momentJs)]).then(() =>{
    }).catch(error => {
        this.error = error;
    });
    refreshApex(this.result);
  }

  handleAddRow(event){
    this.saveButtnDisabled = false;
    this.cancelButtnDisabled = false;
    this.createArrayData(1);
  }

  get showAddMore(){
    return this.index < maxStageLimit;
  }

  get totalCostErrorMessage(){
    return "Please make sure sum of each stage estimated cost is equal to total provided cost $"+this.totalCost.toString();
  }

  createArrayData(numberOfEle){
    console.log('In create array callback...'+numberOfEle);
    console.log('Index...'+this.index);
    
    if(this.index < maxStageLimit){
      console.log( 'insde if');
      console.log(JSON.stringify(this.data));
      let dataTempArr = JSON.parse(JSON.stringify(this.data));
      //clear showDelete button flag
      dataTempArr.forEach(element => {
        console.log('element...'+JSON.stringify(element));
        if(element.showDel) {
          element.showDel = false;
        }
      });
      this.data = [...dataTempArr];
      console.log(JSON.stringify(this.data));
      
      //create array
      for(let i = 0 ; i < numberOfEle; i++){
        let forIndex = i;
        console.log( 'in for');
        let tempParams = {};
        tempParams.bckgrndColor = (this.smallMediumDevView && ((i & 1) || (this.index & 1)))? 'layout-backgrnd-color' : '';
        tempParams.id = this.arrIndex;
        tempParams.stage = this.appNumber + '/'+ (++this.index);
        tempParams.startDate = "";
        tempParams.estimatedCost;
        tempParams.levyAmt = 0;
        //Show Delete icon on last element
        tempParams.showDel = ((this.index > minStageLimit) && (++forIndex) === numberOfEle) ? true : false;
        //Insert before last row
        let temp = JSON.parse(JSON.stringify(this.data));
        temp.splice((this.index-1),0,tempParams);
        this.data = temp;
      }
      //Update id of last row (total costs) after insertion of the rows
      if(this.data[this.index]) this.data[this.index].id = this.index;
      console.log( 'dataarray....'+JSON.stringify(this.data));
    }else{
      console.log('error');
    }
  }

  createArrayLastRow(){
    let tempParams = {};
    tempParams.id = this.arrIndex;
    tempParams.totalCost = 0;
    tempParams.totalLevyAmt = 0;
    this.data.push(tempParams);
    console.log( 'dataarray in lastrow....'+JSON.stringify(this.data));
  }

  get arrIndex(){
    return this.index;
  }

  get showErrorMess(){
     return this.error === true;
  }

  deleteRow(event){
    this.saveButtnDisabled = false;
    this.cancelButtnDisabled = false;
    let tempFilterArray = JSON.parse(JSON.stringify(this.data));
    tempFilterArray = tempFilterArray.filter(function (element) {
      console.log('del element id...'+element.id);
      console.log('del element access...'+event.target.accessKey);
      return parseInt(element.id) !== parseInt(event.target.accessKey);
    });
    this.data = [...tempFilterArray];

    //show Delete icon from 3rd row
    let setShowDelIndex = parseInt(event.target.accessKey)-1;
    if(setShowDelIndex > 1){
      this.data[setShowDelIndex].showDel = true;
    }
    //Decrement Index
    this.index--;
    if(this.data[this.index]) this.data[this.index].id = this.index;    

    let tempArray = JSON.parse(JSON.stringify(this.data));
    tempArray[0].levyAmt = Math.floor(tempArray[0].estimatedCost * 0.0035);
    //Recalculate Total amounts on row deletion
    this.updateTotalAmounts(tempArray);
  }

  handleCostChange(event){
    this.saveButtnDisabled = false;
    this.cancelButtnDisabled = false;
    let estCostVal = event.target.value;
    let key = event.currentTarget.dataset.index;
    let tempArray = [];
    tempArray = JSON.parse(JSON.stringify(this.data));
    if(estCostVal < minAmoutForLevyPay){
      this.setInputValidity(event.target, "Estimated Cost must be greater than or equal to $25000");
      tempArray[parseInt(key)].estimatedCost = parseFloat(estCostVal);
      tempArray[parseInt(key)].levyAmt = 0;
    } 
    else {
      this.setInputValidity(event.target,"");
      tempArray[parseInt(key)].estimatedCost = parseFloat(estCostVal);
      let levyAmt = Math.floor(estCostVal*0.0035); 
      tempArray[parseInt(key)].levyAmt = levyAmt;
      tempArray[0].levyAmt = Math.floor(tempArray[0].estimatedCost * 0.0035);
    }
    //Recalculate Total amounts on cost change
    this.updateTotalAmounts(tempArray);
  }

  updateTotalAmounts(tempArray){
    let totalCost = 0;
    let totalLevyAmt = 0;
    //Update Total cost and Total levy amount
    tempArray.forEach(element =>{
      if(element.estimatedCost) totalCost += element.estimatedCost;
      if(element.levyAmt) totalLevyAmt += element.levyAmt;
    });
    if(parseFloat(totalCost).toFixed(2) == parseFloat(this.totalCost)){
      this.error = false;
      console.log('I am here entered..'+this.levyAmount);
      console.log('I am here calc...'+totalLevyAmt);
      tempArray[0].levyAmt = Math.floor(tempArray[0].estimatedCost * 0.0035) + (this.levyAmount - totalLevyAmt);
      totalLevyAmt = 0;
      //Update Total cost and Total levy amount
      tempArray.forEach(element =>{
        if(element.levyAmt) totalLevyAmt += element.levyAmt;
      });   
    }
    tempArray[this.index].totalCost = parseFloat(totalCost).toFixed(2);
    tempArray[this.index].totalLevyAmt = parseFloat(Math.floor(totalLevyAmt)); 
    this.data = [...tempArray];
  }

  @api
  validateAllFields(){
      let isAscending = true;
      let prevDate;
      //Validate variable instalment inputs
      this.template.querySelectorAll('lightning-input').forEach(element => {
          if(element.name === "startDate" ){
            if(element.value && !(moment(element.value).isSameOrAfter(moment(this.startDate)) && 
            moment(element.value).isSameOrBefore(moment(this.endDate)))){
              this.setInputValidity(element, "Date must be between Estimated Start Date and Estimated End Date");
            }
            else if(prevDate){
              console.log('in loop....');
              isAscending = isAscending && (element.value > prevDate);
              if(isAscending){
                this.setInputValidity(element,"");
              } else{
                this.setInputValidity(element, "Stage proposed start date can’t be less than or equal to previous stage start date");
                //Reset flag
                isAscending = true;
              }
            } else{
              this.setInputValidity(element,"");
            }
            prevDate = element.value;
          } else if(element.name === "totalCost"){
            if(element.value != parseFloat(this.totalCost)){
              this.setInputValidity(element, this.totalCostErrorMessage);
              console.log('total cost validation');
              this.error = true;
            }else{
              this.setInputValidity(element, "");
              this.error = false;
            }
          } 
      });
      let finalResult = this.checkInputValidty() && !this.error;
      if(finalResult && this.experienceBuilder){
        const variableInstalEvent = new CustomEvent('updatevariableinstalments', {  detail : this.data});
        // Dispatches the event.
        this.dispatchEvent(variableInstalEvent); 
      } else if(finalResult && !this.experienceBuilder){
        console.log('All good Salesforce UI');
        //save the case record with new Instalment payload
        this.updateCaseRecord();
      } else{
        console.log('not saving...conditions not satisfied');
      }

      return finalResult;
  }

  parseInstalmentData(){
    let tempArray = [];
    for(let i=0; i < this.data.length ; i++){
      let tempObj = {};
      tempObj.totalLevyAmt = this.data[i].totalLevyAmt;
      tempObj.totalCost = this.data[i].totalCost;
      tempObj.startDate = this.data[i].startDate;
      tempObj.showDel = this.data[i].showDel;
      tempObj.payNo = this.data[i].stage;
      tempObj.levyAmt = this.data[i].levyAmt;
      tempObj.estimatedCost = this.data[i].estimatedCost;
      tempArray.push(tempObj);
    }
    return JSON.stringify(tempArray);
  }

  updateCaseRecord(){
    console.log('In update case record');
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;
    fields[INSTALMNT_FIELD.fieldApiName] = this.parseInstalmentData();
    const recordInput = { fields };
    console.log('jst before update case record');
    updateRecord(recordInput)
      .then(() => {
        console.log('In update case record response');
        this.saveButtnDisabled = true;
        this.cancelButtnDisabled = true;
          this.dispatchEvent(
              new ShowToastEvent({
                  title: 'Success',
                  message: 'Case updated',
                  variant: 'success'
              })
          );
      })
      .catch(error => {
        //getRecordNotifyChange([{recordId: this.recordId}]);
        console.log('In update case record error');
          this.dispatchEvent(
              new ShowToastEvent({
                  title: 'Error updating record',
                  message: error.body.message,
                  variant: 'error'
              })
          );
      });
  }

  handleCancel(e){
    this.data = JSON.parse(JSON.stringify(this.existingInstalmentDetails)); 
    this.index = this.existingCurrentIndex;   
    this.template.querySelectorAll('lightning-input').forEach(element => {
        if(!element.checkValidity()){
          setTimeout(() => {
              this.setInputValidity(element, "");
          }, 0); 
      }
    });
    this.error = false;
    this.cancelButtnDisabled = true;    
    this.saveButtnDisabled = true;
  }

  checkInputValidty(){
    let result = [...this.template.querySelectorAll('lightning-input')]
    .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
    }, true);
    return result;
}  

  handlePropsedDate(event){
    this.saveButtnDisabled = false; 
    this.cancelButtnDisabled = false;
    let input = event.target;
    let currentIndex = event.currentTarget.dataset.index;
    if(input.value && !(moment(input.value).isSameOrAfter(moment(this.startDate)) && 
            moment(input.value).isSameOrBefore(moment(this.endDate)))){
              this.setInputValidity(input, "Date must be between Estimated Start Date and Estimated End Date");
              console.log('corect validation');
            } 
            else{
              this.setInputValidity(input, "");
            }
    let tempArray = JSON.parse(JSON.stringify(this.data));
    tempArray[parseInt(currentIndex)].startDate = input.value;
    this.data = [...tempArray];
  }

  setInputValidity(input, message){
    input.setCustomValidity(message);
    input.reportValidity();       
  }

}