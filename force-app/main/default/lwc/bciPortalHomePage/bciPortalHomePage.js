import { LightningElement, wire } from 'lwc';
import USER_ID from "@salesforce/user/Id";
import NAME_FIELD from '@salesforce/schema/User.FirstName';
import {getRecord} from 'lightning/uiRecordApi';
import getCaseList from '@salesforce/apex/LSC_BCIHomePageController.getCaseList';
import { NavigationMixin} from 'lightning/navigation';
import formFactorPropertyName from '@salesforce/client/formFactor';

export default class PortalHomePage extends NavigationMixin(LightningElement) {
    firstName;
    caseData = [];
    items = [];
    error;
    page = 1;
    totalPage = 0;
    pageSize = 4;
    startingRecord = 1;
    endingRecord = 0; 
    totalRecountCount = 0;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error ; 
        } else if (data) {
            this.firstName = data.fields.FirstName.value;
        }
    }

    @wire(getCaseList)
    cases({data,error}) {
        if(data) {
            this.items = data;
            this.totalRecountCount = data.length; 
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize); 
            this.caseData = this.items.slice(0,this.pageSize); 
            this.endingRecord = this.pageSize;
        }
        if(error) {
            this.error = error;
        }
    }

    get hasCaseData() {
        return (this.caseData.length > 0) ? true : false;
    }  

    get noRecordstoShow() {
        return (this.caseData && this.caseData.length == 0) ? true : false;
    } 

    ticketColumns = [
        {
            label: 'Ticket No.',
            fieldName: 'url',
            type: 'url',
            typeAttributes: {label: { fieldName: 'link' }, 
            target: '_blank'},
            initialWidth: 130,
            sortable: false
        },
        {
            label: 'Date',
            fieldName: 'created',
            sortable: false,
            initialWidth: 100,
            type: "date",
            wrapText : true           
        },
        {
            label: 'Subject',
            fieldName: 'subject',
            type: "text",
            sortable: false,
            initialWidth: 140,
            wrapText: true         
        },        
        {
            label: 'Status',
            fieldName: 'status',
            sortable: false,
            cellAttributes: { class: {fieldName : 'styleClass'}},
            wrapText : true
        }
    ]

    connectedCallback() {
    }

    get mobileView() {
        return formFactorPropertyName !== 'Large';
    }

    get layoutSize(){
        return this.mobileView == true ? 12 : 6;
    }
    
    handleClick(event){
        switch(event.target.name){
            case "payNewLevy":
                this[NavigationMixin.GenerateUrl]({
                    type: 'comm__namedPage',
                    attributes: {
                      pageName: 'new-levy'
                    },
                }).then(url => {
                    window.open(url, "_blank");
                });
                break;
            case "newTicket":
                this[NavigationMixin.GenerateUrl]({
                    type: 'comm__namedPage',
                    attributes: {
                      pageName: 'contactsupport'
                    },
                }).then(url => {
                    window.open(url, "_blank");
                });
                break;
        }
    }
}