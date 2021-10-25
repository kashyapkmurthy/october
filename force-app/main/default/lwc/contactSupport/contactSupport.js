import { LightningElement, track, wire } from 'lwc';
import isguest from '@salesforce/user/isGuest';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import CONTACT_ID from "@salesforce/schema/User.ContactId";
import USER_ID from "@salesforce/user/Id";
import deleteDocument from '@salesforce/apex/LSC_LevyRecordController.deleteDocument';
import createCase from '@salesforce/apex/LSC_ContactSupportController.createCase';
import { NavigationMixin } from 'lightning/navigation';
import { newErrorToast, handleError } from 'c/utils';

export default class ContactSupport extends NavigationMixin(LightningElement) {
    isGuestUser = isguest;
    subject;
    category;
    details;
    name;
    phone;
    email;
    showThankYou = false;
    submitDisabled = false;
    isLoading = false;
    @track uploadedFiles = [];    

    @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
    user;

    get recordId() {
        if(this.isGuestUser) return null;
        return USER_ID;
    }    

    get options() {
        if(this.isGuestUser) {
            return [
                { label: 'Assistance to make a new levy payment', value: 'Assistance to make a new levy payment' },
                { label: 'What work is leviable', value: 'What work is leviable' },
                { label: 'General enquiry', value: 'General enquiry' }
            ];
        }
        else {
            return [
                { label: 'Amend my receipt', value: 'Amend my receipt' },
                { label: 'Assistance to make a new levy payment', value: 'Assistance to make a new levy payment' },
                { label: 'Assistance with a levy refund', value: 'Assistance with a levy refund' },
                { label: 'What work is leviable', value: 'What work is leviable' },
                { label: 'General enquiry', value: 'General enquiry' }
            ];
        }

    } 

    get acceptedFormats() {
        return ['.pdf','.png','.jpg'];
    }

    get hasFiles() {
        return this.uploadedFiles.length > 0;
    }

    handleChange(event){
        this[event.target.name] = event.target.value;
    }    

    handleEmailChange(event){
        const typedValue = event.target.value;
        const trimmedValue = typedValue.trim(); 
        if (typedValue !== trimmedValue) {
            event.target.value = trimmedValue;
        }
        this.email = trimmedValue;
    }

    handleUploadFinished(event) {
        const lstUploadedFiles = event.detail.files;
        console.log(lstUploadedFiles);
        lstUploadedFiles.forEach(fileIterator => this.uploadedFiles.push({name:fileIterator.name, id:fileIterator.documentId}));
    }    

    handleFileDelete(event) {
        var scope = this;
        var doc = event.target.name;
        deleteDocument({docId: doc})
        .then(result => {
            scope.uploadedFiles = scope.uploadedFiles.filter(function (e) {
                return e.id !== doc
            });
        })
        .catch(error =>{
        })   
    }    

    openCase(event) {
        const allValid = [...this.template.querySelectorAll('lightning-combobox, lightning-input, lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
        if (allValid) {
            this.submitDisabled = true;
            this.isLoading = true;
            var documents = this.uploadedFiles.map(function(el) { return el.id });
            createCase({recordId: this.recordId, category: this.category, subject: this.subject, details: this.details, name: this.name, phone: this.phone, email: this.email, docIds: documents})
            .then(result => {
                if(result && result.id) {
                    console.log(result.id);
                    if(this.isGuestUser) {
                        this.showThankYou = true;
                    }
                    else {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: result.id,
                                objectApiName: 'Case',
                                actionName: 'view'
                            }
                        });
                    }
                } 
                else if(result && result.error) {
                    console.log(result.error);
                    this.submitDisabled = false;
                    this.isLoading = false;
                    throw new Error(result.error);               
                }
            })
            .catch(error =>{
                console.log(error)
                this.submitDisabled = false;
                this.isLoading = false;
                const errorMessage = handleError(error);
                this.dispatchEvent(newErrorToast({ message: errorMessage }));
            })               
        }
        this.isLoading = false;      
    }    
}