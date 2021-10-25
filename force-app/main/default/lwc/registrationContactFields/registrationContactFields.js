import { LightningElement, api } from 'lwc';
import validateUsername from '@salesforce/apex/LSC_RegistrationUtility.validateUsername';
import getContactDetails from '@salesforce/apex/LSC_RegistrationUtility.getContactDetails';
import { NavigationMixin} from 'lightning/navigation';
import communityBasePath from '@salesforce/community/basePath';

export default class RegistrationContactFields extends NavigationMixin(LightningElement) {
    @api registrationParameters;   
    @api contdetails_addresspostalparameters; 
    @api isExistingUser = false;
    regTypeIndividual = false;
    pageTitle;
    postalAddressDetails = {}; 
    contactDetailsPage = {};
    givenName="";
    surName="";
    phone="";
    email="";
    usernameValidated = false;
    userValidationError_1="The email provided is already registered with us. Please select Forgot password, enter your email address and select submit to reset your password. Need assistance? Please complete an ";
    userValidationError_2=" or call us on 13 14 41 Monday to Friday, from 8:30am to 5:00pm";
    showError = false;

    connectedCallback(){
        console.log('In contact details connected callback');
        let regParams = JSON.parse(this.registrationParameters);
        if(regParams){
            let regTypeValue = regParams['registrationType'];
            (regTypeValue && regTypeValue === "Individual") ? (this.pageTitle = "Your details", this.regTypeIndividual = true)  : this.pageTitle = "Contact details";

            this.contdetails_addresspostalparameters = regParams['postalAddress'];
            this.postalAddressDetails = this.contdetails_addresspostalparameters ? this.contdetails_addresspostalparameters : {};

            let pageDetails = regParams['contactPageDetails'];
            if(pageDetails){
                this.givenName = pageDetails.givenName;
                this.surName = pageDetails.surName;
                this.phone = pageDetails.phone;
                this.email = pageDetails.email;
            }
            else if(this.isExistingUser){
                this.onLoad();
            }
            this.usernameValidated = regParams['emailValidated']? regParams['emailValidated'] : false;
        }
    }

    onLoad(){
        console.log('In onload');
        getContactDetails().then((response) => {
            if(response.result === 'success'){
                this.email = response.email;
            }
        });
    }

    handleAddressDetails(event){
        console.log('In contact details  event...'+event.detail);
        console.log(event.target.id);
        const id = this.getId(event.target.id);
        this.postalAddressDetails = event.detail;
    } 

    handleBlur(event){
        let input = event.target;
        if(input && input.checkValidity() && !this.isExistingUser){
            let email = input.value;
            validateUsername({username: email.trim()}).then(result => {
                this.usernameValidated = true;
                console.log('email validate username result....'+result+'......'+this.usernameValidated);
                this.setInputValidity(input, "");
                if(result){
                    this.showError = true;
                }
            });
        }
    }

    handleClick(){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: communityBasePath+'/contactsupport'
            },
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    handleChange(event){
        const typedValue = event.target.value;
        const trimmedValue = typedValue.trim(); // trims the value entered by the user
        if (typedValue !== trimmedValue) {
            event.target.value = trimmedValue;
        }
        this.email = trimmedValue; // updates the internal state
        this.showError = false;
        this.usernameValidated = false;
    }

    getId(id){
        const finalId = (id || "").split("-");
        finalId.pop();
        return finalId.join("-");
    }     

    @api
    validateAllFields(){
        console.log('contact details validateAll fields...');
        let customEventDetailMap ={};
        let message="";
        //Validate Contact Details page inputs
        this.template.querySelectorAll('lightning-input').forEach(element => {
            console.log('contact details validateAll fields...'+element.value);
            if(element.checkValidity() && element.value){
                this.contactDetailsPage[element.name] = element.value.trim();
                this.setInputValidity(element, "");
                if(element.name === "email"){
                    if(!this.usernameValidated){
                        this.setInputValidity(element, "Your email is being verified. Please click next again in few seconds");
                    }
                }
            }
        });

        customEventDetailMap['contactPageDetails'] =  this.contactDetailsPage;

        //validate Address Search Input
        let addressSearchValid = true;
        let addrSearchCmp = this.template.querySelector('c-new-address-search');
        if(addrSearchCmp){
            addressSearchValid &= addrSearchCmp.validateAllFields();
            customEventDetailMap['postalAddress'] = this.postalAddressDetails;
        }
        customEventDetailMap['emailValidated'] = this.usernameValidated;
        console.log('event map...'+customEventDetailMap);

        //Check for valid inputs in all the components
        let finalResult = !this.showError && this.checkInputValidty() & addressSearchValid;
        console.log('checkinptuvaldity....'+this.checkInputValidty());
        console.log('finalResult...'+finalResult);
        //Trigger a custom event if all inputs are valid
        if(finalResult){
            const contactDetailsEvent = new CustomEvent('updatecontactdetailsparameters', {  detail : customEventDetailMap});
            // Dispatches the event.
            this.dispatchEvent(contactDetailsEvent); 
        }

        return finalResult;
    }

    setInputValidity(input, message){
        console.log('setInputValidity...'+input.value);
        console.log('setInputValidity...'+input.name);
        console.log('setInputValidity...'+message);
        input.setCustomValidity(message);
        input.reportValidity();       
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