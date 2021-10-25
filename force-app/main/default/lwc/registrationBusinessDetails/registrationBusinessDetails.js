import { LightningElement, api } from 'lwc';

export default class RegistrationBusinessDetails extends LightningElement {
    @api registrationParameters;  
    @api abnParameters;  
    @api addressStreetParameters;
    @api addressPostalParameters;
    @api abnDetails = {};
    @api phoneLabel;
    @api emailLabel;
    @api streetAddrssLabel;
    @api postalAddrssLabel;

    phoneValue = "";
    emailValue = "";
    streetAddressDetails = {};
    postalAddressDetails = {}; 
    businessDetailsPage = {};   
    showAdditionalInputs = false;
    sameAsBusinessAddr = false;

    connectedCallback(){
        console.log('In business details connected callback');
        if(this.registrationParameters){
            let regParams = JSON.parse(this.registrationParameters);
            if(regParams){
                this.abnParameters = regParams['abnDetails'];
                this.abnDetails = this.abnParameters ? this.abnParameters : {};

                this.addressStreetParameters = regParams['streetAddress'];  
                this.streetAddressDetails = this.addressStreetParameters? this.addressStreetParameters : {};       
                
                this.addressPostalParameters = regParams['postalAddress'];  
                this.postalAddressDetails = this.addressPostalParameters ? this.addressPostalParameters : {};

                let pageDetails = regParams['businessPageDetails'];
                if(pageDetails){
                    this.showAdditionalInputs = true;
                    this.phoneValue = pageDetails.phone;
                    this.emailValue = pageDetails.email;
                    this.sameAsBusinessAddr = pageDetails.sameAsStrtAdr;
                }
            }
        }
    }

    handleABNDetails(event){
        console.log('In handle ABN');
        this.abnDetails = event.detail.abnDetails;
        this.showAdditionalInputs = event.detail.showAdditionalInputs;
        //set focus on Phone input field if additional inputs are shown
        if(this.showAdditionalInputs){
            setTimeout(() => {
                let input = this.template.querySelector(".phoneInput");
            if(input) {
                input.focus();
            }
            }, 0); 
        }
        //ABN Validated succesfully validated event
        const abnVaidationEvent = new CustomEvent('abnvalidation', {  detail : event.detail.showAdditionalInputs});
        // Dispatches the event.
        this.dispatchEvent(abnVaidationEvent); 
    }

    handleAddressDetails(event){
        console.log('In reg business details custom event...'+event.detail);
        console.log(event.target.id);
        const id = this.getId(event.target.id);
        console.log(id);
        (id == "streetAdd")? this.streetAddressDetails = event.detail : this.postalAddressDetails = event.detail;
    }   

    handleChkboxChange(event){
        this.sameAsBusinessAddr = !this.sameAsBusinessAddr;
        console.log('chkbox change...'+this.sameAsBusinessAddr);
        if(!this.sameAsBusinessAddr){
            this.postalAddressDetails = {};
            this.addressPostalParameters = {};
            this.addressPostalParameters.autoAddress = true;
        }
    }

    handleChange(event){
        const typedValue = event.target.value;
        const trimmedValue = typedValue.trim(); // trims the value entered by the user
        if (typedValue !== trimmedValue) {
            event.target.value = trimmedValue;
        }
        this.emailValue = trimmedValue; // updates the internal state
    }
    
    setInputValidity(input, message){
        input.setCustomValidity(message);
        input.reportValidity();       
    }

    get showInputs(){
        return this.showAdditionalInputs === true;
    }

    getId(id){
        const finalId = (id || "").split("-");
        finalId.pop();
        return finalId.join("-");
    }      

    @api
    validateAllFields(){
        console.log('busniness details validateAll fields...');
        // Validate ABN Input 
        let abnCmpValid = this.template.querySelector('c-abn-lookup').validateAllFields();
        // Business Details inputs
        this.template.querySelectorAll('lightning-input').forEach(element => {
            if(element.value && element.checkValidity()){
                this.businessDetailsPage[element.name] = element.value.trim();
            }
            if(element.name === 'sameAsStrtAdr')
                this.businessDetailsPage[element.name] = this.sameAsBusinessAddr;
        });

        //validate Address Search Input
        let addressSearchValid = true;
        let addrSearchCmps = this.template.querySelectorAll('c-new-address-search');
        if(addrSearchCmps){
            addrSearchCmps.forEach(element => {
                addressSearchValid &= element.validateAllFields();
            });
        }
        if(this.sameAsBusinessAddr){
            this.postalAddressDetails = this.streetAddressDetails;
        }

        //Check for valid inputs in all the components
        let finalResult = abnCmpValid && this.checkInputValidty() && addressSearchValid;
        console.log('Business Details Page params...'+ this.businessDetailsPage);
        //Trigger a custom event if all inputs are valid
        if(finalResult){
            const businessDetailsEvent = new CustomEvent('updatebusinessdetailsparameters', {  detail : {abnDetails : this.abnDetails,
                                                                                                    postalAddress : this.postalAddressDetails,
                                                                                                    streetAddress : this.streetAddressDetails,
                                                                                                    businessPageDetails : this.businessDetailsPage}});
            // Dispatches the event.
            this.dispatchEvent(businessDetailsEvent); 
        }
        return finalResult;
    }

    checkInputValidty(){
        let result = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        return result;
    }
}