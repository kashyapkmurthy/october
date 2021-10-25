import { LightningElement, wire } from 'lwc';
import getData from '@salesforce/apex/LSC_AbnSwitchController.getData';
import switchAbn from '@salesforce/apex/LSC_AbnSwitchController.switchAbn';

export default class AbnSwitch extends LightningElement {
    hasMultipleAbns = false;
    selectedAbn;
    options = [];

    @wire(getData)
    abnData({ error, data }) {
        if(data) {
            console.log(data);
            this.options = data.options;
            this.hasMultipleAbns = data.hasAbns;
            this.selectedAbn = data.currentAbn;
            this.error = undefined;
            this.notifyParent();
        } else if (error) {
            this.error = error;
            this.options = [];
        }
    }

    handleChange(event) {
        this.selectedAbn = event.detail.value;
        switchAbn({accountId: this.selectedAbn})
            .then(result => {
                if(result && result == true) {
                    location = location;
                }
            })
            .catch(error =>{
                console.log(error)
            })
            
            this.notifyParent();
    }

    notifyParent(){
        //Notify Parent to reload
        const notifyParent = new CustomEvent('abnswitch', { detail: this.selectedAbn });
        this.dispatchEvent(notifyParent);
    }
}