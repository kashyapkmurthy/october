import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getUserProfileData from '@salesforce/apex/LSC_UserController.getUserProfileData';
import updateUserProfile from '@salesforce/apex/LSC_UserController.updateUserProfile';
import BCICommunityLink from '@salesforce/label/c.BCI_Community_Link';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class MyProfile extends LightningElement {
    @track
    userData = [];
    result;
    phone;
    mailingAddressDetails;
    mailingFullAddress;
    buttonLabel = 'Edit';
    isLoading = false;
    showLinkNSW = false;

    connectedCallback() {
        console.log('In connectedCallback()  ');
    }

    get hasData() {
        for (let key in this.userData) {
            if (this.userData.hasOwnProperty(key))
                return true;
        }
        return false;
    }

    @wire(getUserProfileData)
    wireduserProfileData(result) {
        this.result = result;
        if (result.data) {
            console.log(result.data);
            this.userData = { ...result.data };
            this.mailingFullAddress = this.userData.mailingAddress.fullAddress;
            this.mailingAddressDetails = this.userData.mailingAddress;
            this.showLinkNSW = !this.userData.isServiceNSWLinked;
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
            this.updateUserDetails();
        }
        if (this.buttonLabel === 'Edit') {
            this.buttonLabel = 'Save';
        }
    }

    updateUserDetails() {
        this.isLoading = true;
        updateUserProfile({ strUserData: JSON.stringify(this.userData) })
            .then(result => {
                console.log('User details updated');
                this.isLoading = false;
                this.buttonLabel = 'Edit';
                this.showSuccessToast();
                refreshApex(this.result);
            })
            .catch(error => {
                var errorMsg;
                if (Array.isArray(error.body)) {
                    this.errorMsg = error.body.map(e => e.message).join(', ');
                } else //if (typeof error.body.message === 'string') {
                    this.errorMsg = error.body.message;
                // }
                console.log('proper error--->' + this.errorMsg);
                this.isLoading = false;
            });

    }

    handleMailingAddressDetails(event) {
        this.mailingAddressDetails = event.detail;
        this.mailingFullAddress = this.mailingAddressDetails.fullAddress;
        this.userData.mailingAddress = this.mailingAddressDetails;
    }

    handleFirstNameChange(event) {
        console.log(JSON.stringify(this.result.data));
        //this.phone = event.target.value;
        this.userData.firstName = event.target.value;
    }

    handleLastNameChange(event) {
        console.log(JSON.stringify(this.result.data));
        //this.phone = event.target.value;
        this.userData.lastName = event.target.value;;
    }

    handlePhoneChange(event) {
        console.log(JSON.stringify(this.result.data));
        this.phone = event.target.value;
        this.userData.phone = this.phone;
    }

    checkInputValidty() {
        let result = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return result;
    }

    handleCancelClick(event) {
        this.userData = { ...this.result.data };
        this.template.querySelectorAll('lightning-input').forEach(element => {
           element.setCustomValidity("");
          });
          this.buttonLabel = 'Edit';
        
    }

    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Profile update successful.',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    handleSNSWLink() {
        this.isLoading = true;
        location.href = BCICommunityLink+'/services/auth/link/myservicensw';
    }
}