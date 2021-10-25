import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getLevies from '@salesforce/apex/LSC_LevyListController.getLevies';
import getEFT from '@salesforce/apex/LSC_LevyRecordController.getEFT';
import LEVY_OBJECT from '@salesforce/schema/LSC_Levy__c';
import { NavigationMixin } from 'lightning/navigation';
import formFactorPropertyName from '@salesforce/client/formFactor';
import BCICommunityLink from '@salesforce/label/c.BCI_Community_Link';

export default class LightningDatatableExample extends NavigationMixin(LightningElement) {
    value;
    error;
    data;
    sortedDirection = 'desc';
    sortedBy = 'refNo';
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
    transactionAmountDue = 0;
    transactionId;
    bsb = '';
    accNo = '';
    isEFTModal = false;
    eftAllowed = false;

    columns = [
        {
            label: 'Ref. No.',
            fieldName: 'url',
            type: 'url',
            typeAttributes: {label: { fieldName: 'refNo' }, 
            target: '_blank'},
            sortable: true

        },
        {
            label: 'Approval Number',
            fieldName: 'daNo',
            sortable: true
        },
        {
            label: 'Site Address',
            fieldName: 'address',
            sortable: false,
            wrapText: true    
        },
        {
            label: 'Status',
            fieldName: 'status',
            sortable: true
        },
        { type: 'action', typeAttributes: { rowActions: this.getRowActions } },
    ]

    connectedCallback() {
        //Force refresh apex on load
        this.refresh();
    }

    refresh() {
        setTimeout(() => {
            refreshApex(this.result); 
        }, 0);
    }
    
    get hasData() {
        if(this.data.length > 0) return true;
        return false;
    }       

    getRowActions(row, doneCallback) {
        if(row.status === 'Ready to be paid' && row.isPayable && row.isInterestPayable) {
            doneCallback([{ label: 'Pay Levy', name: 'pay' },  { label: 'Pay Interest', name: 'payInterest' },  { label: 'Request support', name: 'support' }]);
        }
        else if(row.status === 'Ready to be paid' && row.isPayable) {
            doneCallback([{ label: 'Pay now', name: 'pay' }, { label: 'Request support', name: 'support' }]);
        }
        else if(row.status === 'Ready to be paid'  && row.isInterestPayable) {
            doneCallback([{ label: 'Pay Interest', name: 'payInterest' }, { label: 'Request support', name: 'support' }]);
        }  
        else if(row.status === 'Ready to be paid') {
            doneCallback([{ label: 'Request support', name: 'support' }]);
        }        
        else if(row.status === 'Awaiting Exemption Decision') {
            doneCallback([{ label: 'Request support', name: 'support' }]);
        }
        else if(row.status === 'Awaiting Instalments Decision') {
            doneCallback([{ label: 'Request support', name: 'support' }]);
        }
        else if(row.status === 'Paid') {
            let buttons = [{ label: 'Request support', name: 'support' }];
            if(!row.hasInstalments) {
                buttons.push({ label: 'Print receipt', name: 'receipt' });
            }
            if(row.canTopup) {
                buttons.push({ label: 'Top Up', name: 'topup' });
            }
            if(row.canRefund) {
                buttons.push({ label: 'Request refund', name: 'refund' });
            }   
            doneCallback(buttons);         
        }
        else if(row.status === 'Cancelled') {
            doneCallback([{ label: 'Request support', name: 'support' }]);
        }                                
    } 
    
    @wire(getEFT, {label : 'BCI'})
    eftDetails({ error, data }) {
        if (data) {
            this.bsb = data.bsb;
            this.accNo = data.accountNumber;
            this.eftAllowed = data.eftAllowed;
        } else if (error) {
            this.error = error;
        }
    } 

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        switch (actionName) {
            case 'receipt':
                if (formFactorPropertyName === 'Large') {
                    this[NavigationMixin.Navigate]({
                        type: 'comm__namedPage',
                        attributes: {
                            pageName: 'levy-receipt'
                        },
                        state: {
                            recordId: event.detail.row.transactionId
                        }
                    }); 
                } else {
                    let url = BCICommunityLink + "/apex/LevyReceipt?id=" + event.detail.row.transactionId;
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: url
                        }
                    },
                    false
                  );
                } 
                break;
            case 'topup':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: event.detail.row.id,
                        objectApiName: LEVY_OBJECT.objectApiName,
                        actionName: 'view'
                    },
                    state: {
                        action: 'topup'
                    }
                });
                break;
            case 'support':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: event.detail.row.id,
                        objectApiName: LEVY_OBJECT.objectApiName,
                        actionName: 'view'
                    },
                    state: {
                        action: 'support'
                    }
                }); 
                break;
            case 'refund':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: event.detail.row.id,
                        objectApiName: LEVY_OBJECT.objectApiName,
                        actionName: 'view'
                    },
                    state: {
                        action: 'support',
                        type: 'refund'
                    }
                });
                break;
            case 'pay':
                if(!this.eftAllowed) {
                    this[NavigationMixin.Navigate]({
                        type: 'comm__namedPage',
                        attributes: {
                            pageName: 'payment'
                        },
                        state: {
                            transactionId: event.detail.row.transactionId
                        }
                    });
                }
                else {
                    this.transactionId = event.detail.row.transactionId;
                    this.transactionAmountDue = event.detail.row.transactionAmountDue;
                    this.isEFTModal = true;
                }                  
                break;
            case 'payInterest':
                if(!this.eftAllowed) {
                    this[NavigationMixin.Navigate]({
                        type: 'comm__namedPage',
                        attributes: {
                            pageName: 'payment'
                        },
                        state: {
                            transactionId: event.detail.row.interestId
                        }
                    });  
                }
                else {
                    this.transactionId = event.detail.row.interestId;
                    this.transactionAmountDue = event.detail.row.transactionAmountDue;
                    this.isEFTModal = true;
                }                  
                break;
            default:
        }
    }    
  
    @wire(getLevies, {searchKey: '$searchKey', sortBy: '$sortedBy', sortDirection: '$sortedDirection'})
    wiredLevies(result) {
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

    //clicking on previous button this method will be called
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

    //clicking on next button this method will be called
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

    //this method displays records page by page
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

    get canPayCPP() {
        console.log('levy payable:::'+this.transactionAmountDue);
        if(this.transactionAmountDue > 1000000) return false;
        return true;
    }
    payCPP() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'payment'
            },
            state: {
                transactionId: this.transactionId
            }
        });        
    }
    // Note: Handle Click for Close Button
     handleClickClose(){
        this.isEFTModal= false;
    }
    
    closeModal() {
        this.isEFTModal = false;
    }

}