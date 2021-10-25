@isTest
public class LSC_ContactSupportController_Test {

    @isTest
    public static void contactSupportCreateCaseTest() {
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        insert levyList;

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'LSC Customer Community Login User'].Id;
        User u = LSC_TestDataFactory.createUser(profileId, 'aaa');
        u.ContactId = contacts[0].Id;
        //u.UserRoleId = userRole_1.Id;
        insert u;

        ContentVersion cv = LSC_TestDataFactory.createContent();
        insert cv;
        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId 
            FROM ContentDocument
        ];
        List<String> docIds = new List<String>();
        docIds.add(documents[0].Id);
        test.startTest();
        System.runAs(u){
             LSC_ContactSupportController.createCase(String.valueOf(u.Id), 'General Enquiry', 'General Enquiry', 'General Enquiry', 'General Enquiry', '0444444444', 'testytest1234@yyy.coo.au', docIds);
             LSC_ContactSupportController.createCase(null, 'General Enquiry', 'General Enquiry', 'General Enquiry', 'General Enquiry', '0444444434', 'testytes334@yyy.coo.au', docIds);
        } 
        test.stopTest();
        List<Case> caseList = [SELECT ID FROM CASE];
        System.assertEquals(2, caseList.size());
    }
        
}