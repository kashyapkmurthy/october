/**
 * 
 * 
 * 
 * 
 */
public with sharing class LSC_ProcessTransactionAfterInsert {
    public LSC_ProcessTransactionAfterInsert() {

    }

    /**
     * 
     * 
     * 
     * 
     */
    public static void processTransactionAfterInsert (Map<Id, SObject> newItems){
        
        List<Id> transactionList   = new List<Id>();

        Map<Id, LSC_Transaction__c> transactionMap = (Map<Id, LSC_Transaction__c>)newItems;

        for (Id key : transactionMap.keySet()){
            LSC_Transaction__c transactionItem = transactionMap.get(key);

            if ((transactionItem.LSC_AccountSyncedWithSAP__c == true) && 
                ((transactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING || transactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PAID) && 
                (transactionItem.LSC_SAPDocumentNo__c == NULL) && 
                (transactionItem.LSC_SyncedWithSAP__c == false))){
                    transactionList.add(transactionItem.Id);    
            }
        }

        if (transactionList != null && transactionList.size() > 0){
            LSC_PublishTransactionToSAP.publishTransaction(transactionList, LSC_GlobalConstants.LSC_TRANSACTION_TYPE_CREATE);
        }
    }
}