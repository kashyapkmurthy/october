import { LightningElement,api, wire, track } from 'lwc';
import strUserId from '@salesforce/user/Id';
import getRelatedContactsById from '@salesforce/apex/LSC_AccountController.getRelatedContactsById';
import processBusinessDetailsContacts from '@salesforce/apex/LSC_BusinessDetailsController.processBusinessDetailsContacts';
import deactivateBusinessContact from '@salesforce/apex/LSC_BusinessDetailsController.deactivateBusinessContact';
import { refreshApex } from '@salesforce/apex';
import { newErrorToast, handleError } from 'c/utils';

export default class BusinessAccountContacts extends LightningElement {
    
    @track businessDetailsContacts = [];
    @api recordId;
    @api abn;
    businessDetailsContact = {};
    result;
    buttonLabel = 'Edit';
    isAdmin = false;
    isLoading = false;
    showAddNewModal = false;
    showLSCModal;
    contactData={};
    showDeleteConfirmationModal = false;
    indexPos;
    deleteMessage = 'You are deleting a contact or user. Do you confirm?'

    connectedCallback() {
        console.log('In BusinessDetailsContacts connectedCallback() ');
    }

    @wire(getRelatedContactsById, { accountId: '$recordId' })
    wiredBusinessDetailContacts(result) {
        this.result = result;
        if (result.data) {
            console.log(this.result.data);
            this.businessDetailsContacts = JSON.parse(JSON.stringify(result.data));
            this.isAdmin=false;
            console.log(this.businessDetailsContacts);
            this.adminCheck();
        } else if (result.error) {
            this.error = result.error;
        }
    }

    adminCheck() {
        //Determine whether logged in user is Admin or not
        const currentUserData = this.businessDetailsContacts.find(element => element.acrUserId == strUserId);
        if (typeof currentUserData != 'undefined' && currentUserData) {
            console.log('currentUser Role:::' + currentUserData.roles);
            if(currentUserData.roles.split(';').includes('Admin')) {
                this.isAdmin=true;
            }
        }
    }

    saveContacts() {
        this.isLoading = true;
        processBusinessDetailsContacts({ accountId:this.recordId, lstBusinessDetailsContacts: JSON.stringify(this.businessDetailsContacts) })
            .then(result => {
                console.log('contacts updated');
                this.isLoading = false;
                refreshApex(this.result);
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                const errorMessage = handleError(error);
                this.dispatchEvent(newErrorToast({ message: errorMessage }));
            });
    }


    get renderReadMode() {
        return this.buttonLabel === 'Edit' ? "true" : false;
    }

    handleClick() {
        if (this.validateAllFields()) {
            //Save the contacts list to the backend when button label is 'Save'
            if (this.buttonLabel === 'Save') {
                this.saveContacts();
            }
            this.buttonLabel === 'Edit' ? this.buttonLabel = 'Save' : this.buttonLabel = 'Edit';
        }
    }

    handleCancelClick() {
        this.buttonLabel = 'Edit';
        refreshApex(this.result);
        this.isLoading=false;

    }

    validateAllFields() {
        return this.checkInputValidty();
    }

    handleAddContact() {
        this.showAddNewModal=true;
    }
    
    //Subscibed to event published from addContactDetails Component
    handleAddContactUserUpdate(event){
        this.showAddNewModal=false;
        this.contactData = event.detail;
        if(Object.keys(JSON.parse(JSON.stringify(this.contactData))).length != 0){
            this.showMessage=true;
            this.showLSCModal=true;
        }
    }

    //Subscibed to event published from lscModal Component
    handleModalClose(event){
        this.showLSCModal=event.detail;
        refreshApex(this.result);
    }

    removeRow(event) {
        this.indexPos = event.currentTarget.name;
        //Logic to deactivate ACR the record & logic to deactivate the user record
        let selectedRow=this.businessDetailsContacts.find(ele => ele.key == event.currentTarget.dataset.id);
        if(selectedRow.id !== null){
            this.showDeleteConfirmationModal=true;
        }
    }

    handleDeleteConfirmation(event){
        if(event.detail){
            this.deactivateACR(this.indexPos);
            this.showDeleteConfirmationModal = false;
        }else{
            this.showDeleteConfirmationModal=false;
        }
    }    

    deactivateACR(index){
        deactivateBusinessContact({ accountId: this.recordId, recBusinessDetailsContact: JSON.stringify(this.businessDetailsContacts[index]) })
        .then(result => {
            console.log('ACR Deactivated');
            this.isLoading = true;
            this.businessDetailsContacts.splice(index,1);
            this.isLoading = false;
        })
        .catch(error => {
            this.isLoading=false;
            const errorMessage = handleError(error);
            this.dispatchEvent(newErrorToast({ message: errorMessage })); 
        });
   
    }

    handleFNameChange(event) {
        let contactElement = this.businessDetailsContacts.find(ele => ele.key == event.target.dataset.id).recContact;
        contactElement.FirstName = event.target.value.trim();
        this.businessDetailsContacts = [...this.businessDetailsContacts];
    }

    handleLNameChange(event) {
        let contactElement = this.businessDetailsContacts.find(ele => ele.key == event.target.dataset.id).recContact;
        contactElement.LastName = event.target.value.trim();
        this.businessDetailsContacts = [...this.businessDetailsContacts];
    }

    handlePhoneChange(event) {
        let contactElement = this.businessDetailsContacts.find(ele => ele.key == event.target.dataset.id).recContact;
        contactElement.Phone = event.target.value;
        this.businessDetailsContacts = [...this.businessDetailsContacts];
    }

    handleEmailChange(event) {
        let contactElement = this.businessDetailsContacts.find(ele => ele.key == event.target.dataset.id).recContact;
        const typedValue = event.target.value;
        const trimmedValue = typedValue.trim(); 
        if (typedValue !== trimmedValue) {
            event.target.value = trimmedValue;
        }
        contactElement.Email = trimmedValue;
        this.businessDetailsContacts = [...this.businessDetailsContacts];
    }
    handleDirectorChange(event) {
       let currentElement = this.businessDetailsContacts.find(ele => ele.key == event.target.dataset.id);
        currentElement.isDirector = event.target.checked;
        this.businessDetailsContacts = [...this.businessDetailsContacts];
    }
    handleAdminChange(event) {
        let currentElement = this.businessDetailsContacts.find(ele => ele.key == event.target.dataset.id);
        currentElement.isAdmin = event.target.checked;
        this.businessDetailsContacts = [...this.businessDetailsContacts];
    }

    checkInputValidty() {
        let result = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        return result;
    }
}