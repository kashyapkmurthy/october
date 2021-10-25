public class LSC_ProcessTransactionBeforeUpdate {
   
    /**
     * Method to validate Before Update Trigger for Transaction Object.
     * 
     */
    public static void processTransactionBeforeUpdate (Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
            Id levyRecordTypeId       = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_LEVY).getRecordTypeId();
            Id instalmentRecordTypeId = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_INSTALMENT).getRecordTypeId();
            Id topupRecordTypeId      = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_TOPUP).getRecordTypeId();
            Id interestRecordTypeId   = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_INTEREST).getRecordTypeId();
            Id refundRecordTypeId     = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_REFUND).getRecordTypeId();
            
            Map<Id, LSC_Transaction__c> newTransactionMap = (Map<Id, LSC_Transaction__c>)newItems;
            Map<Id, LSC_Transaction__c> oldTransactionMap = (Map<Id, LSC_Transaction__c>)oldItems;

            Boolean isSalesforceUSer = !LSC_QueryUtils.isMuleSoftUserProfile();
            Map<String, Transaction_Attribute__mdt> transactionAttributeMdt = Transaction_Attribute__mdt.getAll();
            Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.LSC_Transaction__c.fields.getMap();
            List<String> fieldList = new List<String>();
            for (String str : transactionAttributeMdt.keyset()) {
                fieldList.add(transactionAttributeMdt.get(str).Transaction_Field_Name__c);
            } 
        
            for (Id key : newTransactionMap.keySet()){
                LSC_Transaction__c newtransactionItem = newTransactionMap.get(key);
                LSC_Transaction__c oldtransactionItem = oldTransactionMap.get(key);

                if ((oldtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING) && (newtransactionItem.LSC_Amount__c <= newtransactionItem.LSC_PaidAmount__c)){            
                    newtransactionItem.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PAID;
                }

                if ((oldtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PAID) && (newtransactionItem.LSC_Amount__c > newtransactionItem.LSC_PaidAmount__c)){            
                    newtransactionItem.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
                }
                if (isSalesforceUser){

                    if ((newtransactionItem.recordTypeId == refundRecordTypeId) && 
                    (String.isBlank(newtransactionItem.LSC_TransactionSource__c))){            
                        newtransactionItem.addError(new MyException('You can’t edit a Refund record'));
                    }

                    if (getRecordTypeNameById('LSC_Transaction__c', newtransactionItem.recordTypeId) == 'Levy' ||
                        getRecordTypeNameById('LSC_Transaction__c', newtransactionItem.recordTypeId) == 'Instalment' ||
                        getRecordTypeNameById('LSC_Transaction__c', newtransactionItem.recordTypeId) == 'Top Up' ||
                        getRecordTypeNameById('LSC_Transaction__c', newtransactionItem.recordTypeId) == 'Interest'
                        ){                        
                        if (newtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING){
                            newtransactionItem.LSC_SyncedWithSAP__c = false;
                            Schema.sObjectField[] sObj = getChangedFields(newtransactionItem.id, fieldMap.values());
                            for (Schema.sObjectField s : sObj){
                                String str = String.valueOf(s);
                                System.debug('str--->'+str);
                                if (!fieldList.contains(str)){
                                    //Don't change
                                    newtransactionItem.addError(new MyException('Only Due Date, Payment Reference, Stage, Rep Email and Comments can be edited for Pending Transaction'));      
                                }
                                if (fieldList.contains(str)){
                                    newtransactionItem.LSC_SyncedWithSAP__c = false;    
                                }
                            }
                        } 

                        if (oldtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING && 
                            newtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_CANCELLED){
                            if (topupRecordTypeId == newtransactionItem.recordTypeId){
                                newtransactionItem.addError(new MyException('Top Up Transaction can’t be Cancelled'));    
                            }
                            if (newtransactionItem.LSC_ProcessingAmount__c > 0 || newtransactionItem.LSC_PaidAmount__c > 0){
                                //Don't change
                                newtransactionItem.addError(new MyException('Transaction can’t be Cancelled when it\'s partially or fully paid'));            
                            }else{
                                newtransactionItem.LSC_SyncedWithSAP__c = false;    
                            }
                        }

                        if (oldtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PAID){
                            Schema.sObjectField[] sObj = getChangedFields(newtransactionItem.id, fieldMap.values());
                            for (Schema.sObjectField s : sObj){
                                String str = String.valueOf(s);
                                if (!fieldList.contains(str)){
                                    //Don't change
                                    newtransactionItem.addError(new MyException('Only Due Date, Payment Reference, Stage, Rep Email and Comments can be edited for Pending Transaction'));    
                                }
                            }

                            if (oldtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PAID && 
                            (newtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_CANCELLED || 
                            newtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING || 
                            newtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_FAILED)){
                                // Panaya 321 - Getting validation error when uploading council file
                                // When a transaction type is Levy and transaction source is Council, transaction status is changed from Paid to Pending
                                // will not fire the trigger validation to run
                                if (newtransactionItem.LSC_Status__c != LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING
                                || newtransactionItem.LSC_TransactionSource__c != 'Council'
                                || newtransactionItem.RecordTypeId != levyRecordTypeId) {
                                    newtransactionItem.addError(new MyException('You can’t change the Transaction Paid Status'));    
                                }
                            }
                        }
                        
                        if (oldtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING &&                             
                            newtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_FAILED){
                                newtransactionItem.addError(new MyException('You can’t set the record as Failed'));
                        }
                    }

                    

                     //Generic Method where we dont allow Editing a Cancelled or Failed Transaction.
                    if (oldtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_CANCELLED){            
                        newtransactionItem.addError(new MyException('You can’t edit a cancelled record'));
                    }

                    if (oldtransactionItem.LSC_Status__c == LSC_GlobalConstants.LSC_TRANSACTION_STATUS_FAILED){            
                        newtransactionItem.addError(new MyException('You can’t edit a failed record'));
                    }                    
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