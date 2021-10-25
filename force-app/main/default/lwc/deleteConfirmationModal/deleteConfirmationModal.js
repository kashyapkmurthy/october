import { LightningElement, api } from 'lwc';

export default class DeleteConfirmationModal extends LightningElement {


    @api showModal;
    @api message;
    @api modalHeading;
    @api showHeader = false;
    showMessage;

    connectedCallback() {
        this.showMessage = true;
    }

    handleNo() {
        this.notifyParentToCloseModalWindow(false);
    }

    handleYes() {
        this.notifyParentToCloseModalWindow(true);
    }

    notifyParentToCloseModalWindow(isDelete) {
        const closeModal = new CustomEvent('confirmdelete', { detail: isDelete });
        this.dispatchEvent(closeModal);
    }
}