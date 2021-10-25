import { LightningElement, api } from 'lwc';
import startABNContinuation from '@salesforce/apexContinuation/LSC_ABNLookupService.startABNContinuation';
import checkABNonAccounts from '@salesforce/apex/LSC_RegistrationUtility.checkABNonAccounts';
import { NavigationMixin} from 'lightning/navigation';
import communityBasePath from '@salesforce/community/basePath';

const ABN_LNGTH = 11;

export default class AbnLookup extends NavigationMixin(LightningElement) {
    @api abnParameters;
    @api abnValue = "";
    abnDetails = {};
    isLoading = false;
    clearAdditionalInputs = false;
    @api showInputs = false;
    showError = false;
    errorMessage = "";

    connectedCallback(){
        console.log('In ABN lookup connected callback');
        this.abnValue = this.abnParameters ? this.abnParameters.australianBusinessNumber : "";
    }

    handleChange(event){
        let input = event.target;
        this.clearInputValidity(input);
        this.showError = false;
        let abnString = event.target.value;
        if(abnString.length == ABN_LNGTH && this.checkInputValidty(input)){
            //this.abnValue = this.removeWhiteSpaces(abnString);
            this.clearAdditionalInputs = false;
            this.isLoading = true;
            checkABNonAccounts({abn: abnString.trim()}).then(result => {
                console.log('method result-->'+result);
                if(result && result.matched === 'yes'){
                    this.isLoading = false;
                    this.showError = true;
                    this.errorMessage = `The ABN provided already has an account with us. Please email the account administrator at ${result.portalAdminEmailAddress} to request access.`;
                    this.fireCustomEvent(false);
                } else {
                    this.getABNDetails(input, abnString);
                }
            });
        }
    }

    handleLoginClick(event){
        let commURL = communityBasePath;
        let finalURL = commURL.indexOf("login") > -1 ? commURL : commURL+'/login' ;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: finalURL
            },
        }).then(url => {
            console.log('in handle click...'+url);
            window.open(url, "_blank");
        });
    }

    getId(id){
        const finalId = (id || "").split("-");
        finalId.pop();
        return finalId.join("-");
    } 

    getABNDetails(input, abnString){     
        this.clearAdditionalInputs = false;
        startABNContinuation({abn: abnString.trim()}).then(result => {
            this.abnDetails = result.business;
            //console.log(this.abnDetails.EntityName);
            console.log('abnDetails-->' + this.abnDetails);
            this.isLoading = false;
            if(this.abnDetails.australianBusinessNumberStatus && this.abnDetails.australianBusinessNumberStatus == 'Active'){
                this.abnValue = this.formatABN(this.abnDetails.australianBusinessNumber);
                this.fireCustomEvent(true);
            }else{
                this.setInputValidity(input, 'Provided ABN is not active on the Australian Business Register');
                this.fireCustomEvent(false);
            }
        }).catch(error=>{
            console.log('In error'+error.message);
            this.setInputValidity(input, 'Provided ABN is not found');
            this.isLoading = false;
        });
    }

    formatABN(value){
        console.log('I am in format abn');
        return value.replace(/^(.{2})(.{3})(.{3})(.*)$/, "$1 $2 $3 $4").trim();
    }

    clearInputValidity(input){
        let inputValue = input.value.split(/\s/).join('');  
        input.setCustomValidity("");
        input.reportValidity();
        if(inputValue.length < 11 && !this.clearAdditionalInputs){
            this.clearAdditionalInputs = true;
            this.fireCustomEvent(false);        
        }
        else this.clearAdditionalInputs = false;
    }

    setInputValidity(input, message){
        input.setCustomValidity(message);
        input.reportValidity();       
    }

    checkInputValidty(input){
        return input.checkValidity();
    }

    fireCustomEvent(showInputs){
        this.showInputs = showInputs;
        // Custom event
        const abnDetails = new CustomEvent('abnevent', {  detail: {abnDetails : this.abnDetails, showAdditionalInputs : this.showInputs}});
        // Dispatches the event.
        this.dispatchEvent(abnDetails);      
    }

    onFocus(event){
        console.log('In focus');
        console.log('In focus value-->'+event.target.value);
        this.removeWhiteSpaces(event.target.value);
    }
    
    removeWhiteSpaces(value){
        this.abnValue = value.split(/\s/).join('');
    }

    get disabled(){
        return this.isLoading === true;
    }

    @api
    validateAllFields(){
        let input = this.template.querySelector('lightning-input');  
        if(input && input.value.length < ABN_LNGTH){
            input.setCustomValidity("Please enter a valid ABN number");
            input.reportValidity();
        }
        return input.checkValidity() && !this.showError;
    }
}