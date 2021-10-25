import { LightningElement, api, wire } from 'lwc';
import getData from '@salesforce/apex/LSC_CaseSLAsUtility.getData';

export default class CaseSLA extends LightningElement {
    @api recordId;
    totalTime;
    totalTimeP;       
    totalTimeType;
    timeInQueue;
    timeInQueueP;       
    timeInQueueType;
    processingTime;
    processingTimeType;
    processingTimeP;   
    onHoldTime;
    onHoldTimeType;
    onHoldTimeP;       
    approvalTime;
    approvalType;    
    approvalTimeP;    
    status;

    get showTotal() {
        return this.status;
    }

    get showQueue() {
        return this.timeInQueue >= 0;
    }

    get showProcessing() {
        return this.processingTime >= 0;
    }    

    get showOnHold() {
        return this.onHoldTime >= 0;
    }   
    
    get showApproval() {
        return this.approvalTime >= 0;
    }         

    @wire(getData, {recordId: '$recordId'})
    wiredData(result) {
        this.result = result;
        if(result.data) {
            console.log(result.data);
            this.status = result.data.status;
            this.totalTime = result.data.totalTime;
            this.totalTimeP = result.data.totalTimeP;       
            this.totalTimeType = result.data.totalTimeType;
            this.timeInQueue = result.data.timeInQueue;
            this.timeInQueueP = result.data.timeInQueueP;       
            this.timeInQueueType = result.data.timeInQueueType;
            this.processingTime = result.data.processingTime;
            this.processingTimeType = result.data.processingTimeType;
            this.processingTimeP = result.data.processingTimeP;   
            this.onHoldTime = result.data.onHoldTime;
            this.onHoldTimeType = result.data.onHoldTimeType;
            this.onHoldTimeP = result.data.onHoldTimeP;       
            this.approvalTime = result.data.approvalTime;
            this.approvalType = result.data.approvalType;    
            this.approvalTimeP = result.data.approvalTimeP;    
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.data = [];
        }
    }
}