@isTest
private class LSC_TransactionLineItemTriggerTest {

    static testMethod void createTransactionLineItemTest() {
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

        LSC_TransactionLineItem__c item = new LSC_TransactionLineItem__c();
        item.LSC_TransactionId__c       = transactionList[0].Id;
        item.LSC_AccountId__c       = accountList.get(0).Id;
        item.LSC_Status__c          = LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_PAID;
        item.recordtypeid =  Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_PAYMENT).getRecordTypeId();

        Test.startTest();
            insert item;
        Test.stopTest();

    }

    static testMethod void createWriteOffTLITest() {
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

        item = new LSC_TransactionLineItem__c();
        item.LSC_TransactionId__c       = transactionList[0].Id;
        //item.LSC_AccountId__c       = accountList.get(0).Id;
        item.LSC_Status__c          = 'Pending Approval';
        item.recordtypeid =  Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_WRITE_OFF).getRecordTypeId();
        insert item;
            
        item.LSC_Status__c          = 'Paid';
        update item;
        
            Test.startTest();
            try{
                item.LSC_Reason__c = 'ABCD';
                update item;
            }catch(Exception e)
            {
                Boolean expectedExceptionThrown =  e.getMessage().contains('You can only update the Status of Writeoff Record') ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }

            try{
                item.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_CANCELLED;
                update item;
            }catch(Exception e)
            {
                Boolean expectedExceptionThrown =  e.getMessage().contains('You can only update the Status of Writeoff Record') ? true : false;
                //System.assertEquals(expectedExceptionThrown, true);
            }
            Test.stopTest();
    }

    static testMethod void createPaymentTLITest() {

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

        item = new LSC_TransactionLineItem__c();
        item.LSC_TransactionId__c       = transactionList[0].Id;
        //item.LSC_AccountId__c       = accountList.get(0).Id;
        item.LSC_Status__c          = 'Paid';
        item.recordtypeid =  Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_PAYMENT).getRecordTypeId();
        insert item;

        Test.startTest();
        try{
            item.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_CANCELLED;
            update item;
        }catch(Exception e)
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('You can’t update Payments that have been Paid') ? true : false;
            System.assertEquals(expectedExceptionThrown, true);
        }
            
        Test.stopTest();

    }

    static testMethod void createCommissionTLITest() {

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

        item = new LSC_TransactionLineItem__c();
        item.LSC_TransactionId__c       = transactionList[0].Id;
        item.LSC_AccountId__c       = accountList.get(0).Id;
        item.LSC_Status__c          = 'Paid';
        item.LSC_GST__c              = 1.8;
        item.LSC_Amount__c            = 18;
        item.recordtypeid =  Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_COMMISSION).getRecordTypeId();
        insert item;

        Test.startTest();
        try{
            item.LSC_Reason__c = 'ABCD';
            update item;
        }catch(Exception e)
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('You can’t update Commisions that are Paid') ? true : false;
            System.assertEquals(expectedExceptionThrown, true);
        }

        try{
            item.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_CANCELLED;
            update item;
        }catch(Exception e)
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Commission records can’t be cancelled') ? true : false;
            System.assertEquals(expectedExceptionThrown, true);
        }
            
        Test.stopTest();

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

        item = new LSC_TransactionLineItem__c();
        item.LSC_TransactionId__c       = transactionList[0].Id;
        item.LSC_AccountId__c       = accountList.get(0).Id;
        item.LSC_Status__c          = 'Paid';
        item.LSC_GST__c              = 1.8;
        item.LSC_Amount__c            = 18;
        item.recordtypeid =  Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_COMMISSION).getRecordTypeId();
        insert item;

        Map<Id, SObject> items = new Map<Id, SObject>();
        items.put(item.Id, item);

        Test.startTest();
        LSC_TransactionLineItemTriggerHandler handler = new LSC_TransactionLineItemTriggerHandler();
            handler.BeforeDelete(items);            
            handler.AfterUpdate(items, items);
            handler.AfterInsert(items);
            handler.AfterDelete(items);
            handler.AfterUndelete(items);
        	handler.isDisabled();
        	LSC_QueryUtils.getbankAndBranch('012055');
        Test.stopTest();
    }


    
}