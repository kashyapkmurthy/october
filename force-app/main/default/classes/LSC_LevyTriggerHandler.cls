public class LSC_LevyTriggerHandler implements LSC_TriggerHandler {
    public static Boolean triggerDisabled = false;

    public void LSC_LevyTriggerHandler (){

    }
 
    public Boolean isDisabled() {
        //Done the changes for Spring 21 changes.
        LSC_TriggerSettings__mdt triggerDetailMdt = LSC_TriggerSettings__mdt.getInstance('LSC_LevyTriggerHandler');
        if (triggerDetailMdt != null && triggerDetailMdt.LSC_TriggerDisabled__c) {
            return true;
        }
        return triggerDisabled;
    }
 
    public void BeforeInsert(List<SObject> newItems) {
        LSC_ProcessLevyBeforeInsert.processLevyBeforeInsert(newItems);
    }
        
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        LSC_ProcessLevyBeforeUpdate.processLevyBeforeUpdate(newItems, oldItems);
    }
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterInsert(Map<Id, SObject> newItems) {}
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
}