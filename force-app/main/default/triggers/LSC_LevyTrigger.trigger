trigger LSC_LevyTrigger on LSC_Levy__c(before update) {
    LSC_TriggerDispatcher.Run(new LSC_LevyTriggerHandler());    
}