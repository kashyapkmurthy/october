import { LightningElement, api, track } from 'lwc';

export default class addBusinessContactFields extends LightningElement {
    @api pageTitle;
    @api isDisabled;
    @api recContact;
    @track contactData = {};
    buttonLabel;
    pageHeading;
    firstName="";
    lastName="";
    phone="";
    email="";
    readOnly = false;
    selectedRoles = [];
    showRoles = false;

    get roles() {
        return [
            { label: 'Director', value: 'Director' },
            { label: 'Admin', value: 'Admin' },
        ];
    }

    get selectedRoles() {
        return this.selectedRoles.join(',');
    }

    handleRolesChange(event) {
        this.selectedRoles = event.detail.value;
    }

    handleChange(event){
        console.log('insideHandleChange');
        this.contactData[event.target.name]=event.target.value;
    }

    handleEmailChange(event){
        const typedValue = event.target.value;
        const trimmedValue = typedValue.trim(); 
        if (typedValue !== trimmedValue) {
            event.target.value = trimmedValue;
        }
        this.contactData[event.target.name] = trimmedValue;
    }

    connectedCallback(){
        console.log('In contact details connected callback');
        this.pageHeading = this.pageTitle + ' Details';
        this.showRoles = this.pageTitle === 'User' ? true : false;
        this.buttonLabel='Submit';
        this.contactData=JSON.parse(JSON.stringify(this.recContact));
        console.log('In contact details connected callback'+JSON.stringify(this.recContact));
    }

    get disableEmail(){
        return typeof this.recContact.email !== 'undefined' ? true : false;
    }

    @api
    validateAllFields(){
        console.log('contact details validateAll fields...');
         //Validate Contact Details page inputs
        let i=0;
        let contactDetail={};
        this.template.querySelectorAll('lightning-input').forEach(element => {
            console.log('contact details validateAll fields...'+element.value + i++);
            if(element.checkValidity() && element.value){
                contactDetail[element.name] = element.value.trim();
                this.setInputValidity(element, "");
            }
        });

        //Check for valid inputs in all the components
        let finalResult = this.checkInputValidty();
        console.log('checkinptuvaldity....'+this.checkInputValidty());
        console.log('finalResult...'+finalResult);

        if(finalResult){
            contactDetail.roles=['Director'];
            contactDetail.activateUser = false;
            contactDetail.isNewUser = false;
            if(this.pageTitle === 'User'){
                contactDetail.firstName=this.contactData.firstName;
                contactDetail.lastName=this.contactData.lastName;
                contactDetail.phone=this.contactData.phone;
                contactDetail.email=this.contactData.email;
                contactDetail.contactId=this.contactData.contactId;
                contactDetail.roles=this.selectedRoles;
                contactDetail.isNewUser = this.contactData.isUserExist ? false : true; // isUser will determine whether to Create User Record in the Backend or not
                contactDetail.activateUser = this.contactData.activateUser != null ? this.contactData.activateUser : false;
                contactDetail.acrUserId = this.contactData.userId;
                contactDetail.inviteUser = this.contactData.isSendInvite != null ? this.contactData.isSendInvite : false;
            }
            console.log('finalResult...'+finalResult);
            console.log('contactDetail...'+contactDetail);
            const contactDetailsEvent = new CustomEvent('updatecontactdetails', {  detail : contactDetail });
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
    
    get showExistingUserInfo(){
        return (this.contactData.isUserPartOfSameOtherABN   || this.contactData.activateUser  ) ? true: false;
    }
}