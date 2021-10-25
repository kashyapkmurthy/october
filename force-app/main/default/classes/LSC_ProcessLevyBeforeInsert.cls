public with sharing class LSC_ProcessLevyBeforeInsert {
    public static void processLevyBeforeInsert (List<SObject> newItems) {
        List<LSC_Levy__c> levyItems = (List<LSC_Levy__c>)newItems;
        for(LSC_Levy__c newLevy : levyItems){  
            if(UserInfo.getUserType() == 'Standard' && newLevy.LSC_CostOfWorks__c != null && newLevy.LSC_LevySource__c != 'Legacy' && newLevy.LSC_LevyPayable__c == null){
                if(newLevy.LSC_CostOfWorks__c >= 25000){
                    newLevy.LSC_LevyPayable__c = Math.floor(newLevy.LSC_CostOfWorks__c * 0.0035);
                }else{
                    newLevy.LSC_LevyPayable__c = 0;
                }
            }

            // Panaya-466 replace dash with hypern
            if (!String.isBlank(newLevy.LSC_ApplicationNumber__c)) {
                newLevy.LSC_ApplicationNumber__c = LSC_Utility.replaceDashWithHypen(newLevy.LSC_ApplicationNumber__c);
            }
        }
    }
}