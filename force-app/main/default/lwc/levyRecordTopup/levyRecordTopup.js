import { LightningElement, api, wire } from 'lwc';
import createTopup from '@salesforce/apex/LSC_LevyRecordController.createTopup';
import getEFT from '@salesforce/apex/LSC_LevyRecordController.getEFT';
import { NavigationMixin } from 'lightning/navigation';
import { newErrorToast, handleError } from 'c/utils';

export default class LevyRecordTopup extends NavigationMixin(LightningElement) {
    @api action;
    @api recordId;
    @api levy;
    @api eftAllowed;
    costAmount;
    levyAmount;
    topupAmount;
    transactionId;
    bsb = '';
    accNo = '';
    isEFTOpen = false;
    submitDisabled = false;

    get isTopup() {
        return this.action && this.action === 'topup';
    }

    get paidAmount() {
        if(this.levy) {
            return this.levy.amountPaid - this.levy.interestPaid;
        }
        return null;
    }

    handleClose(){
        this.dispatchEvent(new CustomEvent("close"));
    }        

    @wire(getEFT, {label : 'BCI'})
    eftDetails({ error, data }) {
        if (data) {
            this.bsb = data.bsb;
            this.accNo = data.accountNumber;
        } else if (error) {
            this.error = error;
        }
    }        

    handleChange(event){
        this.costAmount = event.target.value;
        var inputField = this.template.querySelector(".construction-cost"); 
        inputField.setCustomValidity('');
        if(parseFloat(this.costAmount) <= this.levy.totalCost) {
            inputField.setCustomValidity('New construction cost should be greater than current cost');
            this.levyAmount = 0;
            this.topupAmount = 0;
        }
        else if(parseFloat(this.costAmount) > 0) {
            this.levyAmount = Math.floor(this.costAmount * 0.0035) - this.levy.exemptionAmount;
            this.topupAmount = this.levyAmount - this.levy.amountPaid + this.levy.interestPaid;
        }
        else {
            this.levyAmount = 0;
            this.topupAmount = 0;            
        }
        inputField.reportValidity();        
    }
    
    payLevy() {
        var topupField = this.template.querySelector(".topup-amount"); 
        topupField.setCustomValidity('');
        topupField.reportValidity();   
        const allValid = [...this.template.querySelectorAll('lightning-combobox, lightning-input, lightning-textarea')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {       
            this.submitDisabled = true;  
            this.isLoading = true;                   
            createTopup({id: this.recordId, cost: this.costAmount})
            .then(result => {
                if(result && result.id) {
                    this.transactionId = result.id;
                    if(!this.eftAllowed) {
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                pageName: 'payment'
                            },
                            state: {
                                transactionId: result.id
                            }
                        });
                    }
                    else {
                        this.isLoading = false;
                        this.submitDisabled = false;
                        this.isEFTOpen = true;                        
                    }
                } 
                else if(result && result.error) {
                    this.isLoading = false;  
                    this.submitDisabled = false;                       
                    throw new Error(result.error);
                    // disabled field are always valid
                    // topupField = this.template.querySelector(".topup-amount"); 
                    // topupField.setCustomValidity(result.error);
                    // topupField.reportValidity();                 
                }
            })
            .catch(error =>{
                this.isLoading = false;
                this.submitDisabled = false;
                const errorMessage = handleError(error);
                this.dispatchEvent(newErrorToast({ message: errorMessage }));
            })
        } 
    }

    payCPP() {
        this.submitDisabled = true;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'payment'
            },
            state: {
                transactionId: this.transactionId
            }
        });        
    }
    // Note: Handle Click for Close Button
     handleClickClose(){
        this.isEFTOpen= false;
    }
}