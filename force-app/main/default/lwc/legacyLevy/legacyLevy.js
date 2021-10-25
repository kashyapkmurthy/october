import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import submitApproval from '@salesforce/apex/LSC_LegacyLevyController.submitApproval';
import getData from '@salesforce/apex/LSC_LegacyLevyController.getData';
import Id from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import LEVY_OBJECT from '@salesforce/schema/LSC_LegacyLevy__c';
import { refreshApex } from '@salesforce/apex';

const FIELDS = [
    'LSC_LegacyLevy__c.LSC_LevyId__c',
    'LSC_LegacyLevy__c.LSC_ApplicationStatus__c'
];

export default class LegacyLevy extends LightningElement {
    @api recordId;
    levyId;
    error;
    isNew = false;
    isCancelled = false;
    isSuccess = false;
    data;
    paid;
    refunded;
    writeoff;
    options = [];
    result;

    @wire(getObjectInfo, { objectApiName: LEVY_OBJECT })
    levyInfo;

    get recordTypeId() {
        return this.levyInfo.data.defaultRecordTypeId;
    }

    get isLocked() {
        if((this.data && this.data.isLocked) || this.isSuccess) return true;
        return false;
    }

    handleChange(event){
        this[event.target.name] = event.target.value;
    }        

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wireLegacy({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.levyId = data.fields.LSC_LevyId__c.value;
            if(data.fields.LSC_ApplicationStatus__c.value === 'Cancelled') this.isCancelled = true;
            refreshApex(this.result);
        }
    }

    @wire(getData, { recordId: '$recordId' })
    wireData(result) {
        this.result = result;
        if (result.error) {
            this.error = error;
        } else if (result.data) {
            this.data = result.data;
            if(result.data.costOfWorks == 0 || result.data.levyPayable == 0) {
                this.error = 'Please specify the correct Cost Of Works and Levy Payable and reload the page';
            }            
            this.paid = result.data.paidAmount;
            this.refunded = result.data.refundedAmount;
            this.writeoff = result.data.writeOffAmount;         
        }
    }    

    get isConverted() {
        if(this.levyId) return true;
        return false;
    }

    get levyLink() {
        if(this.levyId) return '/' + this.levyId;
        return '';
    }

    handleSubmit(event) {
        this.error = undefined;
        if(this.data.costOfWorks == 0 || this.data.levyPayable == 0) {
            this.error = 'Please update the correct Cost Of Works and Levy Payable on the record and reload the page';
        }
        else {
            const allValid = [...this.template.querySelectorAll('lightning-combobox, lightning-input, lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
            if (allValid) {
                if(event.detail.fields.LSC_Approver__c == Id) {
                    const evt = new ShowToastEvent({
                        title: 'Form Error',
                        message: 'You can\'t set yourself as approver',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                }
                else {
                    event.preventDefault();   
                    submitApproval({recordId : this.recordId, accountId : event.detail.fields.LSC_NewLevyAccount__c, userId: event.detail.fields.LSC_Approver__c, paid : this.paid, refunded : this.refunded, writeoff : this.writeoff, lga: event.detail.fields.LSC_CorrectedLGA__c})
                    .then(result => {
                        if(result.error) {
                            this.error = result.error;
                        }
                        else {
                            this.error = undefined;          
                            this.isSuccess = true;
                        }
                    })
                    .catch(error => {
                        this.error = error;
                    })
                }
            }
        }

    }
}