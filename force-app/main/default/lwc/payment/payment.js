import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getTransactionDetails from '@salesforce/apex/LSC_PaymentController.getTransactionDetails';
import updatePaymentReferenceId from '@salesforce/apex/LSC_PaymentController.updatePaymentReferenceId';
import startCPPPaymentReferenceContinuation from '@salesforce/apexContinuation/LSC_FetchCPPPaymentReferenceDetail.startCPPPaymentReferenceContinuation';
import formFactorPropertyName from '@salesforce/client/formFactor';

export default class Payment extends NavigationMixin(LightningElement) {

    transactionId;
    isLoading = true;
    paymentReference;
    showError = false;
    errorMessage;

    get mobileView () {
        return formFactorPropertyName !== 'Large';
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            this.setParametersBasedOnUrl();
            if (!this.isUndefined(this.urlStateParameters.transactionId)) {
                getTransactionDetails({ transactionId: this.transactionId })
                    .then(result => {
                        if (result) {
                            startCPPPaymentReferenceContinuation({ transactionData: JSON.stringify(result)})
                                .then(result => {
                                    if (result.payments) {
                                        updatePaymentReferenceId({ transactionId: this.transactionId, paymentReferenceId: result.payments[0].paymentReference })
                                            .then(result => {
                                                if (result) {
                                                    this.isLoading = false;
                                                    this.navigateToPaymentPage(result);
                                                }
                                            })
                                            .catch(error => {
                                                this.isLoading = false;
                                                this.showError = true;
                                                this.errorMessage = error.body.message;
                                            });
                                    }
                                })
                                .catch(error => {
                                    this.isLoading = false;
                                    this.showError = true;
                                    this.errorMessage = error.body.message;
                                });
                        }
                    }).catch(error => {
                        this.isLoading = false;
                        if (error.body.message === 'Amount > $1M') {
                            this.isAmountGreaterThanMillion = true;
                        } else {
                            this.showError = true;
                            this.errorMessage = error.body.message;
                        }
                    });
            }
        }
    }

    setParametersBasedOnUrl() {
        if (!this.isUndefined(this.urlStateParameters.transactionId)) {
            this.transactionId = this.urlStateParameters.transactionId || null;
        }
    }

    isUndefined(input) {
        return input === void 0;
    }

    navigateToPaymentPage(redirectURL) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: redirectURL
            },
        }).then(url => {
            window.open(url, "_self");
        });
    }

}