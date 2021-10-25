public with sharing class LSC_ProcessTransactionBeforeInsert {
    public static void processTransactionBeforeInsert (List<SObject> newItems) {
        if(UserInfo.getUserType() == 'Standard') {
            Id topupRecordTypeId = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_TOPUP).getRecordTypeId();        
            List<LSC_Transaction__c> newTransactions = (List<LSC_Transaction__c>)newItems;
            List<Id> topupLevyIds = new List<Id>();
            List<LSC_Transaction__c> topups = new List<LSC_Transaction__c>();
            for(LSC_Transaction__c t : newTransactions) {
                if(t.RecordTypeId == topupRecordTypeId && t.LSC_LevyId__c != null) {
                    topupLevyIds.add(t.LSC_LevyId__c);
                    topups.add(t);
                }
            }
            if(topupLevyIds.size() > 0) {
                Set<Id> levyIds = (new Map<Id, LSC_Levy__c>([SELECT Id FROM LSC_Levy__c WHERE Id IN :topupLevyIds AND LSC_LevySource__c = 'Council'])).keySet();
                if(levyIds != null && levyIds.size() > 0) {
                    for(LSC_Transaction__c t : topups) {
                        if(levyIds.contains(t.LSC_LevyId__c)) {
                            t.LSC_TransactionSource__c = 'Council';
                            t.LSC_PaymentMethod__c = 'Agency';
                        }
                    }
                }
            }
        }
    }

}