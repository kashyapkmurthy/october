import { LightningElement, api } from 'lwc';
import verifyUserLinkWithABN from '@salesforce/apex/LSC_BusinessDetailsController.verifyUserLinkWithABN';
import addNewBusinessContact from '@salesforce/apex/LSC_BusinessDetailsController.addNewBusinessContact';
import { newErrorToast, handleError } from 'c/utils';

export default class AddBusinessContactUser extends LightningElement {
    @api accountId;
    @api isModalOpen;
    @api abn;
    pageHeading = 'Add Contact / User';
    value = '';
    buttonLabel = 'Submit';
    isContactOfDirector = false;
    isNewUser = false;
    isOpenModal = false;
    email;
    showUserDetails = false;
    showUserDetailsReadOnly = false;
    contactDetails = {};
    recContact = {};
    userValidationError;
    showError = false;    
    isLoading = false;
    disableSubmit = true;

    connectedCallback() {
        this.isOpenModal = JSON.parse(this.isModalOpen);
    }

    get options() {
        return [
            { label: 'Contact of Director', value: 'Contact' },
            { label: 'New User', value: 'User' },
        ];
    }

    handleUserTypeChange(event) {
        let selectedValue = event.target.value;
        this.disableSubmit = false;
        if (selectedValue === 'Contact') {
            this.isContactOfDirector = true;
            this.isNewUser = false;
            this.buttonLabel = 'Submit';
            this.recContact = {};
        } else if (selectedValue === 'User') {
            this.isNewUser = true;
            this.isContactOfDirector = false;
            this.buttonLabel = 'Next';
        }
    }

    handlePrevious() {
        this.recContact = {};
        this.value = 'User';
        this.showUserDetails = false;
        this.buttonLabel = 'Next';
        this.pageHeading = 'Add Contact / User';
    }

    handleSubmit() {
        if (this.buttonLabel === 'Submit') {
            // Do Validation Checks
            if (this.validateAllFields()) {
                this.isLoading = true;
                this.disableSubmit = true;
                console.log('JSON.stringify(this.contactDetails)' + JSON.stringify(this.contactDetails));
                addNewBusinessContact({ recBusinessDetailsContact: JSON.stringify(this.contactDetails) })// Call Backend
                    .then(result => {
                        if (typeof this.contactDetails.recContact.Id == 'undefined' && !this.contactDetails.isUser) {
                            this.recContact["name"] = this.contactDetails.recContact.FirstName + ' ' + this.contactDetails.recContact.LastName;
                        }
                        if (this.contactDetails.isUser) {
                            this.recContact["isNewUser"] = this.contactDetails.isUser;
                        }
                        this.notifyParent();
                    })
                    .catch(error => {
                        this.isLoading = false;
                        this.disableSubmit = false;
                        const errorMessage = handleError(error);
                        this.dispatchEvent(newErrorToast({ message: errorMessage }));
                    });
                    this.isLoading = false;
            }

            // Show Status (Success/Failure) Message
        } else if (this.buttonLabel === 'Next') {

            if (this.checkInputValidty()) {
                // perform existing user check with the ABN
                verifyUserLinkWithABN({ email: this.email, abn: this.abn, accountId: this.accountId })
                    .then(result => {

                        this.recContact = { userId: result.userId, contactId: result.contactId, firstName: result.firstName, lastName: result.lastName, phone: result.phone, email: result.email, roles: "", isNewUser: false, isUserExist: result.isUserExist, isUserPartOfSameOtherABN: result.isUserPartOfSameOtherABN, isSendInvite: result.isSendInvite, activateUser: result.activateUser, isIndividualAccountUser: result.isIndividualAccountUser  };
                        if (!result.isUserExist) { // User doesn't exist then show user details
                            this.recContact["email"] = this.email;
                            this.addNewContact = true;
                            this.showUserDetails = true;
                            this.pageHeading = 'User Details';
                            this.buttonLabel = 'Submit';
                        } else {
                            if (result.isIndividualAccountUser){
                                this.buttonLabel = 'Next';
                                this.showError = true;
                                this.userValidationError = 'The user you are trying to add can not be added to this business account. Please raise a support case to LSC to have the user added to the account.';
                            }else if (!result.isUserActive && !result.activateUser) { //User exists but inactive User who is not part of the same account/ABN.
                                this.buttonLabel = 'Next';
                                this.showError = true;
                                this.userValidationError = 'The contact is inactive in our system. Please raise a support case to have the contact added.';
                            } else if (result.isUserPartOfSameABN) { // They are part of the current ABN
                                this.buttonLabel = 'Next';
                                this.showError = true;
                                this.userValidationError = 'The contact is already associated with this Business';
                            } else if (result.isUserPartOfSameOtherABN || result.isSendInvite || result.activateUser) {//They are part of the another ABN || They are not part of an ABN ||  Part of the current ABN but user inactive. 
                                this.showUserDetails = true;
                                this.pageHeading = 'User Details';
                                this.buttonLabel = 'Submit';
                            }
                        }
                    })
                    .catch(error => {
                        const errorMessage = handleError(error);
                        this.dispatchEvent(newErrorToast({ message: errorMessage }));
                        this.isLoading = false;
                    });
            }
        }
    }

    handleCancel() {
        this.recContact = {};
        this.notifyParent();
    }

    notifyParent() {
        const openModalWindow = new CustomEvent('updateaddcontactuser', { detail: this.recContact });
        this.dispatchEvent(openModalWindow);
    }

    validateAllFields() {
        //validate Contact Details Input
        let contactDetailsValid = true;
        let addBussContDetailsCmps = this.template.querySelectorAll('c-add-business-contact-details');
        if (addBussContDetailsCmps) {
            addBussContDetailsCmps.forEach(element => {
                contactDetailsValid &= element.validateAllFields();
            });
        }
        return contactDetailsValid;
    }

    handleContactDetails(event) {
        let data = event.detail;
        let contactData = {};
        contactData = { ...this.contactDetails.recContact };
        contactData.FirstName = data.firstName;
        contactData.LastName = data.lastName;
        contactData.Phone = data.phone;
        contactData.Email = data.email;
        contactData.Id = data.contactId;
        contactData.AccountId = this.accountId;
        this.contactDetails.roles = data.roles.join(';');
        this.contactDetails.isUser = data.isNewUser;
        this.contactDetails.recContact = contactData;
        this.contactDetails.activateUser = data.activateUser;
        this.contactDetails.acrUserId = data.acrUserId;
        this.contactDetails.inviteUser = data.inviteUser;
        console.log('CustomEvent fired from Contact Details Component.. this.contactDetails' + JSON.stringify(this.contactDetails));
    }


    handleChange(event) {
        const typedValue = event.target.value;
        const trimmedValue = typedValue.trim(); 
        if (typedValue !== trimmedValue) {
            event.target.value = trimmedValue;
        }
        this.email = trimmedValue;
        this.showError = false;
    }

    checkInputValidty() {
        let result = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return result;
    }

}