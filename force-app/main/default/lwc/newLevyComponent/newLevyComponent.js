import { LightningElement, api, wire } from 'lwc';
import getUserAccountInfo from '@salesforce/apex/LSC_LevyPaymentUtility.getUserAccountInfo';
import createLevyAndRelatedRecs from '@salesforce/apex/LSC_LevyPaymentUtility.createLevyPayment';
import getEFT from '@salesforce/apex/LSC_LevyRecordController.getEFT';
import { loadStyle, loadScript} from 'lightning/platformResourceLoader';
import momentJs from '@salesforce/resourceUrl/momentjs_2_29_1';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin} from 'lightning/navigation';
import { handleError } from 'c/utils';

export default class NewLevyComponent extends NavigationMixin(LightningElement) {
    @api levyParameters ='{}';
    @api cost;
    error = "";
    updateRecordIds = false;
    levyId="";
    caseId="";
    transactionId="";
    transactionFlag = false;
    caseFlag = false;
    caseNo ="";

    journey = ['developmentDetails', 'developmentCosts', 'instalments', 'developmentApproval', 'AuthorisedRep', 'Confirmation', 'thankYouPage'];    
    journeyPageDetails = ['c-development-details', 'c-levy-payment-development-cost', 'c-instalments-component', 'c-development-approval', 'c-authorized-rep-component','c-levy-confirmation', 'c-new-levy-thank-you'];

    currentStep = 0;
    error;
    isLoading = false;
    userJourney = "";
    bsb = '';
    accNo = '';
    isEFTModal = false;
    eftAllowed = false;
    submitDisabled = false;
    isLoading = false;

    connectedCallback(){
        console.log('In Parent connected callback');
        this.onload();
    }

    renderedCallback(){
        console.log('Parent rend call back ');
        console.log(this.currentStep);
        Promise.all([loadScript(this,momentJs)]).then(() =>{
        }).catch(error => {
            this.error = error;
        });
    }

    @wire(getEFT, {label : 'BCI'})
    eftDetails({ error, data }) {
        if (data) {
            this.bsb = data.bsb;
            this.accNo = data.accountNumber;
            this.eftAllowed = data.eftAllowed;
        } else if (error) {
            this.error = error;
        }
    }  

    onload(){
        getUserAccountInfo().then(result => {
            console.log('on load result...'+result);
            if(result){
                console.log('In result..'+this.cost);
                this.userJourney = result; 
                let urlParam = 'cost';
                this.cost = this.getUrlParamValue(window.location.href, urlParam);
                this.handleUpdateLevyParameters("update user journey");
            }
        });
    }

    getUrlParamValue(url, key){
        return new URL(url).searchParams.get(key);
    }

    get developmentDetailsStep() {
        return this.journey[this.currentStep] === "developmentDetails";
    }  

    get developmentCostsStep() {
        return this.journey[this.currentStep] === "developmentCosts";
    }  

    get instalmentsStep() {
        return this.journey[this.currentStep] === "instalments";
    }  

    get developmentApprovalStep() {
        return this.journey[this.currentStep] === "developmentApproval";
    }  

    get authorizedRepStep() {
        return this.journey[this.currentStep] === "AuthorisedRep";
    }  

    get levyConfirmationStep() {
        return this.journey[this.currentStep] === "Confirmation";
    }    

    get thankYouStep() {
        return this.journey[this.currentStep] === "thankYouPage";
    }  
    
    get isPrev() {
        return this.currentStep > 0 && this.currentStep < this.journey.length - 1;
    }
 
    get isNext() {
        return this.currentStep < this.journey.length - 2;
    }
 
    get isSubmit() {
        return this.currentStep === this.journey.length - 2;
    }      

    hasSkipped = false;
    handleNext(){
        console.log('In handle next');
        //let levyParams = JSON.parse(this.levyParameters);
        //let devCostDetails = levyParams['developmentCostsDetails'];
        //let nolevyExemption = devCostDetails.levyExemptionOption;


        if(this.checkPageErrors()){
            console.log('checkpage rror success');
            if ((this.developmentCostsStep && this.userJourneyOrganisation && this.renderInstalmentsComp) || (this.developmentApprovalStep && this.userJourneyOrganisation)){
                ++this.currentStep;
            }
            else if((this.developmentCostsStep && !this.userJourneyBusiness) || (this.developmentApprovalStep && this.userJourneyOrganisation) || 
            (this.developmentCostsStep && this.userJourneyBusiness && !this.renderInstalmentsComp)){
                console.log('skipping page');
                this.currentStep +=2;
            } 
            else{
                ++this.currentStep;
            }
        }
        else{
            console.log('Has validation errors');
        }
    }      

    handlePrev(){
        if((this.developmentApprovalStep && !this.userJourneyBusiness) || (this.levyConfirmationStep && this.userJourneyOrganisation)|| 
            (this.developmentApprovalStep && this.userJourneyBusiness && !this.renderInstalmentsComp)){
            console.log('registrationTypeIndividual success');
            this.currentStep -=2;}
        else{
            --this.currentStep;
        }
    }   

    handleLevyConfirmationEvent(event){
        console.log('in levy summary event handle click...'+event.detail);
        let navigatePageTo = event.detail;
        console.log('outside...'+navigatePageTo);
        this.currentStep = this.journey.findIndex(element => element === navigatePageTo);
    }

    handlePayment(event){
        if(this.checkPageErrors()){
            console.log('checkpage success');
            this.isLoading = true;
            this.createLevyPayment();
        } 
    }

    get userJourneyBusiness(){
        return this.userJourney === 'Business';
    }

    get userJourneyOrganisation(){
        return this.userJourney === 'Organisation';
    }

    get userJourneyIndividual(){
        return this.userJourney === 'Individual';
    }

    get renderInstalmentsComp(){
        let levyParams = JSON.parse(this.levyParameters);
        let devCostDetails = levyParams['developmentCostsDetails'];
        let devDetails = levyParams['developmentDetails'];
        let stDate = moment(devDetails.startDate);
        let edDate = moment(devDetails.endDate);
        if(devDetails && devCostDetails){
            if ((devCostDetails.levyExemptionOption == 'no' && this.userJourney === 'Organisation') || (this.userJourney === 'Individual' || this.userJourney === 'Business')){
                let result = (parseFloat(devCostDetails.totalBuildConstCost) >= 10000000) && (stDate > moment().toDate()) && (parseInt(edDate.diff(stDate,'months')) >= 12);
                if(!result){
                    this.clearInstalmentLevyParameters();
                    this.hasSkipped = false;
                } 
                return result;
            }
            /*
            else {
                let result = (parseFloat(devCostDetails.totalBuildConstCost) >= 10000000) && (stDate > moment().toDate()) && (parseInt(edDate.diff(stDate,'months')) >= 12);
                if(!result){
                    this.clearInstalmentLevyParameters();
                    this.hasSkipped = false;
                } 
                return result;
            }*/
        }
        return false;
    }

    handleInstallments (event){
        if(event.detail && event.detail.instalments =='yes'){
            this.hasSkipped = true;  
        } else {
            this.hasSkipped = false;
        }
    }
    get renderThankYouPage(){
        return this.caseFlag === true;
    }

    async createLevyPayment(){
        try {
            let levyResult = await createLevyAndRelatedRecs({requestDetails : this.levyParameters});
            console.log('In backend result...'+levyResult);
            if(levyResult.result === 'success'){
                this.isLoading = true;
                this.submitDisabled = true;
                this.updateRecordIds = true;
                this.levyId = levyResult.levyId;
                this.caseFlag = levyResult.caseFlag;
                this.transactionFlag = levyResult.transactionFlag;
                if(levyResult.caseId) this.caseId = levyResult.caseId;
                if(levyResult.caseNo) this.caseNo = levyResult.caseNo;
                if(levyResult.transRecId) this.transactionId = levyResult.transRecId;
                this.showSuccessToast();
                this.handleUpdateLevyParameters("update record ids");
                if(this.renderThankYouPage){
                    ++this.currentStep;
                }
                else{
                    if(!this.eftAllowed) {
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                            pageName: 'payment'
                            },
                            state: {
                                transactionId: this.transactionId
                            }
                        });
                    }
                    else {
                        this.isEFTModal = true;
                    }
                }
            }
        } catch (error) {
            this.submitDisabled = false;
            this.isLoading = false;
            this.updateRecordIds = false;
            this.error = error;
            const errorMessage = handleError(error);
            this.showToast(errorMessage);
        } finally {
            this.submitDisabled = false;
            this.isLoading = false;
        }
    }

    showToast(message){
        const evt = new ShowToastEvent({
            title: 'Application Error',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    
    checkPageErrors(){
        console.log('inside checkpage rror');
        let currentPage = this.template.querySelector(this.journeyPageDetails[this.currentStep]);
        console.log('inside checkpage rror...'+ currentPage)
        return currentPage.validateAllFields();
    }    

    @api
    handleUpdateLevyParameters(event){
        console.log('update Levy params');
        console.log('Levy params...'+this.levyParameters);
        let tempParams = JSON.parse(this.levyParameters);
        if(typeof event === "string" && this.userJourney && !this.updateRecordIds){
            tempParams['userJourney'] = this.userJourney;
            if(this.cost) tempParams['cost'] = this.cost;
        } else if(typeof event === "string" && this.updateRecordIds){
            if(this.levyId) tempParams['levyId'] = this.levyId;
            if(this.caseId) tempParams['caseId'] = this.caseId;
            if(this.transactionId) tempParams['transactionId'] = this.transactionId;
            if(this.caseNo) tempParams['caseNo'] = this.caseNo;
        }
        else{
            for(let key in event.detail){
                if(key === 'clearParams'){
                    console.log('key------'+key);
                    if(tempParams[event.detail[key]]) delete tempParams[event.detail[key]];
                }else{
                    console.log('key------'+key);
                    console.log(event.detail[key]);
                    tempParams[key] = event.detail[key];
                }
            }
        }
        console.log(tempParams);
        this.levyParameters = JSON.stringify(tempParams);
        console.log('updateRegistrationParameters...'+this.levyParameters);
    }    
    clearInstalmentLevyParameters(){
        let instalParams = ['instalmentCmpDetails', 'variableInstalments', 'presetInstalments', 'uploadedFiles'];
        let tempParams = JSON.parse(this.levyParameters);
        //clear Instalment Cmp Params - instalmentCmpDetails, variableInstalments, presetInstalments
        instalParams.forEach(element => {
            if(tempParams[element]) delete tempParams[element];
        })
        this.levyParameters = JSON.stringify(tempParams);
        console.log('clearInstalmentLevyParameters...'+this.levyParameters);
    }
    get canPayCPP() {
        console.log('levy payable:::'+JSON.parse(this.levyParameters).developmentCostsDetails.levyPayable);
        if(JSON.parse(this.levyParameters).developmentCostsDetails.levyPayable > 1000000) return false;
        return true;
    }
    payCPP() {
        this.isLoading = true;
        this.submitDisabled = true;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'payment'
            },
            state: {
                transactionId: this.transactionId
            }
        });        
    }
    // Note: Handle Click for Close Button
     handleClickClose(){
        this.isEFTModal= false;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'levies'
            }
        });
    }

    closeModal() {
        this.isEFTModal = false;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'levies'
            }
        });
    }

    showSuccessToast(){
        const evt = new ShowToastEvent({
            title: 'Pay New Levy',
            message: 'Levy Created Successfully',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
}