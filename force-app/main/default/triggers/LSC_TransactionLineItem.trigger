trigger LSC_TransactionLineItem on LSC_TransactionLineItem__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    LSC_TriggerDispatcher.Run(new LSC_TransactionLineItemTriggerHandler());
}