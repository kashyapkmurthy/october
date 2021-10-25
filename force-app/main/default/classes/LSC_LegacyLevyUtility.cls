//🤡🤡🤡
public with sharing class LSC_LegacyLevyUtility {
    public LSC_LegacyLevyUtility() {

    }

    public static void processLevyConversion(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, LSC_LegacyLevy__c> newLLs = (Map<Id, LSC_LegacyLevy__c>)newItems;
        Map<Id, LSC_LegacyLevy__c> oldLLs = (Map<Id, LSC_LegacyLevy__c>)oldItems;
        List<LSC_LegacyLevy__c> approvedLevies = new List<LSC_LegacyLevy__c>();
        Map<Id, Map<String, LSC_LegacyTransaction__c>> levyToTypeToTransaction = new Map<Id, Map<String, LSC_LegacyTransaction__c>>();
        List<SObject> newRecords = new List<SObject>();
        for(LSC_LegacyLevy__c ll : newLLs.values()) {
            if(oldLLs.get(ll.Id).LSC_IsApproved__c != ll.LSC_IsApproved__c && ll.LSC_IsApproved__c == true) {
                approvedLevies.add(ll);
            }
        }
        if(approvedLevies.size() > 0) {
            List<LSC_LegacyTransaction__c> lts = [SELECT LSC_AccountName__c,LSC_AccountNo__c,LSC_Amount__c,LSC_BSB__c,LSC_Comments__c,LSC_DataMigrationId__c,LSC_DueDate__c,LSC_GST__c,LSC_LastSyncedWithSAP__c,LSC_LegacyLevyId__c,LSC_PaidAmount__c,LSC_PaymentDate__c,LSC_PaymentMethod__c,LSC_PaymentReference__c,LSC_ReceiptDate__c,LSC_Stage__c,LSC_Status__c,LSC_Surcharge__c,LSC_SyncedWithSAP__c,LSC_TotalAmount__c,LSC_Type__c,Name,SystemModstamp FROM LSC_LegacyTransaction__c WHERE LSC_LegacyLevyId__c IN :approvedLevies ORDER BY LSC_PaymentDate__c ASC NULLS FIRST];
            if(lts != null && lts.size() > 0) {
                for(LSC_LegacyTransaction__c lt : lts) {
                    if(levyToTypeToTransaction.containsKey(lt.LSC_LegacyLevyId__c)) {
                        levyToTypeToTransaction.get(lt.LSC_LegacyLevyId__c).put(lt.LSC_Type__c, lt);
                    }   
                    else {
                        Map<String, LSC_LegacyTransaction__c> typeToTransaction = new Map<String, LSC_LegacyTransaction__c>();
                        typeToTransaction.put(lt.LSC_Type__c, lt);
                        levyToTypeToTransaction.put(lt.LSC_LegacyLevyId__c, typeToTransaction);
                    }                 
                }
            }
            Integer i = 0;
            for(LSC_LegacyLevy__c ll : approvedLevies) {
                Map<String, LSC_LegacyTransaction__c> typeToTransaction = new Map<String, LSC_LegacyTransaction__c>();
                if(levyToTypeToTransaction.containsKey(ll.Id)) {
                    typeToTransaction = levyToTypeToTransaction.get(ll.Id);
                }
                //
                LSC_Levy__c l = new LSC_Levy__c();
                l.LSC_AccountId__c = ll.LSC_NewLevyAccount__c;
                l.RecordTypeId = Schema.SObjectType.LSC_Levy__c.getRecordTypeInfosByName().get('BCI').getRecordTypeId();
                l.LSC_ApplicationNumber__c = ll.LSC_ApplicationNumber__c;
                l.LSC_ApplicationStatus__c = 'Ready to be paid';
                l.LSC_ApplicationType__c = ll.LSC_ApplicationType__c;
                l.LSC_Comments__c = ll.LSC_Comments__c;
                l.LSC_ConstructionEndDate__c = ll.LSC_ConstructionEndDate__c;
                l.LSC_ConstructionStartDate__c = ll.LSC_ConstructionStartDate__c;
                l.LSC_CostOfWorks__c = ll.LSC_CostOfWorks__c;
                l.LSC_DataMigrationId__c = ll.LSC_DataMigrationId__c;
                l.LSC_DeclarationAcceptedDateTime__c = ll.LSC_DeclarationAcceptedDateTime__c;
                l.LSC_ExemptionType__c = ll.LSC_ExemptionType__c;
                // Panaya-396 since the Approved Voluntary Labour Cost not bring across in the legacy levy conversion, so we should not set HasExemption flag.
                // Comment this line out to fix receipt issue
                //l.LSC_HasExemption__c = ll.LSC_HasExemption__c;
                l.LSC_HasOwnerBuilderLicence__c = ll.LSC_HasOwnerBuilderLicence__c;
                l.LSC_HasPrivateCertifier__c = ll.LSC_HasPrivateCertifier__c;
                l.LSC_IsDeclarationAccepted__c = ll.LSC_IsDeclarationAccepted__c;
                l.LSC_LegacyCertifierType__c = ll.LSC_LegacyCertifierType__c;
                l.LSC_LevyPayable__c = ll.LSC_LevyPayable__c;
                l.LSC_LocalGovtAreaOrGovtAuthority__c = ll.LSC_CorrectedLGA__c;
                l.LSC_OwnerBuilderLicenceExpiryDate__c = ll.LSC_OwnerBuilderLicenceExpiryDate__c;
                l.LSC_OwnerBuilderLicenceId__c = ll.LSC_OwnerBuilderLicenceId__c;
                l.LSC_OwnerBuilderLicenceNo__c = ll.LSC_OwnerBuilderLicenceNo__c;
                l.LSC_OwnerBuilderLicenceStartDate__c = ll.LSC_OwnerBuilderLicenceStartDate__c;
                l.LSC_OwnerBuilderLicenceStatus__c = ll.LSC_OwnerBuilderLicenceStatus__c;
                l.LSC_OwnerBuilderLicenceType__c = ll.LSC_OwnerBuilderLicenceType__c;
                l.LSC_OwnerBuilderLicenceeName__c = ll.LSC_OwnerBuilderLicenceeName__c;
                l.LSC_PrivateCertifierEmail__c = ll.LSC_PrivateCertifierEmail__c;
                l.LSC_HistoricalLevyNumber__c = ll.LSC_HistoricalLevyNumber__c;
                l.LSC_HistoricalAgentNumber__c = ll.LSC_HistoricalAgentNumber__c;
                l.LSC_HistoricalPayerName__c = ll.LSC_HistoricalPayerName__c;
                l.LSC_HistoricalPayerEmail__c = ll.LSC_HistoricalPayerEmail__c;
                l.LSC_HistoricalPayerPhone__c = ll.LSC_HistoricalPayerPhone__c;
                l.LSC_PrivateCertifierName__c = ll.LSC_PrivateCertifierName__c;
                l.LSC_PrivateCertifierPhone__c = ll.LSC_PrivateCertifierPhone__c;
                l.LSC_SiteAddressCity__c = ll.LSC_SiteAddressCity__c;
                l.LSC_SiteAddressCountry__c = ll.LSC_SiteAddressCountry__c;
                l.LSC_SiteAddressPostCode__c = ll.LSC_SiteAddressPostCode__c;
                l.LSC_SiteAddressState__c = ll.LSC_SiteAddressState__c;
                l.LSC_SiteAddressStreet__c = ll.LSC_SiteAddressStreet__c;
                l.LSC_SyncedWithSAP__c = ll.LSC_SyncedWithSAP__c;
                l.LSC_VoluntaryLabourCostofWorks__c = ll.LSC_VoluntaryLabourCostofWorks__c;
                l.LSC_LegacyLevyId__c = ll.Id;
                l.LSC_LevySource__c = 'Legacy';
                newRecords.add(l);
                //
                LSC_Transaction__c levy = new LSC_Transaction__c();
                levy.RecordTypeId = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get('Levy').getRecordTypeId();
                levy.LSC_Amount__c = ll.LSC_LevyPayable__c;
                levy.LSC_DataMigrationId__c = ll.LSC_DataMigrationId__c; 
                levy.LSC_LevyId__r = new LSC_Levy__c(LSC_DataMigrationId__c = ll.LSC_DataMigrationId__c);
                levy.LSC_Status__c = 'Pending';     
                levy.LSC_TransactionSource__c = 'Legacy';   
                levy.LSC_Comments__c = ll.LSC_Comments__c;
                if(typeToTransaction.containsKey('Payment')) {
                    //levy.LSC_DueDate__c  = typeToTransaction.get('Payment').LSC_DueDate__c;
                    levy.LSC_DueDate__c = System.today();
                }
                else {
                    levy.LSC_DueDate__c = System.today();
                }
                newRecords.add(levy);
                //
                if(ll.LSC_CorrectedTotalPaidAmount__c != null && ll.LSC_CorrectedTotalPaidAmount__c != 0) {
                    newRecords.add(createTLI('Payment', ll.LSC_CorrectedTotalPaidAmount__c, ll, typeToTransaction.get('Payment'), null));
                }    
                if(ll.LSC_CorrectedWriteOffAmount__c != null && ll.LSC_CorrectedWriteOffAmount__c != 0) {
                    newRecords.add(createTLI('Write Off', ll.LSC_CorrectedWriteOffAmount__c, ll, typeToTransaction.get('WriteOff'), null));
                }    
                //if(ll.LSC_CorrectedCommissionAmount__c != null && ll.LSC_CorrectedCommissionAmount__c != 0) {
                //    newRecords.add(createTLI('Commission', ll.LSC_CorrectedCommissionAmount__c, ll, typeToTransaction.get('Commission'), ll.LSC_CorrectedGSTAmount__c));
                //}   
                if(ll.LSC_CorrectedRefundAmount__c != null && ll.LSC_CorrectedRefundAmount__c != 0) {
                    LSC_Transaction__c refund = new LSC_Transaction__c();   
                    LSC_TransactionLineItem__c rPayment = new LSC_TransactionLineItem__c();
                    refund.RecordTypeId = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
                    rPayment.RecordTypeId = Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get('Payment').getRecordTypeId();
                    refund.LSC_LevyId__r = new LSC_Levy__c(LSC_DataMigrationId__c = ll.LSC_DataMigrationId__c);
                    refund.LSC_Amount__c = ll.LSC_CorrectedRefundAmount__c;
                    refund.LSC_Status__c = 'Pending';
                    refund.LSC_TransactionSource__c = 'Legacy';  
                    refund.LSC_PaymentMethod__c = 'EFT';
                    rPayment.LSC_Amount__c = ll.LSC_CorrectedRefundAmount__c;
                    rPayment.LSC_Status__c = 'Paid';
                    if(typeToTransaction.containsKey('Refund')) {
                        LSC_LegacyTransaction__c lt = typeToTransaction.get('Refund');
                        refund.LSC_AccountName__c = lt.LSC_AccountName__c;
                        refund.LSC_AccountNo__c = lt.LSC_AccountNo__c;
                        refund.LSC_BSB__c = lt.LSC_BSB__c;
                        refund.LSC_Comments__c = lt.LSC_Comments__c;
                        refund.LSC_DataMigrationId__c = lt.LSC_DataMigrationId__c;
                        //refund.LSC_DueDate__c = lt.LSC_DueDate__c;    
                        refund.LSC_DueDate__c = System.today();                   
                        refund.LSC_Stage__c = lt.LSC_Stage__c;
                        rPayment.LSC_Comments__c = lt.LSC_Comments__c;
                        rPayment.LSC_DataMigrationId__c = lt.LSC_DataMigrationId__c;
                        //rPayment.LSC_PaymentDate__c = lt.LSC_PaymentDate__c;
                        rPayment.LSC_PaymentDate__c = System.today(); 
                        if(lt.LSC_PaymentMethod__c != null) {
                            rPayment.LSC_PaymentMethod__c = lt.LSC_PaymentMethod__c;
                        } 
                        else {
                            rPayment.LSC_PaymentMethod__c = 'EFT';
                        }
                        //rPayment.LSC_PaymentReference__c = lt.LSC_PaymentReference__c;
                        //rPayment.LSC_ReceiptDate__c = lt.LSC_ReceiptDate__c;
                        rPayment.LSC_ReceiptDate__c = System.today(); 
                        rPayment.LSC_Surcharge__c = lt.LSC_Surcharge__c;
                        rPayment.LSC_TransactionId__r = new LSC_Transaction__c(LSC_DataMigrationId__c = lt.LSC_DataMigrationId__c);  
                    }
                    else {
                        String hashString = String.valueOf(i) + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
                        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
                        String hexDigest = EncodingUtil.convertToHex(hash);                        
                        refund.LSC_Comments__c = ll.LSC_Comments__c;
                        refund.LSC_DataMigrationId__c = hexDigest;
                        refund.LSC_DueDate__c = System.today();    
                
                        rPayment.LSC_Comments__c = ll.LSC_Comments__c;
                        rPayment.LSC_DataMigrationId__c = hexDigest;
                        rPayment.LSC_PaymentDate__c = System.today(); 
                        rPayment.LSC_PaymentMethod__c = 'EFT';
                        rPayment.LSC_ReceiptDate__c = System.today(); 
                        rPayment.LSC_TransactionId__r = new LSC_Transaction__c(LSC_DataMigrationId__c = hexDigest);                             
                    } 
                    newRecords.add(refund);
                    newRecords.add(rPayment);          
                }  
                i++;
            }
            if(newRecords.size() > 0) {
                newRecords.sort();
                insert newRecords;    
                //👮‍♂️ Welcome to recursion 
                List<LSC_LegacyLevy__c> lls = new List<LSC_LegacyLevy__c>();
                for(SObject rec : newRecords) {
                    if(rec.getSObjectType() == Schema.LSC_Levy__c.getSObjectType()) {
                        lls.add(new LSC_LegacyLevy__c(Id = (Id)rec.get('LSC_LegacyLevyId__c'), LSC_LevyId__c = (Id)rec.get('Id')));
                    }
                }  
                if(lls.size() > 0) {
                    update lls;
                }
            }      
        }           
    }

    public static LSC_TransactionLineItem__c createTLI(String type, Decimal amount, LSC_LegacyLevy__c ll, LSC_LegacyTransaction__c lt, Decimal gst) {
        LSC_TransactionLineItem__c tli = new LSC_TransactionLineItem__c();
        tli.RecordTypeId = Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(type).getRecordTypeId();
        if(type == 'Commission') {
            tli.LSC_GST__c = gst;
        }
        if(type == 'Write Off') {
            tli.LSC_Is_Approved__c = true;
        }
        tli.LSC_Amount__c = amount;
        tli.LSC_Status__c = 'Paid';     
        tli.LSC_TransactionId__r = new LSC_Transaction__c(LSC_DataMigrationId__c = ll.LSC_DataMigrationId__c);    
        if(lt != null) {
            tli.LSC_Comments__c = lt.LSC_Comments__c;
            tli.LSC_DataMigrationId__c = lt.LSC_DataMigrationId__c;
            //tli.LSC_PaymentReference__c = lt.LSC_PaymentReference__c;
            tli.LSC_ReceiptDate__c = System.today(); 
            tli.LSC_PaymentDate__c = System.today();
            //tli.LSC_Surcharge__c = lt.LSC_Surcharge__c; 
            if(type == 'Commission') {
                tli.LSC_PaymentMethod__c = 'Agency'; 
                tli.LSC_AccountId__c = ll.LSC_CorrectedCouncilAccount__c;
            }
            else if(lt.LSC_PaymentMethod__c == null) {
                tli.LSC_PaymentMethod__c = 'EFT'; 
            }
            else {
                tli.LSC_PaymentMethod__c = lt.LSC_PaymentMethod__c;
            }
            
        }
        else {
            tli.LSC_Comments__c = ll.LSC_Comments__c;
            tli.LSC_ReceiptDate__c = System.today(); 
            tli.LSC_PaymentDate__c = System.today();
            tli.LSC_PaymentMethod__c = 'EFT';        
        }
        return tli;
    }
}