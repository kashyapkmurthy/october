import { LightningElement, api } from 'lwc';

export default class LscModal extends LightningElement {


    @api showMessage;
    @api modalHeading;
    @api showHeader = false;
    @api inputData;
    showModal;
    
    connectedCallback() {
        this.showModal = this.showMessage;
        this.showContent=true;
    }
    
    handleCancel() {
        this.notifyParentToCloseModalWindow();
    }

    get isNewContact(){
        return (typeof this.inputData.contactId === 'undefined' && typeof this.inputData.isNewUser === 'undefined') ? true : false;
    }


    notifyParentToCloseModalWindow() {
        const closeModal = new CustomEvent('updatemodalclose', { detail: false });
        this.dispatchEvent(closeModal);
    }

    get showContactSuccess(){
        return (this.inputData.isUserPartOfSameOtherABN   || this.inputData.activateUser  ) ? true: false;
    }
}