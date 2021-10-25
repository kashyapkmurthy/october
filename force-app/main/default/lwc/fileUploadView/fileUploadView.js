import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getRelatedFiles from '@salesforce/apex/LSC_FileUploadViewController.getRelatedFiles';

export default class FileUploadView extends LightningElement{
    @api label;
    @api formats = '.png,.pdf';
    @api recordId;

    get acceptedFormats() {
        return this.formats.split(',');
    }

    @wire(getRelatedFiles, { recordId: '$recordId' })
    files;

    handleActionFinished(event) {
        //refresh the list of files
        refreshApex(this.files);
    }
}