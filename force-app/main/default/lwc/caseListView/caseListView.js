import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getCases from '@salesforce/apex/LSC_CaseListController.getCases';
import { NavigationMixin } from 'lightning/navigation';
import formFactorPropertyName from '@salesforce/client/formFactor';

export default class CaseListView extends NavigationMixin(LightningElement) {
    value;
    error;
    data;
    sortedDirection = 'desc';
    sortedBy = 'ticketNo';
    searchKey = '';
    result;
    
    isPrev = true;
    isNext = true;

    page = 1; 
    items = []; 
    data = []; 
    columns; 
    startingRecord = 1;
    endingRecord = 0; 
    pageSize = 8; 
    totalRecountCount = 0;
    totalPage = 0;
    multiplePages = false;

    get containerPadding() {
        return formFactorPropertyName !== 'Large' ? 'slds-p-left_x-small' : '';
    }
    
    columns = [
        {
            label: 'Ticket No.',
            fieldName: 'url',
            type: 'url',
            typeAttributes: {label: { fieldName: 'ticketNo' }, 
            target: '_blank'},
            sortable: true
        },
        {
            label: 'Subject',
            fieldName: 'subject',
            sortable: false,
            wrapText: true
        },
        {
            label: 'Created',
            fieldName: 'created',
            sortable: true,
            type: "date",
            typeAttributes:{
                month: "2-digit",
                day: "2-digit",
                year: "numeric"
            }                 
        },
        {
            label: 'Updated',
            fieldName: 'updated',
            sortable: true,
            type: "date",
            typeAttributes:{
                month: "2-digit",
                day: "2-digit",
                year: "numeric"
            }                 
        },        
        {
            label: 'Status',
            fieldName: 'status',
            sortable: true
        }
    ]

    connectedCallback() {
        //Force refresh apex on load
        this.refresh();
    }
    
    get hasData() {
        if(this.data.length > 0) return true;
        return false;
    }         

    newCase() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'contactsupport'
            }
        });
    }  
    
    refresh() {
        setTimeout(() => {
            refreshApex(this.result); 
        }, 0);
    }
  
    @wire(getCases, {searchKey: '$searchKey', sortBy: '$sortedBy', sortDirection: '$sortedDirection'})
    wiredCases(result) {
        this.result = result;
        if(result.data) {
            this.items = result.data;
            this.totalRecountCount = result.data.length; 
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize); 
            if(this.totalPage > 1) {
                this.multiplePages = true;
                this.isNext = false;
            }
            else {
                this.multiplePages = false;
            }
            this.data = this.items.slice(0,this.pageSize); 
            this.endingRecord = this.pageSize;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.data = [];
        }
    }

    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1;
            this.isNext = false;
            this.displayRecordPerPage(this.page);
        }
        if(this.page == 1) {
            this.isPrev = true;
        }
        else {
            this.isPrev = false;
        }
    }

    nextHandler() {
        if((this.page<this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1; 
            this.isPrev = false;
            this.displayRecordPerPage(this.page);            
        }      
        if(this.page == this.totalPage) {
            this.isNext = true;
        }       
        else {
            this.isNext = false;
        }
    }

    displayRecordPerPage(page){

        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);

        this.endingRecord = (this.endingRecord > this.totalRecountCount) 
                            ? this.totalRecountCount : this.endingRecord; 

        this.data = this.items.slice(this.startingRecord, this.endingRecord);

        this.startingRecord = this.startingRecord + 1;
    }    
    
    sortColumns( event ) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        return refreshApex(this.result);
        
    }
  
    handleKeyChange( event ) {
        this.searchKey = event.target.value;
        return refreshApex(this.result);
    }

}