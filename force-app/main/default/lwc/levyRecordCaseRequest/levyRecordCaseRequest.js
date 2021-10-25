import { LightningElement, wire, api, track } from 'lwc';
import deleteDocument from '@salesforce/apex/LSC_LevyRecordController.deleteDocument';
import createCase from '@salesforce/apex/LSC_LevyRecordController.createCase';
import getbankAndBranch from '@salesforce/apex/LSC_QueryUtils.getbankAndBranch';
import { NavigationMixin } from 'lightning/navigation';
import momentJs from '@salesforce/resourceUrl/momentjs_2_29_1';
import { loadStyle, loadScript} from 'lightning/platformResourceLoader';
import USER_ID from "@salesforce/user/Id";
// Import custom labels
import newCostOfWork from '@salesforce/label/c.NewCostofWorks';
import correctCostOfWork from '@salesforce/label/c.CorrectCostofWorks';
import { newErrorToast, handleError } from 'c/utils';

export default class LevyRecordCaseRequest extends NavigationMixin(LightningElement) {
    @api action;
    @api type;
    @api recordId;
    @api eftDetails;
    @api levy;
    @api ownerBuilderParameters; 

    label = {
        newCostOfWork,
        correctCostOfWork,
    };

    subject;
    category;
    details;
    submitDisabled = false;
    costAmount;
    voluntaryCostAmount;
    levyAmount;
    refundAmount;
    displayRefundFields;
    hasExemptionRefunds;
    showLicenseLookup;
    ownerBuilderDts;
    displayAdditionalFields;
    licenceNumber;
    validatedOwnerBuilderNum = false;
    emptyOwnerBuilderNum = false;
    @track buttonLabel = this.label.newCostOfWork;

    @track levyCostLabel = true;
    @track costOfWorkLabel = true;
    
    accountName;
    bankName;
    bsbCode;
    accountNumber;
    bankDetails;    
    @track uploadedFiles = [];

    renderedCallback(){
        Promise.all([loadScript(this,momentJs)]).then(() =>{
        }).catch(error => {
            this.error = error;
        });
    }

    get fileRecordId() {
        return USER_ID;
    }    
    
    get fileUploadLabel() {
        if(this.type === 'refund') {
            return '';
        }
        else {
            return 'Add attachments';
        }
    }

    get isEFTRefund() {
        return this.type === 'refund' && this.eftDetails      
    }

    get title() {
        if(this.type === 'refund') {
            return 'Refund Request'
        }
        else {
            return 'Support request'
        }
    }

    get categoryType() {
        if(this.type === 'refund') {
            return 'Reason for the refund'
        }
        else {
            return 'Support category'
        }        
    }

    get options() {
        if(this.type === 'refund') {
            return [
                { label: 'The construction work did not proceed', value: 'The construction work did not proceed' },
                { label: 'Overpayment of the levy', value: 'Overpayment of the levy' },
                { label: 'The levy was paid twice', value: 'The levy was paid twice' },
                { label: 'The value of work decreased', value: 'The value of work decreased' },
                { label: 'Requesting a non-profit partial exemption refund', value: 'Requesting a non-profit partial exemption refund' },
                { label: 'Requesting an owner builder partial exemption refund', value: 'Requesting an owner builder partial exemption refund' },                
                { label: 'The work is not leviable', value: 'The work is not leviable' }
            ];
        }
        else {
            return [
                { label: 'Amend my receipt', value: 'Amend my receipt' },
                { label: 'Assistance to make a new levy payment', value: 'Assistance to make a new levy payment' },
                { label: 'General enquiry', value: 'General enquiry' }
            ];
        }  
    }

    get isRendered() {
        if(this.recordId && this.action === 'support') return true;
        return false;
    }

    get isSupport() {
        return this.type !== 'refund';
    }

    get isRefund() {
        return this.type === 'refund';
    }

    get acceptedFormats() {
        return ['.pdf','.png','.jpg'];
    }

    get hasFiles() {
        return this.uploadedFiles.length > 0;
    }

    get paidDate() {
        if(this.levy && this.levy.datePaid) {
            let dt = new Date(this.levy.datePaid);
            return Intl.DateTimeFormat('en-AU').format(dt);
        }
        return '';
    }

     handleVoluntaryAmount(event){
        this.voluntaryCostAmount = event.target.value;
        var inputField = this.template.querySelector(".voluntary-cost"); 
        inputField.setCustomValidity('');        
        if(parseFloat(this.voluntaryCostAmount) <= 0) {
            inputField.setCustomValidity('Voluntary Labour Cost should be greater than 0');
            this.levyAmount = 0;
            this.refundAmount = 0;
            this.voluntaryCostAmount = this.voluntaryCostAmount;
            this.submitDisabled = true;           
        }
        else if(parseFloat(this.voluntaryCostAmount) > ((this.levy.totalCost) * 0.5)) {
            inputField.setCustomValidity('Voluntary Labour Cost should be capped at 50% of Total Cost');
            this.levyAmount = 0;
            this.refundAmount = 0;
            this.voluntaryCostAmount = this.voluntaryCostAmount;           
        } else if(parseFloat(this.voluntaryCostAmount) > 0){
            this.refundAmount = Math.ceil(parseFloat(this.voluntaryCostAmount) * 0.0035) - this.levy.exemptionAmount;            
            let paidAmount = this.levy.amountPaid - this.levy.writeOffAmount - this.levy.totalRefundAmount; 
            if(this.category === 'Requesting a non-profit partial exemption refund' && this.refundAmount > 0) {
                this.submitDisabled = false;
            }
            if(this.category === 'Requesting an owner builder partial exemption refund' && this.refundAmount > 0 && this.validatedOwnerBuilderNum) {
                this.submitDisabled = false;
            }
            if (this.refundAmount > paidAmount){
                this.refundAmount = paidAmount;    
            }
            if (this.refundAmount <= 0){
                this.refundAmount = 0;
                this.submitDisabled = true;
                inputField.setCustomValidity('Refund estimate is 0');
            }                          
        } else{
            this.refundAmount = 0;
        }
        inputField.reportValidity();
    }

    handleAmountChange(event){
        this.costAmount = event.target.value;
        var inputField = this.template.querySelector(".construction-cost"); 
        inputField.setCustomValidity('');
        if(parseFloat(this.costAmount) > this.levy.totalCost) {
            inputField.setCustomValidity('New total cost should be less than current cost');
            this.levyAmount = 0;
            this.refundAmount = 0;
        } 
        else if(this.category  === 'The work is not leviable') {
            if (parseFloat(this.costAmount) < 25000){
                this.levyAmount = 0;
                this.refundAmount = this.levy.amountPaid - this.levy.writeOffAmount - this.levy.totalRefundAmount; 
            }
            if (parseFloat(this.costAmount) >= 25000){
                inputField.setCustomValidity('Work not leviable should be less than 25000');
                this.levyAmount = 0;
                this.refundAmount = 0;  
            }                    
        }       
        else if(parseFloat(this.costAmount) == 0 || parseFloat(this.costAmount) > 24999) {
            inputField.setCustomValidity('');
            this.levyAmount = Math.floor(this.costAmount * 0.0035); 
            this.refundAmount = this.levy.amountPaid - this.levyAmount - this.levy.writeOffAmount - this.levy.totalRefundAmount;
            if (this.refundAmount <= 0){
                this.refundAmount = 0;
                inputField.setCustomValidity('Refund estimate is 0');
            }         
        }        
        else if((parseFloat(this.costAmount) > 0 || parseFloat(this.costAmount) < 25000) && this.category  !== 'The work is not leviable') {
            inputField.setCustomValidity('New total cost should be greater than or equal to 25000');
            this.levyAmount = 0;
            this.refundAmount = 0;         
        }
        else {
            this.levyAmount = 0;
            this.refundAmount = 0;          
        }

        inputField.reportValidity();        
        
    }

    handleChildEvent (event){
        this.ownerBuilderDts = event.detail.ownerBuilderDetails;
        this.licenceNumber = this.ownerBuilderDts.licenceNumber;
        this.validatedOwnerBuilderNum = event.detail.showAdditionalInputs;
        if (this.refundAmount > 0 && this.validatedOwnerBuilderNum){
            this.submitDisabled = false;
        }
        this.displayAdditionalFields = event.detail.showAdditionalInputs;        
    }

    handleEmptyOwnerTextBox (event){
        this.emptyOwnerBuilderNum =  event.detail;  
        if (this.emptyOwnerBuilderNum){
            this.submitDisabled = true;
        }        
    }

    handleUploadFinished(event) {
        const lstUploadedFiles = event.detail.files;
        lstUploadedFiles.forEach(fileIterator => this.uploadedFiles.push({name:fileIterator.name, id:fileIterator.documentId}));
    }

    handleFileDelete(event) {
        var scope = this;
        var doc = event.target.name;
        deleteDocument({docId: doc})
        .then(result => {
            scope.uploadedFiles = scope.uploadedFiles.filter(function (e) {
                return e.id !== doc
            });
        })
        .catch(error =>{
        })   
    }

    handleClose(){
        this.dispatchEvent(new CustomEvent("close"));
    }
    
    handleRefundDropDownChange(event){
        this[event.target.name] = event.target.value;
          
        if (this.type === 'refund'){            
            this.refundAmount = 0;   
            this.costAmount = 0;   
            this.levyAmount = 0;
            this.buttonLabel = this.label.newCostOfWork;
            this.levyCostLabel = true;
            this.costOfWorkLabel = true;            
            this.displayRefundFields = true;
            this.showLicenseLookup = false;
            this.hasExemptionRefunds = false;
            this.submitDisabled = false;
            if(this.category === 'The levy was paid twice') {
                this.refundAmount = this.levy.amountPaid - this.levy.writeOffAmount - this.levy.totalRefundAmount;               
                this.buttonLabel = this.label.correctCostOfWork;
            } else if(this.category  === 'The construction work did not proceed'){               
                this.refundAmount = this.levy.amountPaid - this.levy.writeOffAmount - this.levy.totalRefundAmount; 
                this.levyCostLabel = false;
                this.costOfWorkLabel = false;
            } else if(this.category  === 'Requesting a non-profit partial exemption refund'){               
                this.refundAmount = 0; 
                this.levyCostLabel = false;
                this.costOfWorkLabel = false;
                this.displayRefundFields = true;
                this.hasExemptionRefunds = true;
                this.refundAmount = 0;
            } else if(this.category  === 'Requesting an owner builder partial exemption refund'){               
                this.refundAmount = 0; 
                this.levyCostLabel = false;
                this.costOfWorkLabel = false;
                this.displayRefundFields = true;
                this.showLicenseLookup = true;
                this.hasExemptionRefunds = true;
                this.submitDisabled = true;
                this.refundAmount = 0;
            }  else if(this.category === 'The work is not leviable'){
                this.refundAmount = this.levy.amountPaid - this.levy.writeOffAmount - this.levy.totalRefundAmount; 
                this.costAmount = 0;
            } else {
                this.refundAmount = this.levy.amountPaid - this.levy.writeOffAmount - this.levy.totalRefundAmount; 
            }
        }
    }

    handleChange(event){
        this[event.target.name] = event.target.value;
    }    
    
    handleBSBChange(event){
        this[event.target.name] = event.target.value;
        this.bankDetails = null;
        if(this.bsbCode.length == 6) {
            getbankAndBranch({bsbCode: this.bsbCode})
            .then(result => {
                if(result) {
                    this.bankDetails = result;
                }
            })
            .catch(error =>{
            })               
        }
    }        

    openCase(event) {
        const allValid = [...this.template.querySelectorAll('lightning-combobox, lightning-input, lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
        if (allValid) {      
            this.submitDisabled = true;  
            var documents = this.uploadedFiles.map(function(el) { return el.id });
            
            
            createCase({id: this.recordId, type: this.type, category: this.category, subject: this.subject, details: this.details, bsb: this.bsbCode, accountNumber: this.accountNumber, accountName: this.accountName, bankName: this.bankName, costOfWork : this.costAmount,  refundAmount : this.refundAmount, voluntaryLaborCost : this.voluntaryCostAmount, jsonData : JSON.stringify(this.ownerBuilderDts), docIds: documents})
            .then(result => {
                if(result && result.id) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result.id,
                            objectApiName: 'Case',
                            actionName: 'view'
                        }
                    });
                } 
                else if(result && result.error) {
                    this.submitDisabled = false;
                    throw new Error(result.error);
                    // topu-amount class not exist in the html
                    // let topupField = this.template.querySelector(".topup-amount"); 
                    // topupField.setCustomValidity(result.error);
                    // topupField.reportValidity();                  
                }
            })
            .catch(error =>{
                this.submitDisabled = false;
                const errorMessage = handleError(error);
                this.dispatchEvent(newErrorToast({ message: errorMessage }));
            })    
        }   
    }
}