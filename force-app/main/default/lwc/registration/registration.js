import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import notifyBanner from '@salesforce/messageChannel/RegMessageChannel__c';
import checkForRegistrationStatus from '@salesforce/apex/LSC_RegistrationUtility.checkForRegistrationStatus';
import isguest from '@salesforce/user/isGuest';
import createAccountContact from '@salesforce/apex/LSC_RegistrationUtility.createAccountContact';
import assignPermissionSet from '@salesforce/apex/LSC_RegistrationUtility.assignPermissionSet';
import updateUsername from '@salesforce/apex/LSC_RegistrationUtility.updateUsername';
import { handleError } from 'c/utils';

export default class Registration extends LightningElement {
    @api registrationParameters ='{}';
    errorMessage;
    hasErrorMessage;
    isLoading = false;
    cost;
    renderRegistrationComponent = false;
    journey = ['registrationLevyChoice', 'registrationBusinessDetails', 'registrationContactFields', 'registrationPassword', 'registrationSummary', 'thankYouPage'];
    journeyPageDetails = ['c-registration-levy-choice', 'c-registration-business-details', 'c-registration-contact-fields', 'c-registration-password', 'c-registration-summary','c-thank-you-page'];
    currentStep = 0;
    existingUser = false;
    isGuestUser = isguest;

    @wire(MessageContext)
    messageContext;
    
    connectedCallback(){
        console.log('in connected callback');
        this.onLoad();
    }

    onLoad(){
        if(this.isGuestUser) this.renderRegistrationComponent = true;
        else{
            checkForRegistrationStatus().then((result) => {
                console.log('before reg. status');
                if(result === true){
                    console.log('in true reg. status');
                    this.renderRegistrationComponent = true;
                }
            })
        }
        console.log('after reg. status');
        let urlParam = 'cost';
        this.cost = this.getUrlParamValue(window.location.href, urlParam);
        this.handleUpdateRegParameters("update cost attribute");
    }

    getUrlParamValue(url, key){
        return new URL(url).searchParams.get(key);
    }
    
    @api
    get registrationLevyChoiceStep() {
        return this.journey[this.currentStep] === "registrationLevyChoice";
    }    

    get registrationContactFieldsStep() {
        return this.journey[this.currentStep] === "registrationContactFields";
    }       

    get registrationPasswordStep() {
        return this.journey[this.currentStep] === "registrationPassword";
    }  

    get registrationSummaryStep() {
        return this.journey[this.currentStep] === "registrationSummary";
    }  

    get registrationBusinessDetailsStep() {
        return this.journey[this.currentStep] === "registrationBusinessDetails";
    }  

    get thankYouStep() {
        return this.journey[this.currentStep] === "thankYouPage";
    }  

    get isPrev() {
        return this.currentStep > 0 && this.currentStep < this.journey.length-1;
    }
 
    get isNext() {
        return this.currentStep < this.journey.length - 2;
    }
 
    get isSubmit() {
        return this.currentStep === this.journey.length - 2;
    }    

    get isExistingUser(){
        return this.isGuestUser === false? true : false;
    }

    handleNext(){
        console.log('In handle next');
        if(this.checkPageErrors()){
            console.log('checkpage rror success');
            //console.log(this.registrationLevyChoiceStep());
            console.log(this.registrationTypeIndividual());
            if((this.registrationLevyChoiceStep && this.registrationTypeIndividual()) || (this.registrationContactFieldsStep && this.isExistingUser)){
                this.currentStep += 2;
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
        if(this.registrationContactFieldsStep && this.registrationTypeIndividual() || (this.registrationSummaryStep && this.isExistingUser))
            this.currentStep -= 2;
        else
            --this.currentStep;
    }    

    handleRegister(){
        if(this.checkPageErrors()){
            console.log('checkpage rror success');
            this.isLoading = true;
            this.registerUser();
        } 
    }

    async registerUser(){
        this.hasErrorMessage = false;
        const message = {
            message : "Close the Banner on successful registration",
        };
        try {
            let accConResult = await createAccountContact({requestDetails : this.registrationParameters});
            console.log('in register user return reslut...'+JSON.stringify(accConResult));
            if(accConResult.result){
                console.log('user id returned....'+accConResult.userId);
                let updateUsernameResult = await updateUsername({userId : accConResult.userId});
                let assignPermSetResult = await assignPermissionSet({userId : accConResult.userId});
                console.log('oerm set result...'+assignPermSetResult);
                if(assignPermSetResult && updateUsernameResult){
                    publish(this.messageContext, notifyBanner, message);
                    ++this.currentStep;
                    console.log('current setp is ...'+this.currentStep);
                } else if (!assignPermSetResult) {
                    throw new Error('Error occurred during assigning permission set to the user.');
                } else if (!updateUsernameResult) {
                    throw new Error('Error occurred during updating the username.');
                }
            } else if (accConResult.errorMess) {
                throw new Error(accConResult.errorMess);
            }
        } catch (error) {
            const errorMessage = handleError(error);
            this.errorMessage = errorMessage;
            this.hasErrorMessage = true;
        } finally {
            this.isLoading = false;
        }
    }

    
    get contactDetails(){
        let tempParams = JSON.parse(this.registrationParameters);
        if(tempParams){
            return tempParams['contactPageDetails'];
        }
    }

    handleSummaryPageEvent(event){
        console.log('in registration summary event handle click...'+event.detail);
        let navigatePageTo = event.detail;
        if(navigatePageTo && navigatePageTo === "yourDetails"){
            this.currentStep = 2;
        } else if(navigatePageTo && navigatePageTo === "businessDetails"){
            this.currentStep = 1;
        }
    }

    checkPageErrors(){
        console.log('inside checkpage rror');
        let currentPage = this.template.querySelector(this.journeyPageDetails[this.currentStep]);
        console.log('inside checkpage rror...'+ currentPage)
        return currentPage.validateAllFields();
    }

    @api
    handleUpdateRegParameters(event){
        console.log('update reg params');
        console.log('reg params...'+this.registrationParameters);
        let tempParams = JSON.parse(this.registrationParameters);
        if(typeof event === "string" && this.cost){
            tempParams['cost'] = this.cost;
        } 
        for(let key in event.detail){
            if(key === 'clearParams'){

                    event.detail[key].forEach(element => {
                        if(tempParams[element]) delete tempParams[element];
                    });

            }else{
                console.log(key);
                console.log(event.detail[key]);
                tempParams[key] = event.detail[key];
            }
        }
        console.log(tempParams);
        this.registrationParameters = JSON.stringify(tempParams);
        console.log('updateRegistrationParameters...'+this.registrationParameters);
    }

    registrationTypeIndividual(){
        console.log('in get regtype');
        let regType = JSON.parse(this.registrationParameters)['registrationType'];
        console.log(regType);
        return (regType && regType == 'Individual') ? true : false;
    }
}