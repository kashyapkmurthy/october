trigger LSC_AccountTrigger on Account(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    LSC_TriggerDispatcher.Run(new LSC_AccountTriggerHandler());
    
}