import { LightningElement, wire, api } from 'lwc';
import getPayments from '@salesforce/apex/LSC_LevyRecordController.getPayments';

export default class LevyRecordPayments extends LightningElement {
    @api recordId;
    data = [];     

    get hasData() {
        if(this.data.length > 0) return true;
        return false;
    }   
    
    connectedCallback() {
    }
    

    columns = [
        {
            label: 'Paid for',
            fieldName: 'type'
        },  
        {
            type: 'currency',            
            label: 'Amount paid',
            fieldName: 'amount'
        },
        {
            label: 'Date paid',
            fieldName: 'datePaid',
            type: "date",
            typeAttributes:{
                month: "2-digit",
                day: "2-digit",
                year: "numeric"
            }             
        },
        {
            label: 'Status',
            fieldName: 'status'
        }        
    ]

    @wire(getPayments, {id: '$recordId'})
    wiredPayments({ error, data }) {
        if(data) {
            this.data = data;
        } else if (error) {
            this.error = error;
            this.data = [];
        }
    }    
}