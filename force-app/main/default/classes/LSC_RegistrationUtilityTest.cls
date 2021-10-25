@isTest
public class LSC_RegistrationUtilityTest {  
    static final String COMM_USER_Email = 'communityUser1245@gmail.com';
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
            Account businessNfpAccount = new Account(name = 'BusinessNFPAccount', Type='Not-For-Profit', recordTypeId=accBusinessRecordTypeId, LSC_ABN__c = '43936428523');
            insert businessNfpAccount;
            
            //Testing Perm Set assignment method - insert a community user          
            Contact con = new contact(LastName = 'Businessuser', AccountId = businessNfpAccount.Id, email='greg4568.chapel@gmail.com'); 
            insert con;
            
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'LSC Customer Community Login User' LIMIT 1].Id; 
            
            String username = LSC_Utility.constructUsername(COMM_USER_Email);
            User commUser =  new User(Email = COMM_USER_Email, UserName = username, FirstName = 'Peter',
                                      LastName = 'Pan', communityNickname = 'petPan', ProfileId = profileId, ContactId = con.Id, EmailEncodingKey = 'UTF-8',
                                      TimeZoneSidKey = 'Australia/Sydney', Alias = 'petPan',
                                      LocaleSidKey = 'en_AU',
                                      LanguageLocaleKey = 'en_US');
            insert commUser;
            
            
            AccountContactRelation acr = [SELECT Id, AccountId, ContactId, Roles FROM AccountContactRelation WHERE AccountId =: businessNfpAccount.Id AND ContactId =: con.Id LIMIT 1];
            acr.Roles = 'Admin';
            update acr;
            
            //Data for testing existing User registration
            Account nswAccount = new Account(name = 'MyServiceNSW Registration', Type='Commercial', recordTypeId=accBusinessRecordTypeId);
            insert nswAccount;
            
            Contact conRec = new Contact(LastName = 'sumo10@yopmail.com', email = 'sumo10@yopmail.com', LSC_InCompleteRegistration__c = true, accountId = nswAccount.Id);
            insert conRec;
            
            User userRec = new User(LastName = 'sumo10@yopmail.com', email = 'sumo10@yopmail.com', Username = 'sumo10@yopmail.com', alias='sumo10',
                                   profileId = profileId, contactId = conRec.Id, languagelocalekey = 'en_US', localesidkey = 'en_AU', emailEncodingKey = 'UTF-8', timeZoneSidKey = 'Australia/Sydney');
            insert userRec;
        }

       Id guestUserProfile = [Select Id from Profile where Profile.Name = 'BCI Profile'].Id;
       User guestUser = new User( email='admincorp@gmail.com',
                           profileid = guestUserProfile, 
                           UserName='greg.chapel@gmail.com'+'.test', 
                           Alias = 'GCL',
                           FirstName = 'Greg',
                           LastName = 'Chapel',       
                               EmailEncodingKey = 'UTF-8',
                               TimeZoneSidKey = 'Australia/Sydney',
                               LocaleSidKey = 'en_AU',
                               LanguageLocaleKey = 'en_US');  
        insert guestUser;
    }
    
    @isTest
    Public static void checkAccountsTestABNFound(){
        User currentUser = [Select Id from User where email = 'admincorp@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Map<String, String> abnResult = LSC_RegistrationUtility.checkABNonAccounts('43936428523');
            Test.stopTest();     
            system.assertEquals('yes', abnResult.get('matched'));
        }  
    }
    
    @isTest
    Public static void checkAccountsTestABNNtFound(){
        User currentUser = [Select Id from User where email = 'admincorp@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Map<String, String> abnResult = LSC_RegistrationUtility.checkABNonAccounts('43936426523');
            Test.stopTest();  
            system.assertEquals('no', abnResult.get('matched'));
        }  
    }
    
    @isTest
    public static void validateUsernameTest() {
        User currentUser = [Select Id from User where email = 'admincorp@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Boolean userFound = LSC_RegistrationUtility.validateUsername('jarrodmarrsi1245@yopmail.com');
            Test.stopTest();  
            system.assertEquals(false, userFound);
        }  
    }  
    
    @isTest
    public static void validateUsernameNtFoundTest() {
        User currentUser = [Select Id from User where email = 'admincorp@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Boolean commUserFound = LSC_RegistrationUtility.validateUsername('greg.chapel@gmail.com.test');
            Test.stopTest();  
            system.assertEquals(false, commUserFound);
        }  
    }    

    @isTest
    public static void updateUsernameTest() {
        User commUser = [Select Id, Username, Email from User where email =: COMM_USER_Email Limit 1];
        commUser.Username = LSC_Utility.constructUsername(commUser.Email) + LSC_Utility.SNSW_INCOMPLETED_SUFFIX;
        update commUser;
        System.runAs(commUser){
            Boolean isUpdated = false;
            Test.startTest();
            isUpdated = LSC_RegistrationUtility.updateUsername(commUser.Id);
            Test.stopTest();  
            //system.assertEquals(true, isUpdated);
        }  
    }   
    
    @isTest
    public static void createBusinessAccountandContactTest() {
        User currentUser = [Select Id from User where email = 'admincorp@gmail.com' Limit 1];
        String payload = '{"registrationType":"Business","abnDetails":{"australianBusinessNumber":"82097985558","australianBusinessNumberStatus":"Active","australianCompanyName":"097985558","effectiveFrom":"2001-09-12","entityName":"JOHN PTY LTD","entityTypeCode":"PRV","entityTypeName":"Australian Private Company"},"postalAddress":{"addressId":"GANSW704607073","city":"DULWICH HILL","country":"AU","fullAddress":"MARS BRIDGE UNIT 10 3 WILLIAMS PDE, DULWICH HILL NSW 2203","latitude":-33.9028141,"longitude":151.13792382,"postcode":"2203","state":"NSW","street":"MARS BRIDGE UNIT 10 3 WILLIAMS PDE","autoAddress":true},"streetAddress":{"addressId":"GANSW716441737","city":"GUM FLAT","country":"AU","fullAddress":"ASHGLEN 500 HAVILAH PARK RD, GUM FLAT NSW 2360","latitude":-29.76944314,"longitude":150.93602797,"postcode":"2360","state":"NSW","street":"ASHGLEN 500 HAVILAH PARK RD","autoAddress":true},"businessPageDetails":{"abnEntityName":"JOHN PTY LTD","phone":"0298765432","email":"johnptyltd123@yopmail.com"},"contactPageDetails":{"givenName":"John","surName":"Ptyltd","phone":"0405603212","email":"johnptylts@yopmail.com"},"emailValidated":true,"password":"User@123","declaration":true}';
        System.runAs(currentUser){
            Test.startTest();
            Map<string, Object> resultMap = LSC_RegistrationUtility.createAccountContact(payload);
            Test.stopTest();  
            //system.assertEquals(true, resultMap.get('result'));
        }  
    }    

    @isTest
    public static void createIndividualAccountandContactTest() {
        User currentUser = [Select Id from User where email = 'admincorp@gmail.com' Limit 1];
        String payload = '{"registrationType":"Individual","contactPageDetails":{"givenName":"John","surName":"Pal","phone":"0403020101","email":"john.pal563847@yopmail.com"},"postalAddress":{"addressId":"GANSW718456789","city":"ABERDEEN","country":"AU","fullAddress":"ASHFIELD 108 DARTBROOK RD, ABERDEEN NSW 2336","latitude":-32.14308543,"longitude":150.87353519,"postcode":"2336","state":"NSW","street":"ASHFIELD 108 DARTBROOK RD","autoAddress":true},"emailValidated":true,"password":"User@123","declaration":true}';
        System.runAs(currentUser){
            Test.startTest();
            Map<string, Object> resultMap = LSC_RegistrationUtility.createAccountContact(payload);
            Test.stopTest();  
            //system.assertEquals(true, resultMap.get('result'));
        }  
    }     
    
    @isTest
    public static void createBusinessAccountandContactFailureTest() {
        User currentUser = [Select Id from User where email = 'admincorp@gmail.com' Limit 1];
        String payload = '{"registrationType":"Business","abnDetails":{"australianBusinessNumberStatus":"Active","australianCompanyName":"097985558","effectiveFrom":"2001-09-12","entityName":"JOHN PTY LTD","entityTypeCode":"PRV","entityTypeName":"Australian Private Company"},"postalAddress":{"addressId":"GANSW704607073","city":"DULWICH HILL","country":"AU","fullAddress":"MARS BRIDGE UNIT 10 3 WILLIAMS PDE, DULWICH HILL NSW 2203","latitude":-33.9028141,"longitude":151.13792382,"postcode":"2203","state":"NSW","street":"MARS BRIDGE UNIT 10 3 WILLIAMS PDE","autoAddress":true},"streetAddress":{"addressId":"GANSW716441737","city":"GUM FLAT","country":"AU","fullAddress":"ASHGLEN 500 HAVILAH PARK RD, GUM FLAT NSW 2360","latitude":-29.76944314,"longitude":150.93602797,"postcode":"2360","state":"NSW","street":"ASHGLEN 500 HAVILAH PARK RD","autoAddress":true},"businessPageDetails":{"abnEntityName":"JOHN PTY LTD","phone":"0298765432","email":"johnptyltd123@yopmail.com"},"contactPageDetails":{"givenName":"John","surName":"Ptyltd","phone":"0405603212","email":"johnptylts@yopmail.com"},"emailValidated":true,"password":"User@123","declaration":true}';
        System.runAs(currentUser){
            Test.startTest();
            Map<string, Object> resultMap = LSC_RegistrationUtility.createAccountContact(payload);
            Test.stopTest();  
            system.assertEquals(false, resultMap.get('result'));
        }  
    }   
    
    @isTest
    public static void createIndividualAccountandContactFailureTest() {
        User currentUser = [Select Id from User where email = 'admincorp@gmail.com' Limit 1];
        String payload = '{"registrationType":"Individual","contactPageDetails":{"givenName":"John","phone":"0403020101","email":"john.pal563847@yopmail.com"},"postalAddress":{"addressId":"GANSW718456789","city":"ABERDEEN","country":"AU","fullAddress":"ASHFIELD 108 DARTBROOK RD, ABERDEEN NSW 2336","latitude":-32.14308543,"longitude":150.87353519,"postcode":"2336","state":"NSW","street":"ASHFIELD 108 DARTBROOK RD","autoAddress":true},"emailValidated":true,"password":"User@123","declaration":true}';
        System.runAs(currentUser){
            Test.startTest();
            Map<string, Object> resultMap = LSC_RegistrationUtility.createAccountContact(payload);
            Test.stopTest();  
            system.assertEquals(false, resultMap.get('result'));
        }  
    }
    
    @isTest
    public static void assignPermissionSetTest() {
        User currentUser = [Select Id from User where email = 'admincorp@gmail.com' Limit 1];
        Id commUserId = [Select Id from User where email = 'communityUser1245@gmail.com' Limit 1].Id;
        String payload = '{"registrationType":"Business","abnDetails":{"australianBusinessNumber":"82097985558","australianBusinessNumberStatus":"Active","australianCompanyName":"097985558","effectiveFrom":"2001-09-12","entityName":"JOHN PTY LTD","entityTypeCode":"PRV","entityTypeName":"Australian Private Company"},"postalAddress":{"addressId":"GANSW704607073","city":"DULWICH HILL","country":"AU","fullAddress":"MARS BRIDGE UNIT 10 3 WILLIAMS PDE, DULWICH HILL NSW 2203","latitude":-33.9028141,"longitude":151.13792382,"postcode":"2203","state":"NSW","street":"MARS BRIDGE UNIT 10 3 WILLIAMS PDE","autoAddress":true},"streetAddress":{"addressId":"GANSW716441737","city":"GUM FLAT","country":"AU","fullAddress":"ASHGLEN 500 HAVILAH PARK RD, GUM FLAT NSW 2360","latitude":-29.76944314,"longitude":150.93602797,"postcode":"2360","state":"NSW","street":"ASHGLEN 500 HAVILAH PARK RD","autoAddress":true},"businessPageDetails":{"abnEntityName":"JOHN PTY LTD","phone":"0298765432","email":"johnptyltd123@yopmail.com"},"contactPageDetails":{"givenName":"John","surName":"Ptyltd","phone":"0405603212","email":"johnptylts@yopmail.com"},"emailValidated":true,"password":"User@123","declaration":true}';
        Boolean assignPermSetResult = false;
        
        System.runAs(currentUser){
            Test.startTest();
            assignPermSetResult = LSC_RegistrationUtility.assignPermissionSet(commUserId);
            Test.stopTest();  
            system.assertEquals(true, assignPermSetResult);
        }  
    }  
    
    @isTest //Existing User Registration Test
    public static void existingUserRegistrationTest() {
        User currentUser = [Select Id from User where email = 'sumo10@yopmail.com' Limit 1];
        String payload = '{"registrationType":"Business","abnDetails":{"australianBusinessNumber":"82097985558","australianBusinessNumberStatus":"Active","australianCompanyName":"097985558","effectiveFrom":"2001-09-12","entityName":"JOHN PTY LTD","entityTypeCode":"PRV","entityTypeName":"Australian Private Company"},"postalAddress":{"addressId":"GANSW704607073","city":"DULWICH HILL","country":"AU","fullAddress":"MARS BRIDGE UNIT 10 3 WILLIAMS PDE, DULWICH HILL NSW 2203","latitude":-33.9028141,"longitude":151.13792382,"postcode":"2203","state":"NSW","street":"MARS BRIDGE UNIT 10 3 WILLIAMS PDE","autoAddress":true},"streetAddress":{"addressId":"GANSW716441737","city":"GUM FLAT","country":"AU","fullAddress":"ASHGLEN 500 HAVILAH PARK RD, GUM FLAT NSW 2360","latitude":-29.76944314,"longitude":150.93602797,"postcode":"2360","state":"NSW","street":"ASHGLEN 500 HAVILAH PARK RD","autoAddress":true},"businessPageDetails":{"abnEntityName":"JOHN PTY LTD","phone":"0298765432","email":"johnptyltd123@yopmail.com"},"contactPageDetails":{"givenName":"John","surName":"Ptyltd","phone":"0405603212","email":"johnptylts@yopmail.com"},"emailValidated":true,"password":"User@123","declaration":true}';
        System.runAs(currentUser){
            Test.startTest();
            Map<string, Object> resultMap = LSC_RegistrationUtility.createAccountContact(payload);
            Test.stopTest();  
            //system.assertEquals(true, resultMap.get('result'));
        }  
    }   
    
    @isTest 
    public static void checkForRegistrationStatusTest() {
        User currentUser = [Select Id from User where email = 'sumo10@yopmail.com' Limit 1];
       
        System.runAs(currentUser){
            Test.startTest();
            Boolean result = LSC_RegistrationUtility.checkForRegistrationStatus();
            Test.stopTest();  
            system.assertEquals(true, result);
        }  
    }  
    
    @isTest 
    public static void getContactDetailsTest() {
        User currentUser = [Select Id from User where email = 'sumo10@yopmail.com' Limit 1];
       
        System.runAs(currentUser){
            Test.startTest();
            Map<String, Object> resultMap = LSC_RegistrationUtility.getContactDetails();
            Test.stopTest();  
            system.assertEquals('success', resultMap.get('result'));
        }  
    }     
}