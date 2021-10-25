public class LSC_ProcessTLIBeforeInsert {

    /**
     * Method to add Before Trigger validations for Transaction Line Items     
     */
    public static void processTLIBeforeInsert (List<SObject> newItems){

        List<LSC_TransactionLineItem__c> tlItems = (List<LSC_TransactionLineItem__c>)newItems;

        Id commisionRecordTypeId    = Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_COMMISSION).getRecordTypeId();
        Id paymentRecordTypeId      = Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_PAYMENT).getRecordTypeId();
        Id writeoffRecordTypeId     = Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_WRITE_OFF).getRecordTypeId();

        Boolean isSalesforceUSer = !LSC_QueryUtils.isMuleSoftUserProfile();

        for (LSC_TransactionLineItem__c item : tlItems){
            if (isSalesforceUSer){
                if ((paymentRecordTypeId == item.RecordTypeId || writeoffRecordTypeId == item.RecordTypeId || commisionRecordTypeId == item.RecordTypeId) && (item.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_CANCELLED ||
                item.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_FAILED ||
                item.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_PROCESSING)){
                    item.addError('You can’t Create Line Items with Cancelled or Failed Status');
                }
            }
        }
    }
}