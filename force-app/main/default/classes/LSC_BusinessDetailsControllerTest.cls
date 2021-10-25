@isTest
public class LSC_BusinessDetailsControllerTest {
    static final String USER_EMAIL1 = 'greg1234.chapel@yopmail.com';
    static final String USER_EMAIL2 = 'greg4567.chapel@yopmail.com';
    @testSetup static void setup() {
        Id sysAdminprofileId = [Select Id from Profile where Profile.Name = 'System Administrator'].Id;
        Id userRleId = [Select Id from UserRole where DeveloperName='LSC_Director'].Id;
        User sysAdmn = new User( email='john.doe@gmail.com',
                                profileid = sysAdminprofileId, 
                                UserName='john.doe7549@gmail.com'+'.test', 
                                Alias = 'GCL',
                                FirstName = 'John',
                                LastName = 'Doe',
                                userRoleId = userRleId,        
                                EmailEncodingKey = 'UTF-8',
                                TimeZoneSidKey = 'Australia/Sydney',
                                LocaleSidKey = 'en_AU',
                                LanguageLocaleKey = 'en_US');  
        insert sysAdmn;
        System.runAs(sysAdmn){        
            Id accIndividualRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Individual').getRecordTypeId();
            Id accBusinessRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Business').getRecordTypeId();
            Id permissionSetId = [Select Id from PermissionSet where Name='LSC_BCILevyUser'].Id;
            List<Account> accountList = LSC_TestDataFactory.createAccounts(2);
            accountList[0].LSC_ABN__c = '43936428523';
            accountList[0].recordTypeId = accBusinessRecordTypeId;
            accountList[1].LSC_ABN__c = '84405168480';
            accountList[1].recordTypeId = accBusinessRecordTypeId;
            insert accountList;
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'LSC Customer Community Login User' LIMIT 1].Id; 
            
            
            String username1 = LSC_Utility.constructUsername(USER_EMAIL1);
            String username2 = LSC_Utility.constructUsername(USER_EMAIL2);
            Contact con1 = new contact(LastName = 'Businessuser', AccountId = accountList[0].Id, email = USER_EMAIL1); 
            Contact con2 = new contact(LastName = 'Businessuser', AccountId = accountList[1].Id, email = USER_EMAIL2); 
            
            insert new List<Contact>{con1,con2};
                
                LSC_BusinessDetailsController.upsertACR(accountList[0].Id, con1.Id, 'Admin;Director');
            
           
            User commUser1 =  new User(Email = USER_EMAIL1, UserName = username1, FirstName = 'Peter',
                                       LastName = 'Pan', communityNickname = 'petPan', ProfileId = profileId, ContactId = con1.Id, EmailEncodingKey = 'UTF-8',
                                       TimeZoneSidKey = 'Australia/Sydney', Alias = 'petPan',
                                       LocaleSidKey = 'en_AU',
                                       LanguageLocaleKey = 'en_US');
            
            
            User commUser2 =  new User(Email = USER_EMAIL2, UserName = username2, FirstName = 'Peter',
                                       LastName = 'Pan', communityNickname = 'petPan1', ProfileId = profileId, ContactId = con2.Id, EmailEncodingKey = 'UTF-8',
                                       TimeZoneSidKey = 'Australia/Sydney', Alias = 'petPa1',
                                       LocaleSidKey = 'en_AU',
                                       LanguageLocaleKey = 'en_US');
            
            insert new List<User>{commUser1,commUser2};
                
                PermissionSetAssignment pmSetAssign1 = new PermissionSetAssignment(AssigneeId=commUser1.Id, PermissionSetId= permissionSetId);
            PermissionSetAssignment pmSetAssign2 = new PermissionSetAssignment(AssigneeId=commUser2.Id, PermissionSetId= permissionSetId);
            insert new List<PermissionSetAssignment>{pmSetAssign1,pmSetAssign2};
                }
    }
    
    @isTest
    Public static void addNewBusinessContactNegativeTest(){
        User currentUser = [Select Id from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        Account accountRec = [Select Id from Account WHERE LSC_ABN__c = '43936428523' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            try{
                String newBusinessContact ='{"roles":"Director;Admin","isUser":true,"recContact":{"FirstName":"HiBusiness","LastName":"Test","Phone":"0412345678","Email":"HiBusinessTest@yopmail.com","AccountId":'+accountRec.Id+'},"activateUser":false,"inviteUser":false}';
                LSC_BusinessDetailsController.addNewBusinessContact(newBusinessContact);
            }catch(Exception ex){
                System.assert(ex.getMessage().contains('Error while adding Business Contact'),'Exception while add Business Contact');
            }
            LSC_BusinessDetailsController.UserDetailsWrapper udWrapper1 = LSC_BusinessDetailsController.verifyUserLinkWithABN('greg1234.chapel@yopmail.com', '43936428523', accountRec.Id);
            Test.stopTest();
            System.assertEquals(true, udWrapper1.isUserPartOfSameABN,'User Part of the Same ABN');
        }  
    }
    
    @isTest
    Public static void deactivateBusinessContactTest(){
        User currentUser = [Select Id from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        Account accountRec = [Select Id from Account Limit 1];
        Contact contactRec = [Select Id from Contact WHERE email='greg1234.chapel@yopmail.com' Limit 1 ];
        System.runAs(currentUser){
            Test.startTest();
            List<LSC_AccountController.BusinessDetailsContactWrapper> lstBusinessDetailContacts = LSC_AccountController.getRelatedContactsById(accountRec.Id);
            system.debug(lstBusinessDetailContacts.size());
            String strBusinessContact ='{"abn":"43936428523","acrUserId":'+'\"'+currentUser.Id+'\"'+',"activateUser":false,"hasUser":true,"id":"07k5O000003KH58QAG","isAdmin":true,"isDirector":true,"isLoggedInUser":false,"isUser":false,"key":"1969","recContact":{"Id":'+'\"'+contactRec.Id+'\"'+',"LastName":"Test","Email":"oritest@yopmail.com","AccountId":'+'\"'+accountRec.Id+'\"'+',"FirstName":"Ori","Phone":"04123456789"},"roles":"Director;Admin"}';
            LSC_BusinessDetailsController.deactivateBusinessContact(accountRec.Id, strBusinessContact);
            lstBusinessDetailContacts = LSC_AccountController.getRelatedContactsById(accountRec.Id);
            Test.stopTest();
        }  
    }
    
    
    @isTest
    Public static void addNewBusinessContactPosittiveTest(){
        User currentUser = [Select Id from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        Account accountRec = [SELECT Id from Account WHERE LSC_ABN__C ='43936428523' Limit 1];
        Contact contactRec = [Select Id from Contact WHERE AccountId = : accountRec.Id  Limit 1 ];
         System.runAs(currentUser){
            Test.startTest();
            String newBusinessContact ='{"roles":"Director;Admin","isUser":true,"recContact":{"FirstName":"HiBusiness","LastName":"Test","Phone":"0412345678","Email":"HiBusinessTest@yopmail.com","AccountId":'+'\"'+accountRec.Id+'\"'+'},"activateUser":false,"inviteUser":false}';
            LSC_BusinessDetailsController.addNewBusinessContact(newBusinessContact);
            LSC_BusinessDetailsController.UserDetailsWrapper udWrapper1 = LSC_BusinessDetailsController.verifyUserLinkWithABN('greg4567.chapel@yopmail.com', '43936428523', accountRec.Id);
            Test.stopTest();
        }  
    }
    
    @isTest
    Public static void processBusinessDetailsContactsPositiveTest(){
        User currentUser = [Select Id from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        Account accountRec = [Select Id from Account Limit 1];
        Contact contactRec = [Select Id from Contact WHERE email='greg1234.chapel@yopmail.com' Limit 1 ];
        System.runAs(currentUser){
            Test.startTest();
            List<LSC_AccountController.BusinessDetailsContactWrapper> lstBusinessDetailContacts = LSC_AccountController.getRelatedContactsById(accountRec.Id);
            LSC_BusinessDetailsController.processBusinessDetailsContacts(accountRec.Id, JSON.serialize(lstBusinessDetailContacts));
            Test.stopTest();
        }  
    }
    
    @isTest
    Public static void processBusinessDetailsContactsNegativeTest(){
        User currentUser = [Select Id from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        Account accountRec = [Select Id from Account Limit 1];
        Contact contactRec = [Select Id from Contact WHERE email='greg1234.chapel@yopmail.com' Limit 1 ];
        System.runAs(currentUser){
            Test.startTest();
            List<LSC_AccountController.BusinessDetailsContactWrapper> lstBusinessDetailContacts = LSC_AccountController.getRelatedContactsById(accountRec.Id);
            system.debug(lstBusinessDetailContacts.size());
            String newBusinessContact = '{"roles":"Director","isUser":false,"recContact":{"Id":'+'\"'+contactRec.Id+'\"'+',"FirstName":"HiBusiness","LastName":"Test","Phone":"0412345678","Email":"HiBusinessTest@yopmail.com","AccountId":'+'\"'+accountRec.Id+'\"'+'},"activateUser":true,"inviteUser":false}';
            LSC_BusinessDetailsController.addNewBusinessContact(newBusinessContact);
            LSC_BusinessDetailsController.processBusinessDetailsContacts(accountRec.Id, newBusinessContact);
            Test.stopTest();
        }  
    }
    
     
    @isTest
    Public static void accountInviteTest(){
        User currentUser = [Select Id from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        Account accountRec = [SELECT Id from Account WHERE LSC_ABN__C ='84405168480' Limit 1];
        Contact contactRec = [Select Id from Contact WHERE AccountId = : accountRec.Id  Limit 1 ];
        System.runAs(currentUser){
            Test.startTest();
            String newBusinessContact = '{"roles":"Admin","isUser":false,"recContact":{"Id":'+'\"'+contactRec.Id+'\"'+',"FirstName":"HiBusiness","LastName":"Test","Phone":"0412345678","Email":"HiBusinessTest@yopmail.com","AccountId":'+'\"'+accountRec.Id+'\"'+'},"activateUser":false,"inviteUser":true}';
            LSC_BusinessDetailsController.addNewBusinessContact(newBusinessContact);
            LSC_BusinessDetailsController.addNewBusinessContact(newBusinessContact);// Retry Same Username for invite from UI 
            Test.stopTest();
        }  
    }
    
    @isTest
    Public static void getAccountInviteDetailsTest(){
        
        User currentUser = [Select Id from User where email = 'greg4567.chapel@yopmail.com' Limit 1];
        Account accountRec = [SELECT Id from Account WHERE LSC_ABN__C ='43936428523' Limit 1];
        Contact contactRec = [Select Id from Contact WHERE AccountId = : accountRec.Id  Limit 1 ];
        LSC_AccountInvite__c aiRec = new LSC_AccountInvite__c (LSC_AccountId__c=accountRec.id,LSC_ContactId__c=contactRec.id,LSC_Email__c ='greg4567.chapel@yopmail.com',LSC_Roles__c='Admin;Director',LSC_Secret_Id__c='423854');
        insert aiRec;
        System.runAs(currentUser){
            Test.startTest();
            LSC_BusinessDetailsController.getAccountInviteDetails(aiRec.Id);
            LSC_BusinessDetailsController.acceptInvite(aiRec.Id, aiRec.LSC_Secret_Id__c);
            Test.stopTest();
        }  
    }
    
    
    
    
    
}