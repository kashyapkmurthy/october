public with sharing class LSC_TransactionTriggerHandler implements LSC_TriggerHandler {
    public static Boolean triggerDisabled = false;
    public LSC_TransactionTriggerHandler() {

    }

    public Boolean isDisabled() {
        //Done the changes for Spring 21 changes.
        LSC_TriggerSettings__mdt triggerDetailMdt = LSC_TriggerSettings__mdt.getInstance('LSC_TransactionTriggerHandler');
        if (triggerDetailMdt != null && triggerDetailMdt.LSC_TriggerDisabled__c) {
            return true;
        }
        return triggerDisabled;
    }
 
    public void BeforeInsert(List<SObject> newItems) {
        LSC_ProcessTransactionBeforeInsert.processTransactionBeforeInsert(newItems);
    }
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        LSC_ProcessTransactionBeforeUpdate.processTransactionBeforeUpdate(newItems, oldItems);
    
    }
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {
    }
 
    public void AfterInsert(Map<Id, SObject> newItems) {
        LSC_ProcessTransactionAfterInsert.processTransactionAfterInsert(newItems);
    }
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        LSC_ProcessTransactionAfterUpdate.processTransactionAfterUpdate(newItems, oldItems);
        
    }
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
}