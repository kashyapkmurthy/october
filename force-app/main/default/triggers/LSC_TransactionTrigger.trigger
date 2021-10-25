trigger LSC_TransactionTrigger on LSC_Transaction__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    LSC_TriggerDispatcher.Run(new LSC_TransactionTriggerHandler());
}