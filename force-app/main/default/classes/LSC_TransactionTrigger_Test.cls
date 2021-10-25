@isTest
private class LSC_TransactionTrigger_Test {
    
    static testMethod void createInstalmentTransactionTest() {
        List<Account> accountList = LSC_TestDataFactory.createAccounts(1);
        accountList.get(0).LSC_SyncedWithSAP__c = true;
        accountList.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accountList;

        List<Contact> contactList = LSC_TestDataFactory.createContact(1, accountList.get(0));
        insert contactList;

        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accountList.get(0), contactList.get(0));
        insert levyList;

        List<LSC_Transaction__c> transactionList = LSC_TestDataFactory.createTransaction(1, levyList.get(0), Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_INSTALMENT).getRecordTypeId());      

        for ( LSC_Transaction__c tran: transactionList){
            tran.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
        }

        Test.startTest();
            insert transactionList;
        Test.stopTest();

    } 

    
    static testMethod void createInterestTransactionTest() {
        List<Account> accountList = LSC_TestDataFactory.createAccounts(1);
        accountList.get(0).LSC_SyncedWithSAP__c = true;
        accountList.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accountList;

        List<Contact> contactList = LSC_TestDataFactory.createContact(1, accountList.get(0));
        insert contactList;

        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accountList.get(0), contactList.get(0));
        insert levyList;

        List<LSC_Transaction__c> transactionList = LSC_TestDataFactory.createTransaction(1, levyList.get(0), Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_INTEREST).getRecordTypeId());      
        for ( LSC_Transaction__c tran: transactionList){
            tran.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
           
        }

        Test.startTest();
            insert transactionList;
        Test.stopTest();

    } 
    
    static testMethod void createRefundTransactionTest() {
        List<Account> accountList = LSC_TestDataFactory.createAccounts(1);
        accountList.get(0).LSC_SyncedWithSAP__c = true;
        accountList.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accountList;

        List<Contact> contactList = LSC_TestDataFactory.createContact(1, accountList.get(0));
        insert contactList;

        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accountList.get(0), contactList.get(0));
        insert levyList;

        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
        List<Case> cases = LSC_TestDataFactory.createCase(1, accountList[0], contactList[0], levyList[0], caseRT);

        insert cases;

        List<LSC_Transaction__c> transactionList = LSC_TestDataFactory.createTransaction(1, levyList.get(0), Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_REFUND).getRecordTypeId());      
        for ( LSC_Transaction__c tran: transactionList){
            tran.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;  
            tran.LSC_CaseId__c = cases[0].Id;
        }

        Test.startTest();
            insert transactionList;
        Test.stopTest();

    } 

    static testMethod void createTopUpTransactionTest() {
        List<Account> accountList = LSC_TestDataFactory.createAccounts(1);
        accountList.get(0).LSC_SyncedWithSAP__c = true;
        accountList.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accountList;

        List<Contact> contactList = LSC_TestDataFactory.createContact(1, accountList.get(0));
        insert contactList;

        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accountList.get(0), contactList.get(0));
        levyList[0].LSC_LevySource__c = 'Council';
        insert levyList;

        List<LSC_Transaction__c> transactionList = LSC_TestDataFactory.createTransaction(1, levyList.get(0), Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_TOPUP).getRecordTypeId());      
        for ( LSC_Transaction__c tran: transactionList){
            tran.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;  
        }

        Test.startTest();
            insert transactionList;
        Test.stopTest();

    }
    
    static testMethod void updateToCancelTransactionTest() {
        List<Account> accountList = LSC_TestDataFactory.createAccounts(1);
        accountList.get(0).LSC_SyncedWithSAP__c = true;
        accountList.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accountList;

        List<Contact> contactList = LSC_TestDataFactory.createContact(1, accountList.get(0));
        insert contactList;

        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accountList.get(0), contactList.get(0));
        levyList[0].LSC_LevySource__c = 'Council';
        insert levyList;

        List<LSC_Transaction__c> transactionList = LSC_TestDataFactory.createTransaction(1, levyList.get(0), Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_TOPUP).getRecordTypeId());      
        for ( LSC_Transaction__c tran: transactionList){
            tran.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;  
        }
        
        insert transactionList;

        Test.startTest();
            for ( LSC_Transaction__c tran: transactionList){
            	tran.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_CANCELLED;  
        	}
        	
        	try{
        		update transactionList;
            }catch (Exception ex){
                 boolean hasMessage = ex.getMessage().contains('Top Up Transaction can’t be Cancelled') ? true : false;
            	System.assertEquals(true, hasMessage);
            }
        Test.stopTest();
    }

    static testMethod void createPaymentTransactionTest() {

        LSC_TransactionLineItem__c item;
        
        List<Account> accountList = LSC_TestDataFactory.createAccounts(1);
        accountList.get(0).LSC_SyncedWithSAP__c = true;
        accountList.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accountList;

        List<Contact> contactList = LSC_TestDataFactory.createContact(1, accountList.get(0));
        insert contactList;

        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accountList.get(0), contactList.get(0));
        insert levyList;

        List<LSC_Transaction__c> transactionList = LSC_TestDataFactory.createTransaction(1, levyList.get(0), Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_LEVY).getRecordTypeId());      

        for ( LSC_Transaction__c tran: transactionList){
            tran.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
            tran.LSC_SyncedWithSAP__c = false;
            tran.LSC_Amount__c        = 180;
            tran.LSC_SAPDocumentNo__c  ='1122333';
            
            //tran.LSC_TransactionSource__c = 'Agency';
        }

        insert transactionList;

        item = new LSC_TransactionLineItem__c();
        item.LSC_TransactionId__c       = transactionList[0].Id;
        //item.LSC_AccountId__c       = accountList.get(0).Id;
        item.LSC_Status__c          = 'Paid';
        item.LSC_Amount__c            = 100;
        item.recordtypeid =  Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_PAYMENT).getRecordTypeId();
        insert item;

        Test.startTest();    
            transactionList[0].LSC_Comments__c = 'ABCD';
        	update transactionList;
        Test.stopTest();

    }
    
    static testMethod void createFailedPaymentTransactionTest() {
        
        Profile profile1 = [Select Id from Profile where name = 'Integration Administrator'];
        User portalAccountOwner1 = new User(
        ProfileId = profile1.Id,
        Username = System.now().millisecond() + 'test2@test.com',
        Alias = 'batman',
        Email='bruce.wayne@wayneenterprises.com',
        EmailEncodingKey='UTF-8',
        Firstname='Bruce',
        Lastname='Wayne',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);

        LSC_TransactionLineItem__c item;
        
        List<Account> accountList = LSC_TestDataFactory.createAccounts(1);
        accountList.get(0).LSC_SyncedWithSAP__c = true;
        accountList.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accountList;

        List<Contact> contactList = LSC_TestDataFactory.createContact(1, accountList.get(0));
        insert contactList;

        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accountList.get(0), contactList.get(0));
        insert levyList;

        List<LSC_Transaction__c> transactionList = LSC_TestDataFactory.createTransaction(1, levyList.get(0), Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_LEVY).getRecordTypeId());      

        for ( LSC_Transaction__c tran: transactionList){
            tran.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
            tran.LSC_SyncedWithSAP__c = false;
            tran.LSC_Amount__c        = 180;
            tran.LSC_SAPDocumentNo__c  ='1122333';             
            tran.LSC_PaymentMethod__c = 'EFT';
            tran.LSC_SyncedWithSAP__c = true;
        }

        insert transactionList;

        item = new LSC_TransactionLineItem__c();
        item.LSC_TransactionId__c       = transactionList[0].Id;
        item.LSC_Status__c          = 'Paid';
        item.LSC_Amount__c            = 180;
        item.recordtypeid =  Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_PAYMENT).getRecordTypeId();
        insert item;
        
        System.runAs(portalAccountOwner1){
            Test.startTest();    
               
            try{
            	LSC_ProcessTransactionAfterUpdate.updateRelatedTLIStatus(transactionList[0].Id);
            }catch(Exception ex){
                
            } 
            Test.stopTest();
        }

    }
    
    

    static testMethod void testUnusedMethod() {
        LSC_TransactionLineItem__c item;
        
        List<Account> accountList = LSC_TestDataFactory.createAccounts(1);
        accountList.get(0).LSC_SyncedWithSAP__c = true;
        accountList.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accountList;

        List<Contact> contactList = LSC_TestDataFactory.createContact(1, accountList.get(0));
        insert contactList;

        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accountList.get(0), contactList.get(0));
        insert levyList;

        List<LSC_Transaction__c> transactionList = LSC_TestDataFactory.createTransaction(1, levyList.get(0), Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_LEVY).getRecordTypeId());      

        for ( LSC_Transaction__c tran: transactionList){
            tran.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
        }

        insert transactionList;

        Map<Id, SObject> items = new Map<Id, SObject>();
        items.put(transactionList[0].Id, transactionList[0]);

        Test.startTest();
        LSC_TransactionTriggerHandler handler = new LSC_TransactionTriggerHandler();
            handler.BeforeDelete(items);
            handler.AfterDelete(items);
            handler.AfterUndelete(items);
        	handler.isDisabled();
        Test.stopTest();
    }

}