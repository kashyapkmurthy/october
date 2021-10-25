import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import getLevyDetails from '@salesforce/apex/LSC_LevyRecordController.getLevyDetails';
import formFactorPropertyName from '@salesforce/client/formFactor';
import BCICommunityLink from '@salesforce/label/c.BCI_Community_Link';

export default class LevyRecord extends NavigationMixin(LightningElement) {
    
    @api recordId;
    isAction = false;
    levy;
    canPay = false;
    eftDetails = false;
    eftAllowed = false;
    hasAccess = true;
    hasInterest = false;
    loading = true;
    levyName;

    action;
    type;

    currentPageReference = null; 
    urlStateParameters = null;
    
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
          this.urlStateParameters = currentPageReference.state;
          this.setParametersBasedOnUrl();
       }
    }    

    setParametersBasedOnUrl() {
        this.action = this.urlStateParameters.action || null;
        this.type = this.urlStateParameters.type || null;
    }        

    get items() {
        let buttons = [];
        if(this.levy && this.hasAccess) {
            buttons.push({
                id: 'menu-item-1',
                label: 'Request support',
                value: 'support',
            })
        }
        if(this.levy && this.levy.status === 'Paid') {
            if(this.levy.transactionId) {
                buttons.push({
                    id: 'menu-item-4',
                    label: 'Print a receipt',
                    value: 'receipt',
                })                
            }
            if(this.levy.canTopup) {
                buttons.push({
                    id: 'menu-item-3',
                    label: 'Top up levy',
                    value: 'topup',
                })   
            }
            if(this.levy.canRefund) {
                buttons.push({
                    id: 'menu-item-2',
                    label: 'Request refund',
                    value: 'refund',
                })   
            }            
        }

        return buttons;
    }

    connectedCallback(){
        this.fetchData();
    }    

    fetchData(){
        getLevyDetails({ id: this.recordId })
        .then(data => {
            if (data) {
                this.levy = data;
                this.hasAccess = data.hasAccess;
                this.canPay = data.canPay;
                this.eftDetails = data.eftRefund;
                this.eftAllowed = data.eftAllowed;
                this.hasInterest = data.hasInterest;
                this.levyName = data.name;
                this.error = undefined;
            }             
        })
        .catch(error => {
            this.error = error;
            this.contacts = undefined;            
        })
        .finally(() => { 
            this.loading = false; 
        })
    }    

    handleMenuSelect(event) {
        const selectedItemValue = event.detail.value;
        if(selectedItemValue === 'support') {
            this.action = selectedItemValue;
            this.type = null;
        }
        else if(selectedItemValue === 'refund') {
            this.action = 'support';
            this.type = 'refund';
        }
        else if(selectedItemValue === 'topup') {
            this.action = selectedItemValue;
        }
        else if(selectedItemValue === 'receipt') {
            if (formFactorPropertyName === 'Large') {
                this[NavigationMixin.Navigate]({
                    type: 'comm__namedPage',
                    attributes: {
                        pageName: 'levy-receipt'
                    },
                    state: {
                        recordId: this.levy.transactionId
                    }
                }); 
            } else {
                let url = BCICommunityLink + "/apex/LevyReceipt?id=" + this.levy.transactionId;
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                url: url
                            }
                        },
                        false
                );
            }
        }        
    }    

    handleClose() {
        this.action = null;
        this.type = null;
    }    
}