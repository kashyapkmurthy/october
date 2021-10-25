public class LSC_CaseTriggerHandler implements LSC_TriggerHandler {
    public LSC_CaseTriggerHandler() {

    }
    public static Boolean triggerDisabled = false;

    public void LSC_AccountTriggerHandler (){

    }
 
    public Boolean isDisabled() {
        //Done the changes for Spring 21 changes.
        LSC_TriggerSettings__mdt triggerDetailMdt = LSC_TriggerSettings__mdt.getInstance('LSC_CaseTriggerHandler');
        if (triggerDetailMdt != null && triggerDetailMdt.LSC_TriggerDisabled__c) {
            return true;
        }
        return triggerDisabled;
    }
 
    public void BeforeInsert(List<SObject> newItems) {}
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        LSC_ProcesCaseBeforeUpdate.processBeforeUpdate((Map<Id, Case>)newItems, (Map<Id, Case>)oldItems);
        LSC_CaseSLAsUtility.manageSLAs((Map<Id, Case>)newItems, (Map<Id, Case>)oldItems);
    }
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterInsert(Map<Id, SObject> newItems) {
    }
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        LSC_ProcesCaseAfterUpdate.processCaseAfterUpdate(oldItems, newItems);
    }
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}

}