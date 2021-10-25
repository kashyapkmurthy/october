@isTest
private class LSC_AbnSwitchController_Test {
    @testSetup 
    static void setup() {
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
                
            Contact con1 = new contact(LastName = 'Businessuser', AccountId = accountList[0].Id, email='greg1234.chapel@yopmail.com'); 
           
            insert new List<Contact>{con1};

            LSC_BusinessDetailsController.upsertACR(accountList[0].Id, con1.Id, 'Admin;Director');
            
            User commUser1 =  new User(Email = 'greg1234.chapel@yopmail.com', UserName = 'greg1234.chapel@yopmail.com', FirstName = 'Peter',
                                        LastName = 'Pan', communityNickname = 'petPan', ProfileId = profileId, ContactId = con1.Id, EmailEncodingKey = 'UTF-8',
                                        TimeZoneSidKey = 'Australia/Sydney', Alias = 'petPan',
                                        LocaleSidKey = 'en_AU',
                                        LanguageLocaleKey = 'en_US');

            insert new List<User>{commUser1};

            PermissionSetAssignment pmSetAssign1 = new PermissionSetAssignment(AssigneeId=commUser1.Id, PermissionSetId= permissionSetId);
            insert new List<PermissionSetAssignment>{pmSetAssign1};
        }
    }

    
    @isTest
    Public static void getDataTest(){
        User currentUser = [Select Id from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        Account accountRec = [Select Id from Account WHERE LSC_ABN__c = '43936428523' Limit 1];
          System.runAs(currentUser){
            Test.startTest();
            LSC_AbnSwitchController.ABNWrapper result = LSC_AbnSwitchController.getData();
            Test.stopTest();
            System.assertEquals(result.currentAbn,accountRec.Id ,'Switched to ABN using ACR');
        }  
    }

    @isTest
    Public static void switchABNPostivieTest(){
        User currentUser = [Select Id,contactId from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        Account accountRec = [Select Id from Account WHERE LSC_ABN__c = '84405168480' Limit 1];
        LSC_BusinessDetailsController.upsertACR(accountRec.Id, currentUser.ContactId, 'Admin;Director');
        System.runAs(currentUser){
        Test.startTest();
        Boolean switchABNStatus = LSC_AbnSwitchController.switchAbn(accountRec.Id);
        LSC_AbnSwitchController.ABNWrapper result = LSC_AbnSwitchController.getData();

        Test.stopTest();
        System.assertEquals(true,switchABNStatus ,'ABN Switch Successful');
        System.assertEquals(result.currentAbn,accountRec.Id ,'Switched to ABN using Selected ABN field on User Record');
        }  
    }

    
    @isTest
    Public static void switchABNNegativeTest(){
        User currentUser = [Select Id,contactId from User where email = 'greg1234.chapel@yopmail.com' Limit 1];
        Account accountRec = [Select Id from Account WHERE LSC_ABN__c = '43936428523' Limit 1];
        System.runAs(currentUser){
        Test.startTest();
        Boolean switchABNNullStatus = LSC_AbnSwitchController.switchAbn(null);
        Boolean switchABNErrorStatus = LSC_AbnSwitchController.switchAbn(currentUser.Id);
        Test.stopTest();
        System.assertEquals(false,switchABNNullStatus ,'ABN Switch Test - NULL Check');
        System.assertEquals(false,switchABNErrorStatus ,'ABN Switch Test - ACR not exist for the ABN');
        }  
    }
}