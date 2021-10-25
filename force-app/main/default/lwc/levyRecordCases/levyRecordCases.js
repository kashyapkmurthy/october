import { LightningElement, wire, api } from 'lwc';
import getCases from '@salesforce/apex/LSC_LevyRecordController.getCases';

const mql = window.matchMedia('(max-width: 768px)');

export default class LevyRecordCases extends LightningElement {
    @api recordId;
    sortedDirection = 'desc';
    sortedBy = 'ticket';
    data = [];     
    mobileView = mql.matches;

    connectedCallback() {
        mql.addEventListener('change', (e) => {
            this.mobileView = e.matches;
        });
    }    

    get hasData() {
        if(this.data.length > 0) return true;
        return false;
    }    

    columns = [
        {
            label: 'Ticket No.',
            fieldName: 'url',
            type: 'url',
            typeAttributes: {label: { fieldName: 'ticket' }, 
            target: '_blank'}
        },        
        {
            label: 'Subject',
            fieldName: 'subject'
        },
        {
            label: 'Created',
            fieldName: 'created',
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

    @wire(getCases, {id: '$recordId'})
    wiredAccounts({ error, data }) {
        if(data) {
            this.data = data;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }    
}