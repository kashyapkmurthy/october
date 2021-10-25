@isTest
private class MyServiceNSWRegHandlerTest {
    @TestSetup
    static void makeData() {
        Id accBusinessRecordTypeId = Account.sObjectType.getDescribe()
        .getRecordTypeInfosByDeveloperName()
        .get('LSC_Business')
        .getRecordTypeId();
        //Business Account
        Account businessAccount = new Account(
            name = 'MyServiceNSW Registration',
            Type = 'Commercial',
            recordTypeId = accBusinessRecordTypeId
        );
        insert businessAccount;
    }

    @isTest
    static void testCreateAndUpdateUser() {
        MyServiceNSWRegHandler handler = new MyServiceNSWRegHandler();
        Auth.UserData sampleData = new Auth.UserData('testId', 'testFirst', 'testLast',
                                                     'testFirst testLast', 'testuse8888r@example.org', null, 'testuse8888r@example.org.qa', 'en_US', 'Open ID Connect',
                                                     null, new Map<String, String>{'language' => 'en_US'});
        Test.startTest();
        User u = handler.createUser(null, sampleData);
        Test.stopTest();  
    
        //System.assertEquals('testuse8888r@example.org.qa', u.userName);
        //System.assertEquals('testuse8888r@example.org', u.email);
    }
}