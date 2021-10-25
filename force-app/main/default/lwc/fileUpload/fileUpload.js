import { LightningElement, wire, api, track } from 'lwc';
import deleteDocument from '@salesforce/apex/LSC_LevyPaymentUtility.deleteDocument';
import { NavigationMixin } from 'lightning/navigation';

export default class LevyRecordCaseRequest extends NavigationMixin(LightningElement) {
    @api fileUploadLabel;
    @api recordId;
    @api uploadedFileList;
    acceptedFormats;
    @track uploadedFiles = [];

    get acceptedFormats() {
        return ['.pdf','.png','.jpg'];
    }

    get hasFiles() {
        return this.uploadedFiles.length > 0;
    }

    handleUploadFinished(event) {
        const lstUploadedFiles = event.detail.files;
        console.log(lstUploadedFiles);
        lstUploadedFiles.forEach(fileIterator => this.uploadedFiles.push({name:fileIterator.name, id:fileIterator.documentId}));
    }

    handleFileDelete(event) {
        var scope = this;
        var doc = event.target.name;
        deleteDocument({docId: doc})
        .then(result => {
            scope.uploadedFiles = scope.uploadedFiles.filter(function (e) {
                return e.id !== doc
            });
        })
        .catch(error =>{
        })   
    }

    @api
    validateAllFields(){
        console.log('file upload validateAll fields...');
        const fileUploadEvent = new CustomEvent('fileupload', {  detail : this.uploadedFiles});                                   
        // Dispatches the event.
        this.dispatchEvent(fileUploadEvent); 

        return true;
    } 

    connectedCallback(){
        this.uploadedFiles = this.uploadedFileList && this.uploadedFileList.length>0 ? JSON.parse(JSON.stringify(this.uploadedFileList)) :[];
    }


}