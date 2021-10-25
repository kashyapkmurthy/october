/**
 * 
 * 
 * 
 */
public class LSC_ProcessTransactionAfterUpdate {
    public LSC_ProcessTransactionAfterUpdate() {
    }

    /**
     * 
     *
     */
    public static void processTransactionAfterUpdate (Map<Id, SObject> newItems, Map<Id, SObject> oldItems){

        List<Id> updatedTransactionList = new List<Id>();  
        Map<Id, LSC_Transaction__c> newTransactionMap = (Map<Id, LSC_Transaction__c>)newItems;
        Map<Id, LSC_Transaction__c> oldTransactionMap = (Map<Id, LSC_Transaction__c>)oldItems;

        for (Id key : newTransactionMap.keySet()){
            LSC_Transaction__c newtransactionItem = newTransactionMap.get(key);
            LSC_Transaction__c oldtransactionItem = oldTransactionMap.get(key);

            if ((newtransactionItem.LSC_AccountSyncedWithSAP__c == true) && 
                ((newtransactionItem.LSC_SAPDocumentNo__c != NULL) && 
                (newtransactionItem.LSC_SyncedWithSAP__c == false))){
                updatedTransactionList.add(newtransactionItem.Id);    
            }
            //EFT Payment Transaction failed ? Update realted TLI's status.
            if ((newtransactionItem.LSC_PaymentMethod__c == LSC_GlobalConstants.LSC_CASE_REFUND_PAYMENT_METHOD) &&  
                    (oldtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PAID) &&   
                    (newtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_FAILED)){
                    updateRelatedTLIStatus(key);
                }
        } 



        System.debug('updatedTransactionList----->'+ updatedTransactionList);

        if (updatedTransactionList != null && updatedTransactionList.size() > 0){
            LSC_PublishTransactionToSAP.publishTransaction(updatedTransactionList, LSC_GlobalConstants.LSC_TRANSACTION_TYPE_UPDATE);
        }

    }

    @future
    public static void updateRelatedTLIStatus(id trnsactionID){
       //Get all related TLI's and update status to failed/Cancelled based on record type.
        List<LSC_TransactionLineItem__c> tliList = new List<LSC_TransactionLineItem__c>();
        for (LSC_TransactionLineItem__c tliRec : [SELECT Id,  LSC_Status__c, RecordType.Name FROM LSC_TransactionLineItem__c WHERE LSC_TransactionId__c = :trnsactionID AND LSC_Status__c =: LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_PAID ]){
            if (tliRec.RecordType.Name == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_PAYMENT){
                tliRec.LSC_Status__c =  LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_FAILED;
            }else if (tliRec.RecordType.Name == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_WRITE_OFF){
                tliRec.LSC_Status__c =  LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_CANCELLED;
            }   
            tliList.add(tliRec);
        }
        //update status.
        if (tliList.size() != 0){
            update tliList;
        }
    }
}