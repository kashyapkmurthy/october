import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getAccountInviteDetails from '@salesforce/apex/LSC_BusinessDetailsController.getAccountInviteDetails';
import acceptInvite from '@salesforce/apex/LSC_BusinessDetailsController.acceptInvite';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AcceptUserInvite extends NavigationMixin(LightningElement) {
    accountInviteData = {};
    selectedRoles = [];
    accountInviteId;
    verificationCode;
    hasData = false;
    showError = false;
    errorMessage;
    validationError;

    get roles() {
        return [
            { label: 'Director', value: 'Director' },
            { label: 'Admin', value: 'Admin' },
        ];
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            this.setParametersBasedOnUrl();
            this.fetchInviteData();
        }
    }

    setParametersBasedOnUrl() {
        this.accountInviteId = this.urlStateParameters.inviteid || null;
    }

    connectedCallback() {
       // this.fetchInviteData();
    }

    fetchInviteData() {
        getAccountInviteDetails({ accountInviteId: this.accountInviteId })
            .then(data => {
                console.log(JSON.stringify(data));
                if (data) {
                    this.accountInviteData = data;
                    this.hasData = true;
                    console.log(JSON.stringify(this.accountInviteData));
                }
            }).catch(error => {
                this.showError = true;
                this.validationError = error.body.message;
            });
    }

    get selectedRoles() {
        return this.accountInviteData.selectedRoles.join(',');
    }


    handleVerificationCodeChange(event) {
        this.showError = false;
        this.verificationCode = event.target.value;
    }

    handleAccept() {
        if (this.checkInputValidty()) {
            this.verifyAndAcceptInvite();
        }
    }

    checkInputValidty() {
        let result = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return result;
    }

    verifyAndAcceptInvite() {
        acceptInvite({ accInviteId: this.accountInviteId, verificationCode: this.verificationCode })
            .then(data => {
                console.log('verication status::'+JSON.stringify(data));
                if (data) {
                    console.log(JSON.stringify(data));
                    this.showSuccessToast();
                    this.navigateToBusinessDetailsPage();

                } else {
                    this.showError = true;
                    this.validationError = 'Invalid verfication code!';
                }

            }).catch(error => {
                this.showError = true;
                this.validationError = error.body.message;
            });
    }

    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: 'Accept Invite Status',
            message: 'Account Invite Verification Succesful',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    navigateToBusinessDetailsPage() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'business-details'
            }
        });
    }
}