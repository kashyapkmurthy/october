import { LightningElement, wire, api } from 'lwc';
import getTransactions from '@salesforce/apex/LSC_LevyRecordController.getTransactions';

export default class LevyRecordTransactions extends LightningElement {
    @api recordId;
    sortedDirection = 'desc';
    sortedBy = 'created';
    data = [];  
    
    get hasData() {
        if(this.data.length > 0) return true;
        return false;
    }

    connectedCallback() {
    }    

    columns = [
        {
            label: 'Type',
            fieldName: 'type'
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
            label: 'Status',
            fieldName: 'status'
        },
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
            { class: { fieldName: 'dueDateClass' }}
        }        
    ]

    @wire(getTransactions, {id: '$recordId'})
    wiredTransactions({ error, data }) {
        if(data) {
            this.data = data;
        } else if (error) {
            this.error = error;
            this.data = [];
        }
    }  
}