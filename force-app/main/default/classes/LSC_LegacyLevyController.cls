public with sharing class LSC_LegacyLevyController {

    @AuraEnabled(cacheable=true)
    public static LLWrapper getData(String recordId) {
        LLWrapper wrapper = new LLWrapper();
        LSC_LegacyLevy__c ll = [SELECT LSC_CostOfWorks__c, LSC_LevyPayable__c FROM LSC_LegacyLevy__c WHERE Id = :recordId];
        
        
        Double paidAmount = 0;
        Double writeOffAmount = 0;
        Double commission = 0;
        Double refundedAmount = 0;
        Double gst = 0;
        List<LSC_LegacyTransaction__c> lts = [SELECT LSC_AccountName__c,LSC_AccountNo__c,LSC_Amount__c,LSC_BSB__c,LSC_Comments__c,LSC_DataMigrationId__c,LSC_DueDate__c,LSC_GST__c,LSC_LastSyncedWithSAP__c,LSC_LegacyLevyId__c,LSC_PaidAmount__c,LSC_PaymentDate__c,LSC_PaymentMethod__c,LSC_PaymentReference__c,LSC_ReceiptDate__c,LSC_Stage__c,LSC_Status__c,LSC_Surcharge__c,LSC_SyncedWithSAP__c,LSC_TotalAmount__c,LSC_Type__c,Name,SystemModstamp FROM LSC_LegacyTransaction__c WHERE LSC_LegacyLevyId__c = :recordId];
        for(LSC_LegacyTransaction__c lt : lts) {
            if(lt.LSC_Type__c == 'Payment') {
                if(lt.LSC_PaidAmount__c != null) {
                    paidAmount += lt.LSC_PaidAmount__c;
                }
                else {
                    paidAmount += lt.LSC_Amount__c;
                }            
            }
            else if(lt.LSC_Type__c == 'Commission') {
                if(lt.LSC_PaidAmount__c != null) {
                    commission += lt.LSC_PaidAmount__c;
                }
                else {
                    commission += lt.LSC_Amount__c;
                }  
                if(lt.LSC_GST__c != null) {
                    gst += lt.LSC_GST__c;
                }                                 
            }
            else if(lt.LSC_Type__c == 'WriteOff') {
                if(lt.LSC_PaidAmount__c != null) {
                    writeOffAmount += lt.LSC_PaidAmount__c;
                }
                else {
                    writeOffAmount += lt.LSC_Amount__c;
                }
            }
            else if(lt.LSC_Type__c == 'Refund') {
                if(lt.LSC_PaidAmount__c != null) {
                    refundedAmount += lt.LSC_PaidAmount__c;
                }
                else {
                    refundedAmount += lt.LSC_Amount__c;
                }
            }            
        }
        wrapper.costOfWorks = ll.LSC_CostOfWorks__c;
        wrapper.levyPayable = ll.LSC_LevyPayable__c;
        wrapper.paidAmount = paidAmount;
        wrapper.writeOffAmount = writeOffAmount;
        wrapper.refundedAmount = refundedAmount;
        wrapper.commissionAmount = commission;
        wrapper.gst = gst;
        wrapper.isLocked = Approval.isLocked(recordId);
        return wrapper;
    }

    @AuraEnabled
    public static ResultWrapper submitApproval(String recordId, String accountId, String userId, Double paid, Double refunded, Double writeoff, String lga) {
        ResultWrapper result = new ResultWrapper();
        try {
            LSC_LegacyLevy__c ll = new LSC_LegacyLevy__c();
            ll.Id = recordId;
            ll.LSC_Approver__c = userId;
            ll.LSC_NewLevyAccount__c = accountId;
            ll.LSC_CorrectedTotalPaidAmount__c = paid;
            ll.LSC_CorrectedRefundAmount__c = refunded;
            ll.LSC_CorrectedWriteOffAmount__c = writeoff;
            //ll.LSC_CorrectedCommissionAmount__c =  commission;
            ll.LSC_CorrectedLGA__c = lga;
            //ll.LSC_CorrectedGSTAmount__c = gst;
            update ll;
            
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Request for Legacy Levy conversion approval');
            req.setObjectId(recordId);
            req.setNextApproverIds(new Id[] {userId});
            Approval.ProcessResult res = Approval.process(req);

            return result;
        }
        catch(Exception e) {
            result.error = e.getMessage();
            return result;
        }
    }

    public class ResultWrapper {
        @AuraEnabled
        public String error {get; set;}   
    } 

    public class LLWrapper {
        @AuraEnabled
        public Double paidAmount {get; set;}   

        @AuraEnabled
        public Double writeOffAmount {get; set;}

        @AuraEnabled
        public Double refundedAmount {get; set;}   

        @AuraEnabled
        public Double commissionAmount {get; set;}           

        @AuraEnabled
        public Double costOfWorks {get; set;}        
        
        @AuraEnabled
        public Double levyPayable {get; set;}   

        @AuraEnabled
        public Double gst {get; set;}           
        
        @AuraEnabled
        public Boolean isLocked { get; set; }
    
    }     
}