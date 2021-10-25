import { LightningElement, api, track, wire } from 'lwc';
import deleteDocument from '@salesforce/apex/LSC_LevyRecordController.deleteDocument';
import deleteDocuments from '@salesforce/apex/LSC_CaseCommentsController.deleteDocuments';
import getComments from '@salesforce/apex/LSC_CaseCommentsController.getComments';
import createComment from '@salesforce/apex/LSC_CaseCommentsController.createComment';
import USER_ID from "@salesforce/user/Id";
import { refreshApex } from '@salesforce/apex';
import { newErrorToast, handleError } from 'c/utils';

export default class CaseRecordComments extends LightningElement {
    @api recordId;
    @api ticket;
    details;
    comments = [];
    result;
    showComment = false;
    disableSubmit = false;
    isLoading = false;
    @track uploadedFiles = [];
    
    get acceptedFormats() {
        return ['.pdf','.png','.jpg'];
    }



    get hasFiles() {
        return this.uploadedFiles.length > 0;
    }   
    
    get canComment() {
        if(this.ticket.closed || this.showComment) return false;
        return true
    }

    get filesRecordId() {
        return USER_ID;
    }

    get hasComments() {
        return this.comments.length > 0;
    }

    reply() {
        this.showComment = true;
    }

    handleChange(event){
        this[event.target.name] = event.target.value;
    }   

    @wire(getComments, {recordId: '$recordId'})
    wiredComments(result) {
        this.result = result;
        if(result.data) {
            this.comments = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = error;
            this.comments = [];
        }
    }

    cancelComment() {
        this.showComment = false;
        this.details = '';
        var documents = this.uploadedFiles.map(function(el) { return el.id });
        deleteDocuments({docIds: documents})
        .then(result => {
            this.uploadedFiles = [];
        })
        .catch(error =>{
            console.log(error);
        })           
    }

    postComment() {
        var area = this.template.querySelector('lightning-textarea');
        area.reportValidity();
        if(area.checkValidity()) {
            this.disableSubmit = true;
            this.isLoading = true;
            var documents = this.uploadedFiles.map(function(el) { return el.id });
            createComment({recordId: this.recordId, body: this.details, docIds: documents})
            .then(result => {
                if(result && result.id) {
                    console.log(result.id);
                    this.showComment = false;
                    this.details = '';
                    this.uploadedFiles = [];
                    this.isLoading = false;
                    this.disableSubmit = false;
                    refreshApex(this.result);
                    const commentEvent = new CustomEvent("newcomment");
                    this.dispatchEvent(commentEvent);
                } 
                else if(result && result.error) {
                    this.isLoading = false;
                    this.disableSubmit = false;
                    throw new Error(result.error);                  
                }
            })
            .catch(error =>{
                console.log(error);
                this.isLoading = false;
                this.disableSubmit = false;
                const errorMessage = handleError(error);
                this.dispatchEvent(newErrorToast({ message: errorMessage }));
            })  
            this.isLoading = false;
        }        
         
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
}