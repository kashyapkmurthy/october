import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DummyParentComponent extends LightningElement {
    showaddBusinessPage = false;

    handleClick(event){
        this.showaddBusinessPage = true;
    }


    get showaddBusinessPage(){
        this.showaddBusinessPage === true;
    }

    handleEvent(event){
        let evtDetail = event.detail;
        this.showaddBusinessPage = false;
        if(evtDetail === 'success'){
            this.showSuccessToast();
        } else{
            this.showFailureToast();
        }
    }

    showSuccessToast(){
        const evt = new ShowToastEvent({
            title: 'Add Business Status',
            message: 'Account created succesfully',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    showFailureToast(){
        const evt = new ShowToastEvent({
            title: 'Add Business Status',
            message: 'Account creation failed',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

}