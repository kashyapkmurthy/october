/**
* Before Update Trigger for Transaction Line Items
*     
*/
public class LSC_ProcessTLIBeforeUpdate {

    /**
     * Method to add Before Trigger validations for Transaction Line Items     
     */
    public static void processTLIBeforeUpdate (Map<Id, SObject> newItems, Map<Id, SObject> oldItems){

        Id commisionRecordTypeId    = Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_COMMISSION).getRecordTypeId();
        Id paymentRecordTypeId      = Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_PAYMENT).getRecordTypeId();
        Id writeoffRecordTypeId     = Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_WRITE_OFF).getRecordTypeId();
        
        Map<Id, LSC_TransactionLineItem__c> newTransactionLIMap = (Map<Id, LSC_TransactionLineItem__c>)newItems;
        Map<Id, LSC_TransactionLineItem__c> oldTransactionLIMap = (Map<Id, LSC_TransactionLineItem__c>)oldItems;

        Map<String, Transaction_Line_Attribute__mdt> transactionLineAttributeMdt = Transaction_Line_Attribute__mdt.getAll();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.LSC_TransactionLineItem__c.fields.getMap();
        List<String> fieldList = new List<String>();
        for (String str : transactionLineAttributeMdt.keyset()) {
            fieldList.add(transactionLineAttributeMdt.get(str).Transaction_Line_Field_Name__c);
        }

        Boolean isSalesforceUSer = !LSC_QueryUtils.isMuleSoftUserProfile();

        Map<String, String> tliMap = new  Map<String, String>();
        for (ProcessInstance instance : [select SubmittedById, TargetObjectId from ProcessInstance where TargetObjectId IN:newItems.keySet()]){
            tliMap.put(instance.TargetObjectId, instance.SubmittedById);
        }
        
        for (Id key : newTransactionLIMap.keySet()){
            LSC_TransactionLineItem__c newtransactionLineItem = newTransactionLIMap.get(key);
            LSC_TransactionLineItem__c oldtransactionLineItem = oldTransactionLIMap.get(key);
            
            if (isSalesforceUSer){

                if (getRecordTypeNameById('LSC_TransactionLineItem__c', newtransactionLineItem.RecordTypeId) == 'Write Off'){    

                    if (oldtransactionLineItem.LSC_Status__c != newtransactionLineItem.LSC_Status__c && (newtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_PAID )){                        
                        if (tliMap.get(newtransactionLineItem.Id) != null && tliMap.get(newtransactionLineItem.Id) == UserInfo.getUserId()) {
                            newtransactionLineItem.addError('Submitter of the Approval Process can not Approve or Reject the Transaction Line Item');    
                        }                          
                    }
                    
                    if (oldtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_PAID){                    
                        Schema.sObjectField[] sObj = getChangedFields(newtransactionLineItem.id, fieldMap.values());
                        for (Schema.sObjectField s : sObj){
                            String str = String.valueOf(s);
                            System.debug('str--->'+str);
                            if (!fieldList.contains(str)){
                                newtransactionLineItem.addError(new MyException('You can only update the Status of Writeoff Record'));    
                            }else if (newtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_CANCELLED){
                                newtransactionLineItem.LSC_SyncedWithSAP__c = false;
                            }
                        }
                    }
                }               

                if (paymentRecordTypeId == newtransactionLineItem.RecordTypeId && 
                   ((oldtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_PROCESSING || 
                     oldtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_PAID) && 
                    (newtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_PAID || 
                    newtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_CANCELLED ||
                    newtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_FAILED))){
                        newtransactionLineItem.addError('You can’t update Payments that have been Paid');
                }

                if (commisionRecordTypeId == newtransactionLineItem.RecordTypeId && 
                   (oldtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_PAID)){
                    newtransactionLineItem.addError('You can’t update Commisions that are Paid');
                }

                if ((newtransactionLineItem.recordTypeId == commisionRecordTypeId)  && 
                (newtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_CANCELLED) ){
                    newtransactionLineItem.addError('Commission records can’t be cancelled');
                }

                if ((oldtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_FAILED)){
                    newtransactionLineItem.addError('Failed records can’t be edited');
                }                

                if ( oldtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_CANCELLED ){
                    newtransactionLineItem.addError('Cancelled records can’t be edited');
                }                
            }

            //TLI Payment Status changed to Cancelled? 
            if ( newtransactionLineItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_CANCELLED){
                    newtransactionLineItem.LSC_PaymentDate__c=null; //Clear the Payment Date.
            }

        }
    }


    public class MyException extends Exception {}

    public static Schema.sObjectField[] getChangedFields(ID recordId, Schema.sObjectField[] fieldList) {
        Schema.sObjectField[] changedFields = new list<Schema.sObjectField> ();
        SObject o1 = Trigger.oldMap.get(recordId);
        SObject o2 = Trigger.newMap.get(recordId);
    
        for (Schema.sObjectField field : fieldList) {
            Object v1 = o1.get(field);
            Object v2 = o2.get(field);
            if (didFieldChange(v1, v2)) {
                changedFields.add(field);
            }
        }
        return changedFields;
    }
    
    private static Boolean didFieldChange(Object v1, Object v2) {
        if (v1 == null && v2 == null) {
            return false;
        }
        if (v1 != v2) {
            return true;
        }
        return false;
    }

    public static String getRecordTypeNameById(String objectName, Id strRecordTypeId)
    {
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById().get(strRecordTypeId).getName();
    } 

}