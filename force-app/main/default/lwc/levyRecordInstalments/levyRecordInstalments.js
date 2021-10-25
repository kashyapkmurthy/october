import { LightningElement, wire, api } from 'lwc';
import getInstalments from '@salesforce/apex/LSC_LevyRecordController.getInstalments';
import getOverdueInstalment from '@salesforce/apex/LSC_LevyRecordController.getOverdueInstalment';
import getEFT from '@salesforce/apex/LSC_LevyRecordController.getEFT';
import { NavigationMixin } from 'lightning/navigation';

export default class LevyRecordTransactions extends NavigationMixin(LightningElement) {
    @api recordId;
    @api eftAllowed;
    @api levy
    data = [];  
    hasOverdue = false;
    rowOffset = 0;
    overdueDate;   
    currentTransaction;
    currentAmount = 0;
    bsb = '';
    accNo = '';    
    isEFTModal;

    get hasData() {
        if(this.data.length > 0) return true;
        return false;
    }    

    get canPayCPP() {
        if(this.currentAmount > 1000000) return false;
        return true;
    }

    get hasInstalments() {
        if(this.levy && this.levy.hasInstalments) return true;
        return false
    }    

    connectedCallback() {
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

    columns = [
        {
            label: "Date due",
            fieldName: "dueDate",
            type: "date",
            typeAttributes:{
                month: "2-digit",
                day: "2-digit",
                year: "numeric"
            },
            cellAttributes: 
            { 
                class: {fieldName: 'dueDateClass'}
            }            
        },        
        {
            type: 'currency',
            label: 'Amount',
            fieldName: 'amount'
        },
        {
            type: 'currency',
            label: 'Paid Amount',
            fieldName: 'paidAmount'
        },        
        {
            label: "Date paid",
            fieldName: "datePaid",
            type: "date",
            typeAttributes:{
                month: "2-digit",
                day: "2-digit",
                year: "numeric"
            } 
        },     
        {
            type:  'button',
            typeAttributes: 
            {
                label: {fieldName : 'buttonTitle'},
                name: {fieldName : 'buttonTitle'},
                variant: 'neutral'
            },
            cellAttributes: 
            { 
                class: {fieldName: 'buttonClass'}
            }                 
        }    
    ]  

    @wire(getInstalments, {id: '$recordId'})
    wiredInstalments({ error, data }) {
        if(data) {      
            this.data = data;
        } else if (error) {
            this.error = error;
            this.data = [];
        }
    } 

    @wire(getOverdueInstalment, {id: '$recordId'})
    wiredOverdueInstalment({ error, data }) {
        if(data) {
            this.hasOverdue = data.hasOverdue;
            this.overdueDate = data.overdueDate;
        } else if (error) {
            this.error = error;
            this.hasOverdue = false;
        }
    }     
 
    closeModal() {
        this.isEFTModal = false;
    }   

    rowAction(event){
        if(event.detail.row.buttonTitle === 'Pay now') {
            let amountToPay = 0;
            if(event.detail.row.amount && event.detail.row.paidAmount) {
                amountToPay = event.detail.row.amount - event.detail.row.paidAmount;
            }
            else if(event.detail.row.amount) {
                amountToPay = event.detail.row.amount
            } 
            if(this.eftAllowed || amountToPay > 1000000) {
                this.currentTransaction = event.detail.row.id;
                this.currentAmount = amountToPay;
                this.isEFTModal = true;
            }
            else {
                this[NavigationMixin.Navigate]({
                    type: 'comm__namedPage',
                    attributes: {
                        pageName: 'payment'
                    },
                    state: {
                        transactionId: event.detail.row.id
                    }
                });                 
            }
        }
        else if(event.detail.row.buttonTitle === 'Print receipt') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'levy-receipt'
                },
                state: {
                    recordId: event.detail.row.id
                }
            });  
        }
    }    
    
    handlePay(event) {
        let curRow = data.find(x => x.id === event.target.name)
        let amountToPay = 0;
        if(curRow && curRow.amount && curRow.paidAmount) {
            amountToPay = event.detail.row.amount - event.detail.row.paidAmount;
        }
        else if(curRow && curRow.amount) {
            amountToPay = event.detail.row.amount
        }         
        if(this.eftAllowed || amountToPay > 1000000) {
            this.currentTransaction = event.target.name;
            this.currentAmount = amountToPay;
            this.isEFTModal = true;
        }
        else {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'payment'
                },
                state: {
                    transactionId: event.target.name
                }
            });             
        }
    }

    payCPP() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'payment'
            },
            state: {
                transactionId: this.currentTransaction
            }
        });        
    }
    // Note: Handle Click for Close Button
    handleClickClose(){
        this.isEFTModal = false;
    }
}