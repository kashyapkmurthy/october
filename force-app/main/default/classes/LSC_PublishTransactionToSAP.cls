public with sharing class LSC_PublishTransactionToSAP {
    public LSC_PublishTransactionToSAP() {

    }

    
    private static List <LSC_Transaction__c> getAllRelatedTransactionDeatils (List<Id> transactionIdList){

        String query ='';
        String sobjectApiName = 'LSC_Transaction__c';
        String strFields = LSC_QueryUtils.getFieldNameForAnObject('LSC_Transaction__c');       
        String referenceFields = ', RecordType.Name, LSC_LevyId__r.LSC_AccountId__c, LSC_LevyId__r.RecordType.Name, LSC_LevyId__r.Name, LSC_LevyId__r.LSC_LevySource__c, LSC_CaseId__r.LSC_TransactionLineItemId__r.LSC_TransactionId__c ';

        query = 'select ' + strFields + referenceFields+ ' from ' + SobjectApiName + ' where Id IN:transactionIdList';
       
        List <LSC_Transaction__c> transactionList = Database.query(query);

        System.debug('Transaction value--->'+transactionList);

        for (LSC_Transaction__c transactionItem : transactionList){
            System.debug('Account Name--->'+transactionItem.Name);
            System.debug('Account Name--->'+transactionItem.LSC_LevyId__r.RecordType.Name);    
        }
        return transactionList;
    }

    private static void setAndPublishTransactionToPlatformEventObj (List <LSC_Transaction__c> transactionList, String transactionType){
        
        List<LSC_NewTransaction__e > events = new List<LSC_NewTransaction__e >();
        for(LSC_Transaction__c transactionIter : transactionList) {
            LSC_NewTransaction__e  transactionPlatformEvent = new LSC_NewTransaction__e ();
            transactionPlatformEvent.LSC_AccountId__c         = transactionIter.LSC_LevyId__r.LSC_AccountId__c;
            transactionPlatformEvent.LSC_AccountName__c       = transactionIter.LSC_AccountName__c;
            transactionPlatformEvent.LSC_AccountNo__c         = transactionIter.LSC_AccountNo__c;
            transactionPlatformEvent.LSC_Amount__c            = transactionIter.LSC_Amount__c;
            transactionPlatformEvent.LSC_BSB__c               = transactionIter.LSC_BSB__c;
            transactionPlatformEvent.LSC_Comments__c          = transactionIter.LSC_Comments__c;
            transactionPlatformEvent.LSC_CreatedDate__c       = transactionIter.CreatedDate;
            transactionPlatformEvent.LSC_DueDate__c           = transactionIter.LSC_DueDate__c;
            transactionPlatformEvent.LSC_Source__c            = transactionIter.LSC_TransactionSource__c;
            transactionPlatformEvent.LSC_EventType__c         = transactionType;
            transactionPlatformEvent.LSC_LevyId__c            = transactionIter.LSC_LevyId__c;
            transactionPlatformEvent.LSC_LevyScheme__c        = transactionIter.LSC_LevyId__r.RecordType.Name;
            transactionPlatformEvent.LSC_LevyTransactionId__c = transactionIter.LSC_LevyTransactionId__c;
            transactionPlatformEvent.LSC_PaymentMethod__c     = transactionIter.LSC_PaymentMethod__c;
            transactionPlatformEvent.LSC_PaymentReference__c  = transactionIter.LSC_PaymentReference__c;           
            transactionPlatformEvent.LSC_Status__c            = transactionIter.LSC_Status__c;
            transactionPlatformEvent.LSC_TransactionId__c     = transactionIter.Id;
            transactionPlatformEvent.LSC_TransactionType__c   = transactionIter.RecordType.Name;
            transactionPlatformEvent.LSC_RelatedSAPDocumentNo__c = transactionIter.LSC_SAPDocumentNo__c;
            transactionPlatformEvent.LSC_BankCode__c          = transactionIter.LSC_BankCode__c;
            transactionPlatformEvent.LSC_BranchName__c        = transactionIter.LSC_BranchName__c;
            transactionPlatformEvent.LSC_RefundedTransactionId__c = transactionIter.LSC_CaseId__r.LSC_TransactionLineItemId__r.LSC_TransactionId__c;

            events.add(transactionPlatformEvent);            
        }
        

        if(events.size() > 0) {
            System.debug('Transaction events value--->'+events);
            EventBus.publish(events);
        }
    }



    @future
    public static void publishTransaction (List<Id> transactionIdList, String transactionType){
        List <LSC_Transaction__c> transactionList = getAllRelatedTransactionDeatils(transactionIdList);
        setAndPublishTransactionToPlatformEventObj(transactionList, transactionType);
    }

}