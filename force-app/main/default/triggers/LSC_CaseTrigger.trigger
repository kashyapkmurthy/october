trigger LSC_CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    LSC_TriggerDispatcher.Run(new LSC_CaseTriggerHandler());
}