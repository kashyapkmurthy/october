import { LightningElement, api, wire, track } from 'lwc';
import getCaseAndTransactionList from '@salesforce/apex/LSC_BCIHomePageController.getCaseAndTransactionList';
import getAllColumns from '@salesforce/apex/LSC_BCIHomePageController.getColumns';
import formFactorPropertyName from '@salesforce/client/formFactor';

export default class BciPendingActions extends LightningElement {
    @api renderAsShared = false;
    @track columns;
    caseNTransactionData = [];
    items = [];
    error;
    page = 1;
    totalPage = 0;
    pageSize;
    startingRecord = 1;
    endingRecord = 0; 
    totalRecountCount = 0;

    @wire(getAllColumns, {renderShared : '$renderAsShared'})
    columns({data,error}) {
        if(data) {
            console.log('I should be firest');
            this.columns = data; 
            console.log(this.columns);
        }
        if(error) {
            this.error = error;
            console.log(error);
        }
    }

    @wire(getCaseAndTransactionList)
    casesAndTransactions({data,error}) {
        if(data) {
            this.items = data;
            this.totalRecountCount = data.length; 
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize); 
            this.caseNTransactionData = this.items.slice(0,this.pageSize); 
            this.endingRecord = this.pageSize;
        }
        if(error) {
            this.error = error;
        }
    }

    connectedCallback() {
        this.pageSize = this.renderAsShared ? 4 : 8;
    }

    get mobileView() {
        return formFactorPropertyName !== 'Large';
    }

    actionColumns = [
        {
            label: 'Id',
            fieldName: 'url',
            type: 'url',
            typeAttributes: {label: { fieldName: 'link' }, 
            target: '_blank'},
            fixedWidth: this.widhtVal,
            sortable: false
        },
        {
            label: 'Date',
            fieldName: 'dueDate',
            sortable: false,
            type: "date" ,
            fixedWidth: this.widhtVal        
        },
        {
            label: 'Action',
            fieldName: 'action',
            type: "text",
            sortable: false,
            wrapText: true,
            fixedWidth: this.widhtVal          
        }
    ] 

    get hasCaseNTransactionData() {
        return (this.caseNTransactionData.length > 0) ? true : false;
    } 

    get noRecordstoShow() {
        return (this.caseNTransactionData && this.caseNTransactionData.length == 0) ? true : false;
    } 

    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1; 
            this.displayRecordPerPage(this.page);
        }
    }

    nextHandler() {
        if((this.page < this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1; 
            this.displayRecordPerPage(this.page);            
        }             
    }

    displayRecordPerPage(page){
        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);
        this.endingRecord = (this.endingRecord > this.totalRecountCount) 
                            ? this.totalRecountCount : this.endingRecord; 
        this.caseNTransactionData = this.items.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;
    }   


    get multiplePages(){
        return (!this.renderAsShared && this.totalPage > 1)? true : false;
    }

    get isPrev(){
        return (this.page == 1)? true : false;
    }

    get isNext(){
        return (this.page == this.totalPage)? true : false;
    }
}