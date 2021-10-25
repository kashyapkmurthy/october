import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getBusinessDetailsById from '@salesforce/apex/LSC_AccountController.getBusinessDetailsById';
import processBusinessDetails from '@salesforce/apex/LSC_AccountController.processBusinessDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { newErrorToast, handleError } from 'c/utils';

export default class BusinessDetails extends LightningElement {

    businessDetails={};
    recordId;
    showaddBusinessPage = false;
    value;
    result;
    phone;
    email;
    isAdmin = false;
    isLoading = false;
    streetAddressDetails;
    postalAddressDetails;
    streetFullAddress;
    postalFullAddress;
    buttonLabel = 'Edit';
    abn;
    @track businessData;

    connectedCallback() {
        console.log('In BusinessDetails connectedCallback()  ');
    }

    get hasData() {
        for (let key in this.businessDetails) {
            if (this.businessDetails.hasOwnProperty(key))
                return true;
        }
        return false;
    }

    @wire(getBusinessDetailsById, { accountId: '$recordId' })
    wiredBusinessDetails(result) {
        this.result = result;
        if (result.data) {
            console.log(result.data);
            this.businessDetails = result.data;
            this.businessData = {...this.businessDetails};
            this.abn = this.businessDetails.abn;
            this.isAdmin = this.businessDetails.isAdmin;
            this.streetFullAddress = this.businessDetails.streetAddress.fullAddress;
            this.streetAddressDetails = this.businessDetails.streetAddress;
            this.postalFullAddress = this.businessDetails.postalAddress.fullAddress;
            this.postalAddressDetails = this.businessDetails.postalAddress;
        } else if (result.error) {
            this.error = result.error;
            this.data = [];
        }
    }

    @api
    validateAllFields() {
        console.log('busniness details validateAll fields...');
        //validate Address Search Input
        let addressSearchValid = true;
        let addrSearchCmps = this.template.querySelectorAll('c-new-address-search');
        if (addrSearchCmps) {
            addrSearchCmps.forEach(element => {
                addressSearchValid &= element.validateAllFields();
            });
        }
        return addressSearchValid && this.checkInputValidty();
    }

    get renderReadMode() {
        return this.buttonLabel === 'Edit' ? true : false;
    }

    handleClick() {
        console.log('inside handleClick()')
        if (this.buttonLabel === 'Save' && this.validateAllFields()) {
            this.updateBusinessDetails();
        }
        if (this.buttonLabel === 'Edit') {
            this.buttonLabel = 'Save';
        }
    }

    updateBusinessDetails() {
        this.isLoading = true;
        processBusinessDetails({ strBusinessDetails: JSON.stringify(this.businessData) })
            .then(result => {
                console.log('business details updated');
                this.isLoading = false;
                this.buttonLabel = 'Edit'
                refreshApex(this.result);
                this.isLoading = false;
                //this.buttonLabel === 'Edit' ? this.buttonLabel = 'Save' : this.buttonLabel = 'Edit';
            })
            .catch(error => {
                this.isLoading = false;
                const errorMessage = handleError(error);
                this.dispatchEvent(newErrorToast({ message: errorMessage })); 
            });

    }

    handlePostalAddressDetails(event) {
        this.postalAddressDetails = event.detail;
        this.postalFullAddress = this.postalAddressDetails.fullAddress;
        this.businessData.postalAddress = this.postalAddressDetails;
    }

    handleStreetAddressDetails(event) {
        this.streetAddressDetails = event.detail;
        this.streetFullAddress = this.streetAddressDetails.fullAddress;
        this.businessData.streetAddress = this.streetAddressDetails;
    }

    handlePhoneChange(event) {
        console.log(JSON.stringify(this.businessDetails));
        this.phone = event.target.value;
        this.businessData.phone = this.phone;
        console.log(JSON.stringify(this.businessDetails));
    }

    handleEmailChange(event) {
        console.log(JSON.stringify(this.businessDetails));
        const typedValue = event.target.value;
        const trimmedValue = typedValue.trim(); 
        if (typedValue !== trimmedValue) {
            event.target.value = trimmedValue;
        }
        this.businessData.email = trimmedValue;
        console.log(JSON.stringify(this.businessDetails));
    }

    checkInputValidty() {
        let result = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return result;
    }

    handleCancelClick() {
        this.buttonLabel = 'Edit';
        this.businessData = {...this.businessDetails};
        
        this.template.querySelectorAll('lightning-input').forEach(element => {
            if(!element.checkValidity()){
                setTimeout(() => {
                    this.setInputValidity(element, "");
                }, 0); 
            }
        });
    }

    handleAddBusiness(event) {
        this.showaddBusinessPage = true;
    }

    get showaddBusinessPage() {
        this.showaddBusinessPage === true;
    }

    handleAddBusinessEvent(event) {
        let evtDetail = event.detail;
        this.showaddBusinessPage = false;
        if (evtDetail === 'success') {
            this.showSuccessToast();
        } else {
            this.showFailureToast();
        }
    }

    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: 'Add Business Status',
            message: 'Account created succesfully',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
        location.reload();

    }

    showFailureToast() {
        const evt = new ShowToastEvent({
            title: 'Add Business Status',
            message: 'Account creation failed',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    handleABNChange(event) {
        this.recordId = event.detail;
        refreshApex(this.result);
    }

    setInputValidity(input, message){
        input.setCustomValidity(message);
        //input.setInputValidity(message);
        input.reportValidity();       
    }  
}