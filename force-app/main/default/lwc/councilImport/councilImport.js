import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createRecords from '@salesforce/apex/LSC_CouncilImportController.createRecords';
import getLevyRecords from '@salesforce/apex/LSC_CouncilImportController.getLevyRecords';
import LEVY_OBJECT from "@salesforce/schema/LSC_Levy__c";
import { getObjectInfo }from 'lightning/uiObjectInfoApi';
import { getRecord, createRecord } from 'lightning/uiRecordApi';
import { loadScript } from 'lightning/platformResourceLoader';
import momentJs from '@salesforce/resourceUrl/momentjs_2_29_1';
import momentTmzone from "@salesforce/resourceUrl/moment_timezone";
import PARSER from '@salesforce/resourceUrl/csvparser';
import { newSuccessToast, handleError, newErrorToast } from 'c/utils';
import { refreshApex } from '@salesforce/apex';

const fields = [
    'Account.LSC_EntityTypeName__c'
];

export default class CouncilImport extends LightningElement {
    @api recordId;
    @track records = [];
    toggleSaveLabel = 'Save';
    parserInitialized = false;
    levyRecs = [];
    type;
    year;
    month;
    showError = false;
    error;
    errorMessage = 'There are records already uploaded for the selected month';
    @track chkBoxValue = [];
    disableChkbox = false;
    chkboxOptions =[{label : '', value : 'nil'}];
    confirmModal = false;
    scriptLoaded = false;
    displayDate;

    renderedCallback() {
        if(!this.parserInitialized){
            loadScript(this, PARSER)
            .then(() => {
                this.parserInitialized = true;
            })
            .catch(error => {
                this.error = error
            });
        }
    }

    handleChange(event){
        this[event.target.name] = event.target.value;
        //Reset error message on input change
        this.showError = false;
        //Reset Disable chkbox flag on input change
        this.disableChkbox = false;
        this.chkBoxValue = [];
        if(event.target.name === 'month')
            this.month = event.target.value;
        else if(event.target.name === 'year')
            this.year = event.target.value;
        //Check if there are levy records uploaded for the User selected month and year
        let result = this.levyRecs.some((val) => ((1 + moment(val.LSC_CouncilImportDate__c).month()) == this.month && 
        moment(val.LSC_CouncilImportDate__c, 'YYYY-MM-DD').format('YYYY') == this.year));
        if(result){
            //Show error 
            this.showError = true;
            //Disable the Nil return checkbox to avoid User creating Levy record with $0
            this.disableChkbox = true;
        } 
        //Tick the Nil return checkbox if a Levy record with $0 already exists for the selected period
        let selPeriodLevyRecs = this.levyRecs.filter((val) => ((1 + moment(val.LSC_CouncilImportDate__c).month()) == this.month && 
        moment(val.LSC_CouncilImportDate__c, 'YYYY-MM-DD').format('YYYY') == this.year));
        let nilLevyExist = selPeriodLevyRecs.some((val) => val.LSC_Nil_Return__c);
        if(nilLevyExist){
            //Disable the Nil return checkbox if a $0 levy record already exists for the selected month
            this.chkBoxValue = ['nil'];
            this.disableChkbox = true;
        }
    } 

    connectedCallback(){
        Promise.all([loadScript(this, momentJs), loadScript(this, momentTmzone)]).then(() =>{
            this.scriptLoaded = true;
            this.parseLevyRecords();
        }).catch(error => {
            this.error = error;
        });
        this.tempRecords();
    }

    @wire(getRecord, { recordId: '$recordId', fields: fields })
    wireAccount({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.type = data.fields.LSC_EntityTypeName__c.value;
        }
    }

    @wire(getLevyRecords, { recordId: '$recordId'})
    wireAccountLevyRecords(result) {
        this.result = result;
        if (result.error) {
            this.error = error;
        } else if (result.data) {
            this.levyRecs = result.data;
            this.parseLevyRecords();
        }
    }

    @wire(getObjectInfo, { objectApiName: LEVY_OBJECT })
    levyMetadataHandler({data,error}) {
        if(data) {
            const rtis = data.recordTypeInfos;
            this.defaultRecordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'BCI')
        }
        if(error) {
            this.error = error;
        }
    }
    defaultRecordTypeId;

    get disableCheckbox(){
        return (this.month === undefined || this.year === undefined) ? true : this.disableChkbox;
    }

    parseLevyRecords(){
        //Parse levy records once the records are successfully retrieved from the Server
        if(this.scriptLoaded === true && this.levyRecs.length > 0){
            let latestLevyRecord = this.levyRecs.reduce(function (a, val) {
                return a.LSC_CouncilImportDate__c > val.LSC_CouncilImportDate__c ? a : val;
            });
            let newDate = moment(latestLevyRecord.LSC_CouncilImportDate__c, 'YYYY-MM-DD').add(1, 'M');
            let month = moment(latestLevyRecord.LSC_CouncilImportDate__c, 'YYYY-MM-DD').month();
            let year = moment(newDate, 'YYYY-MM-DD').year();
            this.month = (1 + moment(newDate).month()).toString();
            //If the new Date's year is greater than the current year then update the variable to the current year
            if(year > moment().year()){
                this.year = moment(latestLevyRecord.LSC_CouncilImportDate__c, 'YYYY-MM-DD').format('YYYY');
                //If the new Date's month is Decemeber then update month to December
                //moment's index for the month December is 11
                if(month === 11){
                    this.month = (1 + moment(latestLevyRecord.LSC_CouncilImportDate__c, 'YYYY-MM-DD').month()).toString();
                    //Check for nil return records for december
                    let nilLevyExist = this.levyRecs.some((val) => ((1 + moment(val.LSC_CouncilImportDate__c).month()) == this.month && 
                    moment(val.LSC_CouncilImportDate__c, 'YYYY-MM-DD').format('YYYY') == this.year && val.LSC_Nil_Return__c));
                    //If it was Nil record check the checkbox value
                    if(nilLevyExist){
                        this.chkBoxValue = ['nil'];
                    }
                    this.disableChkbox = true;
                    this.showError = true;
                }
            } else{
                //set the month and year to next month/year based on previous latest upload date
                this.year = moment(newDate, 'YYYY-MM-DD').format('YYYY');
                this.disableChkbox = false;
                this.chkBoxValue = [];
            }
        }
    }

    handleInputChange(event){
        this.showError = false;
        if(event.target.files.length > 0){
            const file = event.target.files[0];
            this.loading = true;
            Papa.parse(file, {
                quoteChar: '"',
                header: 'true',
                complete: (results) => {
                    let csvRecords = [];
                    results.data.forEach(function (arrayItem) {
                        if(Object.values(arrayItem)[0].length > 0) {
                            let record = {Type : Object.values(arrayItem)[0], AppNumber : Object.values(arrayItem)[1], Cost : parseFloat(Object.values(arrayItem)[2].replace(/,/g, '')).toFixed(2), Street : Object.values(arrayItem)[8], City: '', PostCode: '', PaidAmount: parseFloat(Object.values(arrayItem)[3].replace(/,/g, '')), Commission: parseFloat(Object.values(arrayItem)[4].replace(/,/g, '')), GST: (parseFloat(Object.values(arrayItem)[4].replace(/,/g, '')) * 0.1).toFixed(2), Comments: Object.values(arrayItem)[9], key : Math.random().toString(36).substring(2, 15)};
                            csvRecords.push(record);
                        }
                    });
                    this.records = csvRecords;
                    this.loading = false;
                },
                error: (error) => {
                    this.loading = false;
                }
            })
        }
    }

    get isRendered() {
        if(this.type === 'Council') return true;
        return false;
    }
    
    get options() {
        return [
            { label: 'BA', value: 'BA' },
            { label: 'BC', value: 'BC' },
            { label: 'CCB', value: 'CCB' },
            { label: 'CCE', value: 'CCE' },
            { label: 'SWC', value: 'SWC' },
            { label: 'SCC', value: 'SCC' },
            { label: 'LD', value: 'LD' },
            { label: 'CW', value: 'CW' },
            { label: 'PCDC', value: 'PCDC' },
            { label: 'PWC', value: 'PWC' },
            { label: 'SDCC', value: 'SDCC' },
            { label: 'DA/CC', value: 'DA/CC' },
            { label: 'S68', value: 'S68' },
            { label: 'DA', value: 'DA' },
            { label: 'CC', value: 'CC' },
            { label: 'CDC', value: 'CDC' },
            { label: 'CONTRACT', value: 'CONTRACT' },
            { label: 'GC', value: 'GC' },
            { label: 'GDA', value: 'GDA' }            
        ];
    } 

    get monthOptions() {
        return [
            { label: 'January', value: '1' },
            { label: 'February', value: '2' },
            { label: 'March', value: '3' },
            { label: 'April', value: '4' },
            { label: 'May', value: '5' },
            { label: 'June', value: '6' },
            { label: 'July', value: '7' },
            { label: 'August', value: '8' },
            { label: 'September', value: '9' },
            { label: 'October', value: '10' },
            { label: 'November', value: '11' },
            { label: 'December', value: '12' },                  
        ]
    }

    get yearOptions() {
        let curYear = new Date().getFullYear();
        return [
            { label: (curYear-4).toString(), value: (curYear-4).toString() },             
            { label: (curYear-3).toString(), value: (curYear-3).toString() }, 
            { label: (curYear-2).toString(), value: (curYear-2).toString() }, 
            { label: (curYear-1).toString(), value: (curYear-1).toString() },            
            { label: curYear.toString(), value: curYear.toString() }                            
        ]
    }    

    get showAdd() {
        if(this.records.length > 19) return false;
        return true;
    }

    tempRecords(){
        this.records = [];
        for(var i=0; i < 1 ; i++){
            this.records.push({Type : '', AppNumber : '', Cost : 0, Street : '', City: '', PostCode: '', PaidAmount: 0, Commission: 0, GST: 0, Comments: '', key : Math.random().toString(36).substring(2, 15)});
        }
    }

    addRow(){
        const len = this.records.length;
        this.records.unshift({Type : '', AppNumber : '', Cost : 0, Street : '', City: '', PostCode: '', PaidAmount: 0, Commission: 0, GST: 0, Comments: '', key : Math.random().toString(36).substring(2, 15)});
    }

    removeRow(event){
        const indexPos = event.currentTarget.name;
        let remList = [];
        remList = this.records;
        remList.splice(indexPos,1);
        this.records = remList;
    }

    handleCheckboxChange(event){
        let month = (Number(this.month) - 1).toString();
        this.displayDate = moment().year(this.year).month(month).date(1).format('DD/MM/YYYY');
        this.confirmModal = true;
    }

    handleConfirm(event){
        switch(event.target.name){
            case 'confirmYes':
                let month = (Number(this.month) - 1).toString();
                // Creating mapping of fields of Levy with values
                const fields = {'LSC_LevySource__c' : 'Council',  'LSC_AccountId__c' : this.recordId, 'LSC_Comments__c' : 'Nil Return', 'LSC_ApplicationStatus__c' : 'Paid',
                                'LSC_Nil_Return__c' : true, 'RecordTypeId': this.defaultRecordTypeId, 'LSC_CouncilImportDate__c' :  moment().year(this.year).month(month).date(1).format('YYYY-MM-DD HH:mm:ss')};
                // Record details to pass to create method with api name of Object.
                const levyObjectRecord = {'apiName' : LEVY_OBJECT.objectApiName, fields};
                this.confirmModal = false;
                createRecord(levyObjectRecord).then(response => {
                    let successMessage = 'Levy created with Id: ' +response.fields.Name.value+' for the date '+ this.displayDate;
                    this.dispatchEvent(newSuccessToast({ message: successMessage }));
                    refreshApex(this.result);
                }).catch(error => {
                    const errorMessage = handleError(error);
                    this.dispatchEvent(newErrorToast({ message: errorMessage }));
                });
                break;
            case 'confirmNo':
                this.chkBoxValue = [''];
                this.confirmModal = false;
                break;
        }
    }

    closeModal(){
        this.chkBoxValue = [''];
        this.confirmModal = false;
    }

    handleTypeChange(event){
        let foundelement = this.records.find(ele => ele.key == event.target.dataset.id);
        foundelement.Type = event.target.value;
        this.records = [...this.records];
    }

    handleNumberChange(event){
        let foundelement = this.records.find(ele => ele.key == event.target.dataset.id);
        foundelement.AppNumber = event.target.value;
        this.records = [...this.records];
    }
    
    handleStreetChange(event){
        let foundelement = this.records.find(ele => ele.key == event.target.dataset.id);
        foundelement.Street = event.target.value;
        this.records = [...this.records];
    }
    
    handleCityChange(event){
        let foundelement = this.records.find(ele => ele.key == event.target.dataset.id);
        foundelement.City = event.target.value;
        this.records = [...this.records];
    }
    
    handlePostcodeChange(event){
        let foundelement = this.records.find(ele => ele.key == event.target.dataset.id);
        foundelement.PostCode = event.target.value;
        this.records = [...this.records];
    }
    
    handleCostChange(event){
        let foundelement = this.records.find(ele => ele.key == event.target.dataset.id);
        foundelement.Cost = event.target.value;
        this.records = [...this.records];
    }
    
    handlePaidChange(event){
        let foundelement = this.records.find(ele => ele.key == event.target.dataset.id);
        foundelement.PaidAmount = event.target.value;
        this.records = [...this.records];
    }
    
    handleCommissionChange(event){
        let foundelement = this.records.find(ele => ele.key == event.target.dataset.id);
        foundelement.Commission = event.target.value;
        foundelement.GST = (event.target.value * 0.1).toFixed(2);
        this.records = [...this.records];
    }
    
    handleCommentsChange(event){
        let foundelement = this.records.find(ele => ele.key == event.target.dataset.id);
        foundelement.Comments = event.target.value;
        this.records = [...this.records];
    }    

    handleSave(){
        const allValid = [...this.template.querySelectorAll('lightning-combobox, lightning-input, lightning-textarea')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {
            this.toggleSaveLabel = 'Saving...'
            let toSaveList = this.records.slice(0);;
            toSaveList.forEach((element, index) => {
                let eleType = typeof element.Name;
                if(element.Name === '' || eleType=='object'){
                    toSaveList.splice(index);
                }
            });  
            createRecords({records : toSaveList, recordId : this.recordId, year : this.year, month: this.month})
            .then(result => {
                this.toggleSaveLabel = 'Save';
                if(result.isSuccess) {
                    this.tempRecords();
                    this.error = undefined;
                    if(result.errorRecords) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title : 'Some records has failed',
                                message : 'There was an error saving records with Application Number: ' + result.errorRecords + '. Looks like these records already exist in the system and need to be manually updated',
                                variant : 'warning',
                                mode: 'sticky',
                            })
                        )
                    }
                    else {
                        refreshApex(this.result);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title : 'Success',
                                message : 'Records saved succesfully!',
                                variant : 'success',
                            })
                        )
                    }
                }
                else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title : 'Error',
                            message : result.error,
                            variant : 'error',
                        })
                    )                    
                }
            })
            .catch(error => {
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title : 'Error',
                        message : error,
                        variant : 'error',
                    })
                )
            })
            .finally(() => {
                setTimeout(() => {
                    this.toggleSaveLabel = 'Save';
                }, 3000);
            });
        }
    }
}