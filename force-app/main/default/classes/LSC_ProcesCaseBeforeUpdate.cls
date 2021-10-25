public class LSC_ProcesCaseBeforeUpdate {
    public LSC_ProcesCaseBeforeUpdate() {

    }

    public static void processBeforeUpdate (Map<Id, Case> newItems, Map<Id, Case> oldItems) {
        
        Id exemptionRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_CASE_RECORDTYPENAME_EXEMPTION).getRecordTypeId();
        Id instalmentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_CASE_RECORDTYPENAME_INSTALMENT).getRecordTypeId();
        Id refundRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_CASE_RECORDTYPENAME_REFUND).getRecordTypeId();


        Map<String, String> caseMap = new  Map<String, String>();
        List<String> submittedApprovalCase = new  List<String>();

        for (ProcessInstance instance : [select SubmittedById, TargetObjectId from ProcessInstance where TargetObjectId IN:newItems.keySet()]){
            caseMap.put(instance.TargetObjectId, instance.SubmittedById);
        }

        for (Id key : newItems.keySet()){
            Case newCase = newItems.get(key);
            Case oldCase = oldItems.get(key);

            if (newCase.RecordTypeId == exemptionRecordTypeId && 
                oldCase.Status != newCase.Status && 
                newCase.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_REJECTED){
                    newCase.LSC_ApprovedVoluntaryLabourCost__c = 0;                    
            }

            if ((newCase.RecordTypeId == instalmentRecordTypeId || newCase.RecordTypeId == exemptionRecordTypeId || refundRecordTypeId == newCase.RecordTypeId)  && 
                oldCase.Status != newCase.Status && (
                newCase.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_REJECTED || newCase.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_APPROVED)){
                if (caseMap.get(newCase.Id) != null && caseMap.get(newCase.Id) == UserInfo.getUserId()) {
                    newCase.addError('Submitter of the Approval Process can not Approve or Reject the Case');    
                }                          
            }
        }

       
    }
}