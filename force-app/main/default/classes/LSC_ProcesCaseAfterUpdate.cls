public class LSC_ProcesCaseAfterUpdate {

    public static void processCaseAfterUpdate (Map<Id, SObject> oldItems, Map<Id, SObject> newItems){
        Map<Id, Case> newCaseMap;
        Map<Id, Case> oldCaseMap;

        newCaseMap = (Map<Id, Case>) newItems;
        List<Id> newCaseIdList = new List<Id>();
        newCaseIdList.addAll(newCaseMap.keySet());
        
        oldCaseMap = (Map<Id, Case>) oldItems;
        List<Id> oldCaseIdList = new List<Id>();
        oldCaseIdList.addAll(oldCaseMap.keySet());

        Id refundRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_CASE_RECORDTYPENAME_REFUND).getRecordTypeId();
        Id exemptionRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_CASE_RECORDTYPENAME_EXEMPTION).getRecordTypeId();
        Id instalmentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_CASE_RECORDTYPENAME_INSTALMENT).getRecordTypeId();
        
        List<Id> caseList = new List<Id>();
        List<Id> caseInstalmentApprovedList = new List<Id>();
        List<Id> caseExemptionApprovedList  = new List<Id>();
        List<Id> caseInstalmentRejectedList = new List<Id>();
        Map<String, Case> caseLevyRefundApprovedMap = new Map<String, Case>();

        for (Id key : newCaseMap.keySet()){
            Case newCase = newCaseMap.get(key);
            Case oldCase = oldCaseMap.get(key);
            if (newCase.RecordTypeId == refundRecordTypeId && 
                oldCase.Status != newCase.Status && 
                newCase.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_APPROVED && 
                newCase.LSC_TransactionId__c == null){
                    caseList.add(newCase.Id);
                    caseLevyRefundApprovedMap.put(newCase.LSC_LevyId__c, newCase);
            }
            if (newCase.RecordTypeId == exemptionRecordTypeId && 
                oldCase.Status != newCase.Status && 
                newCase.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_APPROVED && 
                newCase.LSC_TransactionId__c == null){
                    caseList.add(newCase.Id);
                    if (newCase.LSC_LevyId__c != null){
                        caseExemptionApprovedList.add(newCase.LSC_LevyId__c);
                    }
            }
            if (newCase.RecordTypeId == exemptionRecordTypeId && 
                oldCase.Status != newCase.Status && 
                newCase.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_REJECTED && 
                newCase.LSC_TransactionId__c == null){
                    caseList.add(newCase.Id);                    
            }
            if (newCase.RecordTypeId == instalmentRecordTypeId && 
                oldCase.Status != newCase.Status && 
                newCase.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_APPROVED && 
                newCase.LSC_TransactionId__c == null){
                    caseList.add(newCase.Id);
                    if (newCase.LSC_LevyId__c != null){
                        caseInstalmentApprovedList.add(newCase.LSC_LevyId__c);
                    }
            }
            if (newCase.RecordTypeId == instalmentRecordTypeId && 
                oldCase.Status != newCase.Status && 
                newCase.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_REJECTED && 
                newCase.LSC_TransactionId__c == null){
                    caseList.add(newCase.Id); 
                    if (newCase.LSC_LevyId__c != null){
                        caseInstalmentRejectedList.add(newCase.LSC_LevyId__c);
                    }                    
            }
        }
        
        LSC_CreateTransactionRecordFromCase.createTransactionFromCase(caseList);
        if (!caseInstalmentApprovedList.isEmpty()){
            updateCaseInstalmentFlagSet(caseInstalmentApprovedList);
        }
        if (!caseExemptionApprovedList.isEmpty()){
            updateCaseExemptionFlagSet(caseExemptionApprovedList);
        }
        if (!caseInstalmentRejectedList.isEmpty()){
            updateRejctedInstalments(caseInstalmentRejectedList);
        }
        if (!caseLevyRefundApprovedMap.isEmpty()){
            updateRefundApproved(caseLevyRefundApprovedMap);
        }        
        
        
    }  

    
    public static void updateRefundApproved (Map<String, Case> caseLevyRefundApprovedMap){
        List<LSC_Levy__c> levyList = new List<LSC_Levy__c>();
        for (String key : caseLevyRefundApprovedMap.keySet()){            
            if (caseLevyRefundApprovedMap.get(key).LSC_NewCostOfWork__c != null){        
                LSC_Levy__c l = new LSC_Levy__c();
                l.id = key;                        
                l.LSC_CostOfWorks__c = caseLevyRefundApprovedMap.get(key).LSC_NewCostOfWork__c;
                levyList.add(l);
            } 
            //Refund with Exemption for NGO and Owner Builders.
            if (caseLevyRefundApprovedMap.get(key).LSC_NewCostOfWork__c == null && 
                caseLevyRefundApprovedMap.get(key).LSC_ApprovedVoluntaryLabourCost__c != null && 
                caseLevyRefundApprovedMap.get(key).LSC_ApprovedVoluntaryLabourCost__c > 0){
                LSC_Levy__c l = new LSC_Levy__c();
                l.id = key;                        
                l.LSC_ApprovedVoluntaryLabourcost__c = caseLevyRefundApprovedMap.get(key).LSC_ApprovedVoluntaryLabourCost__c;
                l.LSC_HasExemption__c = true;
                levyList.add(l);    
            }  
        }
        try{
            if (!levyList.isEmpty()){
                update levyList;
            }
        }
        catch(Exception e){
            LSC_LogHandler.logException('LSC_ProcesCaseAfterUpdate', 'updateRefundApproved', e.getMessage(),e.getLineNumber(),e.getStackTraceString());            
        }
    }
    
    @future
    public static void updateRejctedInstalments (List<Id> caseInstalmentRejectedList){
        List<LSC_Levy__c> levyList = new List<LSC_Levy__c>();
        for (Id i : caseInstalmentRejectedList){
            LSC_Levy__c l = new LSC_Levy__c();
            l.id = i;
            l.LSC_HasInstallments__c = false;
            l.LSC_ApplicationStatus__c = LSC_GlobalConstants.LSC_LEVY_APPLICATION_STATUS;
            levyList.add(l);
        }
        update levyList;
    }

    @future
    public static void updateCaseInstalmentFlagSet (List<Id> caseInstalmentApprovedList){
        List<LSC_Levy__c> levyList = new List<LSC_Levy__c>();
        for (Id i : caseInstalmentApprovedList){
            LSC_Levy__c l = new LSC_Levy__c();
            l.id = i;
            l.LSC_HasInstallments__c = true;
            l.LSC_ApplicationStatus__c = LSC_GlobalConstants.LSC_LEVY_APPLICATION_STATUS;
            levyList.add(l);
        }
        update levyList;
    }

    @future
    public static void updateCaseExemptionFlagSet (List<Id> caseExemptionApprovedList){
        List<LSC_Levy__c> levyList = new List<LSC_Levy__c>();
        for (Id i : caseExemptionApprovedList){
            LSC_Levy__c l = new LSC_Levy__c();
            l.id = i;
            l.LSC_HasExemption__c = true;            
            levyList.add(l);
        }
        update levyList;
    }

    


}