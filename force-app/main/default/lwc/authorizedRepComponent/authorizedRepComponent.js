import { LightningElement, api } from 'lwc';

export default class AuthorizedRepComponent extends LightningElement {
    @api appldetails_addresspostalparameters;
    @api levyParameters;
    value="";
    givenName="";
    surName="";
    phone="";
    email="";
    applicantDetails={};
    postalAddressDetails;
    radioLabel="";
    options=[];

    connectedCallback(){
        console.log('In auth rep cc');
        let levyParams = JSON.parse(this.levyParameters);
        if(levyParams){
            let userJourney = levyParams['userJourney'];
            if(userJourney && userJourney == "Individual"){
                this.radioLabel = "Are you the applicant, or are you paying on behalf of the applicant?";
                this.options = [
                    { label: 'I am the applicant', value: 'yourRoleApplicant' },
                    { label: 'I am paying on behalf of the applicant', value: 'yourRoleBehalf' },
                ];
            }else if(userJourney && userJourney == "Business"){
                this.radioLabel = "Is your business the applicant, or are you paying on behalf of the applicant?";
                this.options = [
                    { label: 'Our business is the applicant', value: 'yourRoleBusinessApplicant' },
                    { label: 'Our business is paying on behalf of the applicant', value: 'yourRoleBusinessBehalf' },
                ];
            }else if(userJourney && userJourney == "Organisation"){
                this.radioLabel = "Is your Organisation the applicant, or are you paying on behalf of the applicant?";
                this.options = [
                    { label: 'Our organisation is the applicant', value: 'yourRoleOrganisationApplicant' },
                    { label: 'Our organisation is paying on behalf of the applicant', value: 'yourRoleOrganisationBehalf' },
                ];
            }

            let authRepDetails = levyParams['authRepDetails'];
            if(authRepDetails){
                this.value = authRepDetails.yourRole;
                if(this.showAdditionalInputs){
                    this.givenName = authRepDetails.givenName;
                    this.surName = authRepDetails.surName;
                    this.phone = authRepDetails.phone;
                    this.email = authRepDetails.email;
                    this.appldetails_addresspostalparameters = levyParams['postalAddress'];
                    this.postalAddressDetails = this.appldetails_addresspostalparameters ? this.appldetails_addresspostalparameters : {};
                }
            }

        }
    }

    get options() {
        return this.options;
    }

    handleChange(event){
        this.value = event.target.value;
    }

    setInputValidity(input, message){
        input.setCustomValidity(message);
        input.reportValidity();       
    }

    get showAppDetails(){
        return (this.value && (this.value === 'yourRoleBehalf' || this.value === 'yourRoleBusinessBehalf'));
    }

    get showAdditionalInputs(){
        return this.value === 'yourRoleBehalf' || this.value === 'yourRoleBusinessBehalf';
    }

    handleAddressDetails(event){
        this.postalAddressDetails = event.detail;
    }

    handleEmailChange(event){
        const typedValue = event.target.value;
        const trimmedValue = typedValue.trim(); 
        if (typedValue !== trimmedValue) {
            event.target.value = trimmedValue;
        }
        this.email = trimmedValue;
    }

    @api
    validateAllFields(){
        console.log('auth rep validateAll fields...');
        let authRepDetails = {};
        let authRepPageDetails = {};
        let clearParams = [];
        // Auth Rep Details inputs
        let input = this.template.querySelector('lightning-radio-group');
        if(input.reportValidity() && input.value && input.checkValidity()){
            authRepDetails[input.name] = input.value;
        }
        this.template.querySelectorAll('lightning-input').forEach(element => {
            if(element.reportValidity() && element.value && element.checkValidity()){
                authRepDetails[element.name] = element.value.trim();
            } 
        });

        authRepPageDetails['authRepDetails'] = authRepDetails;

        //validate Address Search Input
        let addressSearchValid = true;
        let addrSearchCmp = this.template.querySelector('c-new-address-search');
        if(addrSearchCmp){
            addressSearchValid &= addrSearchCmp.validateAllFields();
            authRepPageDetails['postalAddress'] = this.postalAddressDetails;
        } else{
            clearParams.push('postalAddress');
            authRepPageDetails['clearParams'] = 'postalAddress';
        }

        //Check for valid inputs in all the components
        let finalResult = this.checkInputValidty() && addressSearchValid;
        console.log('auth rep Details Page params...'+ authRepDetails);
        //Trigger a custom event if all inputs are valid
        if(finalResult){
            const authRepDetailsEvent = new CustomEvent('updateauthrepdetailsparameters', {  detail : authRepPageDetails});
            // Dispatches the event.
            this.dispatchEvent(authRepDetailsEvent); 
        }
        return finalResult;
    } 
    
    checkInputValidty(){
        let radioGrpResult = this.template.querySelector('lightning-radio-group').checkValidity();
        let result = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        return (result & radioGrpResult);
    }    
}