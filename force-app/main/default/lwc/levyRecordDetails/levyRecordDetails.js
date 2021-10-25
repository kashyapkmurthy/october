import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getEFT from '@salesforce/apex/LSC_LevyRecordController.getEFT';

export default class LevyRecordTransactions extends NavigationMixin(LightningElement) {
    @api recordId;
    @api levy;
    @api canPay;
    @api eftAllowed;
    @api hasInterest;
    error;
    bsb = '';
    accNo = '';  
    isEFTModal = false;
    isInterestModal = false;

    @wire(getEFT, {label : 'BCI'})
    eftDetails({ error, data }) {
        if (data) {
            this.bsb = data.bsb;
            this.accNo = data.accountNumber;
        } else if (error) {
            this.error = error;
        }
    }          

    get paidDate() {
        if(this.levy && this.levy.datePaid) {
            let dt = new Date(this.levy.datePaid);
            return Intl.DateTimeFormat('en-AU').format(dt);
        }
        return '';
    }

    get dueDate() {
        if(this.levy && this.levy.dueDate) {
            let dt = new Date(this.levy.dueDate);
            return Intl.DateTimeFormat('en-AU').format(dt);
        }
        return null;
    }


    get canPayCpp() {
        if(this.levy.isBigTransaction && !this.isInterestModal) return false;
        if(this.isInterestModal && this.levy.interestDue >= 1000000) return false;
        return true;
    }

    handlePay() {
        if(this.eftAllowed || this.levy.isBigTransaction) {
            this.isEFTModal = true;
            this.isInterestModal = false;
        }
        else {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'payment'
                },
                state: {
                    transactionId: this.levy.transactionId
                }
            });      
        }
    }

    get isNotCase() {
        if(this.levy.status == 'Awaiting Exemption Decision' || this.levy.status == 'Awaiting Instalments Decision') return false;
        return true;
    }

    handleInterestPay() {
        if(this.eftAllowed || this.levy.interestDue >= 1000000) {
            this.isEFTModal = true;
            this.isInterestModal = true;
        }
        else {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'payment'
                },
                state: {
                    transactionId: this.levy.interestId
                }
            });      
        }        
    }

    closeModal() {
        this.isEFTModal = false;
    }    

    payCPP() {
        if(this.isInterestModal) {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'payment'
                },
                state: {
                    transactionId: this.levy.interestId
                }
            });  
        }
        else {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'payment'
                },
                state: {
                    transactionId: this.levy.transactionId
                }
            });  
        }      
    }   
    // Note: Handle Click for Close Button
    handleClickClose(){
        this.isEFTModal = false;
    }
}