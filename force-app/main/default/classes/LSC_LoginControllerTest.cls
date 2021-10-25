@isTest
public class LSC_LoginControllerTest {

    @isTest
    public static void getCases() {
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
        UserRoleId = portalRole.Id,
        ProfileId = profile1.Id,
        Username = 'testuser1@test.aaa',
        Alias = 'batman',
        Email='bruce.wayne@wayneenterprises.com',
        EmailEncodingKey='UTF-8',
        Firstname='Bruce',
        Lastname='Wayne',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        TimeZoneSidKey='Australia/Sydney'
        );
        Database.insert(portalAccountOwner1);
        System.runAs(portalAccountOwner1) {
            List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
            insert accounts;
            List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
            insert contacts;
        	Id profileId = [SELECT Id FROM Profile WHERE Name = 'LSC Customer Community Login User'].Id;
            User u = LSC_TestDataFactory.createUser(profileId, 'aaa');
            u.ContactId = contacts[0].Id;
            u.Username = LSC_Utility.constructUsername('testuser@test.aaa');
            insert u;
            
            Test.startTest();
            LSC_LoginController.ResultWrapper rw = LSC_LoginController.communityLogin('testuser@test.aaa', 'P@ssw0rd', null);
            contacts[0].LSC_IsEmailConfirmed__c = true;
            update contacts[0];
            rw = LSC_LoginController.communityLogin('testuser@test.aaa', 'P@ssw0rd', null);
            System.assert(rw.error == 'User with the provided details was not found');        
            rw = LSC_LoginController.emailVerification('testuser@test.aaa');
            rw = LSC_LoginController.emailVerification('testuser@test.aa');
            System.assert(rw.error == 'User with the provided details was not found');      
            LSC_LoginController.VerificationWrapper vw = LSC_LoginController.checkVerification(null);
            System.assert(vw.isError == true);
            contacts[0].LSC_EmailConfirmationLink__c = 'ABCD';
            contacts[0].LSC_StartUrl__c = 'ABCD';
            update contacts[0];
            vw = LSC_LoginController.checkVerification('ABCD');
            System.assert(vw.isVerified == true);  
            contacts[0].LSC_IsEmailConfirmed__c = false;
            update contacts[0];      
            vw = LSC_LoginController.checkVerification('ABCD');
            System.assert(vw.email != null);    
            vw = LSC_LoginController.checkVerification('TABD');
            Test.stopTest();
        }
    }

    @isTest
    public static void getCases1() {
        
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
        UserRoleId = portalRole.Id,
        ProfileId = profile1.Id,
        Username = System.now().millisecond() + 'test2@test.com.au',
        Alias = 'batman',
        Email='bruce.wayne@wayneenterprises.com',
        EmailEncodingKey='UTF-8',
        Firstname='Bruce',
        Lastname='Wayne',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        TimeZoneSidKey='Australia/Sydney'
        );
        Database.insert(portalAccountOwner1);
        
        System.runAs(portalAccountOwner1) {
            List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
            insert accounts;
            List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
            contacts[0].LSC_StartUrl__c = 'ABCD';
            insert contacts;
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'LSC Customer Community Login User'].Id;
            User u = LSC_TestDataFactory.createUser(profileId, 'aaa');
            u.ContactId = contacts[0].Id;
            insert u;
            Test.startTest();        
            contacts[0].LSC_StartUrl__c = 'ABCD';
            update contacts[0];
            LSC_LoginController.ResultWrapper rw = LSC_LoginController.communityLogin('testuser@test.aaa', 'P@ssw0rd', 'ABCD');

            Test.stopTest();
        }
    }

    @isTest
    static void checkIfGuestUser() {
        Boolean isGuestUser = false;
        Test.startTest();
            isGuestUser = LSC_LoginController.checkIfGuestUser();
        Test.stopTest();
        System.assertEquals(isGuestUser, false);
    }
}