import { LightningElement, api } from 'lwc';

export default class LevyRecordTransactions extends LightningElement {
    @api recordId;
    @api levy;
    error;

    get hasDetails() {
        if(this.levy && (this.levy.approverName || this.levy.approverCompany)) return true;
        return false;
    }
}