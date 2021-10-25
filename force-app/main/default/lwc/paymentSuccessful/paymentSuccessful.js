// Payment Successful Screen 
import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from "lightning/navigation";
import getLevyDetails from '@salesforce/apex/LSC_LevyRecordController.getLevyDetails';

export default class PaymentSuccessful extends NavigationMixin(LightningElement) {
    recordId;
    currentPageReference = null;
    urlStateParameters = null;

    // Get current Page reference
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            // Set RecordId
            this.recordId = this.urlStateParameters.id || null;
            this.fetchData();
        }
    }

    loading = false;
    error;
    levy;
    
    // fetch transation details
    fetchData() {
        getLevyDetails({ id: this.recordId })
            .then(data => {
                if (data) {
                    this.levy = data;
                    this.error = undefined;
                }
            })
            .catch(error => {
                this.error = error;
            })
            .finally(() => {
                this.loading = false;
            })
    }
    // Navigate to Levy receipt
    navigatetoReceipt() {
        let levyTrasaction = this.levy && this.levy.transactionId ? this.levy.transactionId : null;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'levy-receipt'
            },
            state: {
                recordId: levyTrasaction
            }
        });
    }

}