@isTest
private class LSC_LevyTriggerTest {

    static testMethod void testUnusedMethod() {
        List<Account> accountList = LSC_TestDataFactory.createAccounts(1);
        accountList.get(0).LSC_SyncedWithSAP__c = true;
        accountList.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accountList;

        List<Contact> contactList = LSC_TestDataFactory.createContact(1, accountList.get(0));
        insert contactList;

        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accountList.get(0), contactList.get(0));
        insert levyList;

        Map<Id, SObject> items = new Map<Id, SObject>();
        items.put(levyList[0].Id, levyList[0]);

        Test.startTest();
            LSC_LevyTriggerHandler handler = new LSC_LevyTriggerHandler();
            handler.BeforeDelete(items);            
            handler.AfterUpdate(items, items);
            handler.AfterInsert(items);
            handler.AfterDelete(items);
            handler.AfterUndelete(items);
        	handler.isDisabled();
        Test.stopTest();
    }
}