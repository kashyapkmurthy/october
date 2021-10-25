@isTest
private class LSC_UserController_Test {
    @testSetup 
    static void setup() {
        User guestUser;
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
            Id accBusinessRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Business').getRecordTypeId();
            Id accIndividualRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Individual').getRecordTypeId();
            Id permissionSetId = [Select Id from PermissionSet where Name='LSC_BCILevyUser'].Id;
            List<Account> accountList = LSC_TestDataFactory.createAccounts(1);
            Account businessAccount = new Account(name = 'BusinessAccount', Type='Commercial',LSC_ABN__c = '43936428523', recordTypeId=accBusinessRecordTypeId);
            Account individualAccount = new Account(name = 'IndividualAccount', recordTypeId=accIndividualRecordTypeId);
            insert new List<Account>{businessAccount,individualAccount};
            
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'LSC Customer Community Login User' LIMIT 1].Id; 
                
            Contact businessContact   = new contact(LastName = 'BusinessUser', AccountId = businessAccount.Id, email='greg1234.chapel@yopmail.com'); 
            Contact individualContact = new contact(LastName = 'Individualuser', AccountId = individualAccount.Id, email='greg.chapelindividual@gmail.com'); 
              
            insert new List<Contact>{businessContact,individualContact};

            LSC_BusinessDetailsController.upsertACR(businessAccount.Id, businessContact.Id, 'Admin;Director');
            AccountContactRelation acrInd = [Select Id, LSC_IsLevyPayer__c from AccountContactRelation where ContactId =: individualContact.Id];
            acrInd.LSC_IsLevyPayer__c = true;
            update acrInd;
            
            User businessUser =  new User(Email = 'greg1234.chapel@yopmail.com', UserName = 'greg1234.chapel@yopmail.com', FirstName = 'Peter',
                                        LastName = 'Pan', communityNickname = 'petPan', ProfileId = profileId, ContactId = businessContact.Id, EmailEncodingKey = 'UTF-8',
                                        TimeZoneSidKey = 'Australia/Sydney', Alias = 'petPan',
                                        LocaleSidKey = 'en_AU',
                                        LanguageLocaleKey = 'en_US');

            User individualUser = new User( email='greg.chapelindividual@gmail.com',
            profileid = profileId, 
            UserName='greg.chapelindividual@gmail.com'+'.test7654', 
            Alias = 'GCLind',
            ContactId = individualContact.Id,
            FirstName = 'Greg',
            LastName = 'Chapelind',EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_AU',
            LanguageLocaleKey = 'en_US');    

            insert new List<User>{businessUser,individualUser};
            PermissionSetAssignment pmSetAssign1 = new PermissionSetAssignment(AssigneeId=businessUser.Id, PermissionSetId= permissionSetId);
            insert new List<PermissionSetAssignment>{pmSetAssign1};
        }
    }


    @isTest
    private static void getUserProfileDataBusinessTest() {
        User businessUser = [Select Id from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        System.runAs(businessUser){
            Test.startTest();
            LSC_UserController.UserDataWrapper userData = LSC_UserController.getUserProfileData();
            Test.stopTest();  
            system.assertEquals(false,userData.isIndividual);
        }  
    }
    
    @isTest
    private static void updateUserProfileDataIndividualTest() {
        User individualUser = [Select Id from User where email = 'greg.chapelindividual@gmail.com' Limit 1];
        System.runAs(individualUser){
            Test.startTest();
            LSC_UserController.UserDataWrapper userData = LSC_UserController.getUserProfileData();
            userData.phone = '0444444444';
            userData.firstName = 'unitTestFirstName';
            userData.lastName = 'unitTestLastName';
            userData.mailingAddress.street = '100 UnitTest Coverage';
            String userProfileUpdateStatus = LSC_UserController.updateUserProfile(JSON.serialize(userData));
            
            Test.stopTest();  
            Contact con =[Select Id,Phone,Account.BillingStreet from Contact where id =: userData.contactId];
            system.assertEquals(null,userProfileUpdateStatus);
            system.assertEquals('0444444444',con.Phone);
            system.assertEquals('100 UnitTest Coverage', con.Account.BillingStreet);
        }  
    }  

    @isTest
    private static void updateUserProfileDataBusinessTest() {
        User individualUser = [Select Id from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        System.runAs(individualUser){
            Test.startTest();
            LSC_UserController.UserDataWrapper userData = LSC_UserController.getUserProfileData();
            userData.phone = '0444444445';
            userData.firstName = 'unitTestFirstName';
            userData.lastName = 'unitTestLastName';
            String userProfileUpdateStatus = LSC_UserController.updateUserProfile(JSON.serialize(userData));
            
            Test.stopTest();  
            Contact con =[Select Id,Phone,Account.BillingStreet from Contact where id =: userData.contactId];
            system.assertEquals('User details updated Successfully',userProfileUpdateStatus);
            system.assertEquals('0444444445',con.Phone);
        }  
    } 
    
    @isTest
    private static void logoutSNSWUserTest() {
        User businessUser = [Select Id from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        businessUser.LSC_Registration_Type__c = 'SNSW';
        update businessUser;

        MockHttpResponseGenerator response = new MockHttpResponseGenerator();
        System.runAs(businessUser){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, MockHttpResponseGenerator.jsonDelete200Ok());
            LSC_UserController.logoutSNSWUser();
            Test.stopTest();  
        }  
    }

    @isTest
    private static void logoutSNSWUserExceptionTest() {
        User businessUser = [Select Id from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        businessUser.LSC_Registration_Type__c = 'SNSW';
        update businessUser;

        MockHttpResponseGenerator response = new MockHttpResponseGenerator();
        System.runAs(businessUser){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, MockHttpResponseGenerator.jsonDelete400Exception());
            try {
                LSC_UserController.logoutSNSWUser();
            } catch (AuraHandledException e) {
                System.assertEquals(e.getMessage(), 'Error occurred while calling SNSW logout service.');
            }
            
            Test.stopTest();  
        }  
    }
    
}