@istest
private class LSC_PrintTransactionDetailsTest {
    
    static testMethod void testPrintTransaction() {
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        insert levyList;

        List<LSC_Transaction__c> transactions = LSC_TestDataFactory.createTransaction(1,levyList[0], Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_INSTALMENT).getRecordTypeId());
        transactions[0].LSC_Status__c = 'Pending';
        insert transactions;

        transactions[0].LSC_Status__c = 'Paid';
        update transactions;

        PageReference pageRef = Page.LevyReceipt;
        Test.setCurrentPage(pageRef);

        pageRef.getParameters().put('Id', String.valueOf(transactions[0].Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(transactions[0]);
        LSC_PrintTransactionDetails testAccPlan = new LSC_PrintTransactionDetails(sc);
        LSC_PrintTransactionDetails.getFieldNames();

    }

    static testMethod void testCancelTransaction() {
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        insert levyList;

        List<LSC_Transaction__c> transactions = LSC_TestDataFactory.createTransaction(1,levyList[0], Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_INSTALMENT).getRecordTypeId());
        transactions[0].LSC_Status__c = 'Pending';
        insert transactions;

        transactions[0].LSC_Status__c = 'Cancelled';
        update transactions;

        PageReference pageRef = Page.LevyReceipt;
        Test.setCurrentPage(pageRef);

        pageRef.getParameters().put('Id', String.valueOf(transactions[0].Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(transactions[0]);
        LSC_PrintTransactionDetails testAccPlan = new LSC_PrintTransactionDetails(sc);
        LSC_PrintTransactionDetails.getFieldNames();

    }
}