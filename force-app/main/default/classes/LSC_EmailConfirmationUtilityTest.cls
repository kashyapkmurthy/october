@isTest
public class LSC_EmailConfirmationUtilityTest {
    @isTest
    public static void getCases() {
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        insert contacts;
        Test.startTest();
        String s = LSC_EmailConfirmationUtility.generateEmailId();
        System.assert(s.length() == 30);
        Messaging.SingleEmailMessage message = LSC_EmailConfirmationUtility.prepareEmail(contacts[0].Id);
        System.assert(message != null);
        Test.stopTest();
    }
}