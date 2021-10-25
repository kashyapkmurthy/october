import { LightningElement, wire } from 'lwc';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import notifyBanner from '@salesforce/messageChannel/RegMessageChannel__c';
import formFactorPropertyName from '@salesforce/client/formFactor';

export default class LSC_SNSWHome extends LightningElement {
    showBanner = true;
    subscription = null;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    get smallDevView() {
        return formFactorPropertyName === 'Small' ? true : false;
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                notifyBanner,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    handleMessage(message){
        this.showBanner = false;
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleClose(){
        this.showBanner = false;
    }
}