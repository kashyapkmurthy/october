import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FilesList extends NavigationMixin(LightningElement) {

    @api files;
    @track originalMessage;
    @track isDialogVisible = false;

    filePreview(event) {
        // Naviagation Service to the show preview
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                // assigning ContentDocumentId to show the preview of file
                selectedRecordId: event.currentTarget.dataset.id
            }
        })
    }

    handleDelete(event) {
        if (event.target) {
            if (event.target.name === 'openConfirmation') {
                //it can be set dynamically based on your logic
                this.originalMessage = event.currentTarget.dataset.id;
                //shows the component
                this.isDialogVisible = true;
            } else if (event.target.name === 'confirmModal') {
                if (event.detail !== 1) {
                    if (event.detail.status === 'confirm') {
                        //delete content document
                        let contentDocumentId = event.detail.originalMessage;
                        deleteRecord(contentDocumentId)
                            .then(() => {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Success',
                                        message: 'File deleted',
                                        variant: 'success'
                                    })
                                );
                                this.dispatchEvent(new CustomEvent('filedelete', {}));
                            })
                            .catch(error => {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error deleting file',
                                        message: error.body.message,
                                        variant: 'error'
                                    })
                                );
                            });
                    }
                }

                //hides the component
                this.isDialogVisible = false;
            }
        }
    }
}