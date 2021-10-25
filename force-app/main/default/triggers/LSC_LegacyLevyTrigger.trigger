trigger LSC_LegacyLevyTrigger on LSC_LegacyLevy__c(after update) {
    LSC_TriggerDispatcher.Run(new LSC_LegacyLevyTriggerHandler());    
}