import { LightningElement, api, wire } from 'lwc';
import getAttachments from '@salesforce/apex/LSC_CaseRecordDetailsController.getAttachments';
import { refreshApex } from '@salesforce/apex';

export default class CaseRecordDetails extends LightningElement {
    @api recordId;
    @api ticket;
    result;
    attachments = [];

    get hasAttachments() {
        return this.attachments.length > 0;
    }

    @wire(getAttachments,  {recordId: '$recordId'})
    attachmentDetails(result) {
        this.result = result;
        if (result.data) {
            this.attachments = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.attachments = [];
        }
    }      

    @api forceRefresh() {
        return refreshApex(this.result);
    }    
}