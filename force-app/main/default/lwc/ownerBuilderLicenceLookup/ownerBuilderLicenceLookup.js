import { LightningElement, api } from 'lwc';
import startOwnerBuilderContinuation from '@salesforce/apexContinuation/LSC_FetchOwnerBuilderLicenceDetail.startOwnerBuilderContinuation';
const OWNER_BUILDER_MIN_LNGTH = 6;
export default class OwnerBuilderLicenceLookup extends LightningElement {
    
    @api ownerBuilderParameters;
    @api ownerBuilderValue = "";
    ownerBuilderDetails = {};
    isLoading = false;
    clearAdditionalInputs = false;
    @api emptyOwnerAPITextBox = false;
    @api showInputs = false;
    @api hasValidLicenceNumber = false;
    @api largeDeviceSize = 6;
    showIcon = false;

    connectedCallback(){
        this.ownerBuilderValue = this.ownerBuilderParameters ? this.ownerBuilderParameters.licenceNumber : "";
    }

    handleChange(event){
        this.clearInputValidity();
        let licenceNumber = event.target.value;
        if(event.target.value.length > OWNER_BUILDER_MIN_LNGTH && this.checkInputValidty()){
            this.clearAdditionalInputs = false;
            this.isLoading = true;
            this.getLicenceDetails(licenceNumber);
        }
        else if((event.target.value.length <= OWNER_BUILDER_MIN_LNGTH) || (event.target.value.length == 0)) {
            this.emptyOwnerAPITextBox = true;
            //this.emptyOwnerAPITextBox(true);
            this.clearAdditionalInputs = true;
            this.isLoading = false;
            const emptyEvent = new CustomEvent('emptyownerbox', { detail: this.emptyOwnerAPITextBox });
            this.dispatchEvent(emptyEvent);
        }
    }


    emptyOwnerAPITextBox() {
        const selectedEvent = new CustomEvent('emptyownerbox', { detail: this.emptyOwnerAPITextBox });
        this.dispatchEvent(selectedEvent);
    }

    getLicenceDetails(licenceNumber){     
        this.clearAdditionalInputs = false;
        this.setInputValidity('');
        startOwnerBuilderContinuation({licenceNumber: licenceNumber.trim().toUpperCase()}).then(result => {
            let response = JSON.parse(JSON.stringify(result.licenceDetails));
            this.isLoading = false; //moment(this.devDetails.startDate).format("DD-MM-YYYY");
            response.startDate = response.startDate ? moment(response.startDate).format("YYYY-MM-DD") : "";
            response.expiryDate = response.expiryDate ? moment(response.expiryDate).format("YYYY-MM-DD") : null;
            this.ownerBuilderDetails = response;
            if(this.ownerBuilderDetails.status && this.ownerBuilderDetails.status == 'Current'){
                this.ownerBuilderValue = this.formatValue(this.ownerBuilderDetails.licenceNumber);
                this.hasValidLicenceNumber = true;
                this.showIcon = true;
                //this.setInputValidity('Provided Owner Builder Permit validated successfully');
                this.fireCustomEvent(true);
            }else{
                this.hasValidLicenceNumber = false;
                this.setInputValidity('Provided Owner Builder Permit number is not active');
                this.showIcon = false;
                this.fireCustomEvent(false);
            }
        }).catch(error=>{
            this.setInputValidity('Provided Owner Builder Permit number is not found');
            this.isLoading = false;
            this.showIcon = false;
            this.hasValidLicenceNumber = false;
            this.fireCustomEvent(false);
        });
    }

    formatValue(value){
        return value.trim();
    }

    clearInputValidity(){
        let input = this.template.querySelector('lightning-input');
        let inputValue = input.value.split(/\s/).join('');  
        input.setCustomValidity("");
        input.reportValidity();
        if(inputValue.length <= 6 && !this.clearAdditionalInputs){
            this.clearAdditionalInputs = true;
            this.showIcon = false;
            this.fireCustomEvent(false);        
        }
        else this.clearAdditionalInputs = false;
    }

    setInputValidity(message){
        let input = this.template.querySelector('lightning-input');  
        input.setCustomValidity(message);
        input.reportValidity();       
    }   

    fireCustomEvent(showInputs){
        this.showInputs = showInputs;
        // Custom event
        const ownerBuildDetails = new CustomEvent('ownerbuildevent', {  detail: {ownerBuilderDetails : this.ownerBuilderDetails, showAdditionalInputs : this.showInputs}});
        // Dispatches the event.
        this.dispatchEvent(ownerBuildDetails);      
    }

    onFocus(event){
        this.removeWhiteSpaces(event.target.value);
    }
    
    removeWhiteSpaces(value){
        this.ownerBuilderValue = value.split(/\s/).join('');
    }

    get disabled(){
        return this.isLoading === true;
    }

    get showCorrectIcon(){
        return this.showIcon === true;
    }

    @api
    validateAllFields(){
        let input = this.template.querySelector('lightning-input');  
        if(input && input.value.length <= OWNER_BUILDER_MIN_LNGTH){
            input.setCustomValidity("Please enter valid owner builder permit number");
            input.reportValidity();
        }
        return input.checkValidity();
    }

    checkInputValidty(){
        let input = this.template.querySelector('lightning-input');
        return input.checkValidity();
    }       

}