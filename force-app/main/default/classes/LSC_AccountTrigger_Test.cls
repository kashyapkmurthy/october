@isTest
private class LSC_AccountTrigger_Test {

    static testMethod void createAccountsTest() {
        List<Account> accountList = LSC_TestDataFactory.createAccounts(200);

        Test.startTest();
            insert accountList;
        Test.stopTest();
    }

    static testMethod void updateAccountsTest() {
        List<Account> accountList = LSC_TestDataFactory.createAccounts(200);
        for (Account acc : accountList){
            acc.LSC_SyncedWithSAP__c = true;
        }

        insert accountList;

        for (Account a : accountList){
            a.Phone = '0297452014';
        }

        Test.startTest();
            update accountList;
        Test.stopTest();
    }


}