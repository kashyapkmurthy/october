import { LightningElement, wire, api } from 'lwc';
import getCase from '@salesforce/apex/LSC_CaseRecordController.getCase';
import { NavigationMixin } from 'lightning/navigation';

export default class CaseRecord extends NavigationMixin(LightningElement) {
    @api recordId;
    ticket;
    hasAccess = true;
    hasAction = false;
    loading = true;

    printApproval() {
        if(this.ticket.actionType == 'Instalment') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Instalments_Approval__c'
                },
                state: {
                    recordId: this.recordId
                }
            });            
        }
        else if(this.ticket.actionType == 'Fire') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Bushfire_Exemption__c'
                },
                state: {
                    recordId: this.recordId
                }
            });
        }
        else if(this.ticket.actionType == 'NFP') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Non_Profit_Exemption__c'
                },
                state: {
                    recordId: this.recordId
                }
            });
        }
        else if(this.ticket.actionType == 'OB') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Owner_Builder_Exemption__c'
                },
                state: {
                    recordId: this.recordId
                }
            });
        }                
    }

    newComment() {
        this.template.querySelector('c-case-record-details').forceRefresh();
    }

    @wire(getCase, {recordId: '$recordId'})
    wiredCase({ error, data }) {
        if(data) {
            console.log(data);
            this.loading = false;
            this.ticket = data;
            this.hasAccess = data.hasAccess;
            this.hasAction = data.hasAction;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.ticket = undefined;
        }
    }

    get levyUrl(){
        return '/bci/s/levy/' + this.ticket.levyId;
    }

}