@isTest
public class LSC_AccountControllerTest {
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
           
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'LSC Customer Community Login User' LIMIT 1].Id; 
            Account businessNfpAccount = new Account(name = 'BusinessNFPAccount', Type='Not-For-Profit', recordTypeId=accBusinessRecordTypeId, LSC_ABN__c = '43936428523');
            insert businessNfpAccount;
            
            //Testing Perm Set assignment method - insert a community user          
            Contact con = new contact(LastName = 'Businessuser', AccountId = businessNfpAccount.Id, email='greg4568.chapel@gmail.com'); 
            insert con;

            LSC_BusinessDetailsController.upsertACR(businessNfpAccount.Id, con.Id, 'Admin;Director');
            
            User commUser =  new User(Email = 'communityUser1245@gmail.com', UserName = 'communityUser1245@gmail.com', FirstName = 'Peter',
                                      LastName = 'Pan', communityNickname = 'petPan', ProfileId = profileId, ContactId = con.Id, EmailEncodingKey = 'UTF-8',
                                      TimeZoneSidKey = 'Australia/Sydney', Alias = 'petPan',
                                      LocaleSidKey = 'en_AU',
                                      LanguageLocaleKey = 'en_US');
            insert commUser;
            PermissionSetAssignment pmSetAssign = new PermissionSetAssignment(AssigneeId=commUser.Id, PermissionSetId= permissionSetId);
            insert pmSetAssign;
        }
    }
    
    @isTest
    Public static void addBusinessTest(){
        User currentUser = [Select Id from User where email = 'communityUser1245@gmail.com' Limit 1];
        String abnPayload = '{"acncRegistrationStatus": "Registered", "australianBusinessNumber": "84405168482","australianBusinessNumberStatus": "Active","businessName": ["Bayt Al-Zakat Australia"],"charityTypeName": "Charity","effectiveFrom": "2014-05-27","entityName": "Bayt Zakat Charity Inc.","entityTypeCode": "OIE","entityTypeName": "Other Incorporated Entity"}';
        String businessDetailsPayload = '{"abnEntityName":"Bayt Zakat Charity Inc.","phone":"0405060102","email":"oiuwer@iouer.com"}';
        String postalAddressPayload = '{"autoAddress":true,"addressId":"GANSW717010820","city":"BILPIN","country":"AU","fullAddress":"BILPIN OVEL 2526 BELLS LINE OF ROAD, BILPIN NSW 2758","latitude":-33.49039092,"longitude":150.51431592,"postcode":"2758","state":"NSW","street":"BILPIN OVEL 2526 BELLS LINE OF ROAD"}';
        String streetAddressPayload = '{"autoAddress":true,"addressId":"GANSW718456789","city":"ABERDEEN","country":"AU","fullAddress":"ASHFIELD 108 DARTBROOK RD, ABERDEEN NSW 2336","latitude":-32.14308543,"longitude":150.87353519,"postcode":"2336","state":"NSW","street":"ASHFIELD 108 DARTBROOK RD"}';
        System.runAs(currentUser){
            Test.startTest();
            Boolean addBusinessResult = LSC_AccountController.addBusiness(abnPayload, businessDetailsPayload, postalAddressPayload, streetAddressPayload);
            Test.stopTest();     
            //system.assertEquals(true, addBusinessResult,'Added Business Successfully');
        }  
    }
    @isTest
    Public static void addBusinessFailTest(){
        User currentUser = [Select Id from User where email = 'communityUser1245@gmail.com' Limit 1];
        String abnPayload = '{"acncRegistrationStatus": "Registered", australianBusinessNumberStatus": "Active","businessName": ["Bayt Al-Zakat Australia"],"charityTypeName": "Charity","effectiveFrom": "2014-05-27","entityName": "Bayt Zakat Charity Inc.","entityTypeCode": "OIE","entityTypeName": "Other Incorporated Entity"}';
        String businessDetailsPayload = '{"abnEntityName":"Bayt Zakat Charity Inc.","phone":"0405060102","email":"oiuwer@iouer.com"}';
        String postalAddressPayload = '{"autoAddress":true,"addressId":"GANSW717010820","city":"BILPIN","country":"AU","fullAddress":"BILPIN OVEL 2526 BELLS LINE OF ROAD, BILPIN NSW 2758","latitude":-33.49039092,"longitude":150.51431592,"postcode":"2758","state":"NSW","street":"BILPIN OVEL 2526 BELLS LINE OF ROAD"}';
        String streetAddressPayload = '{"autoAddress":true,"addressId":"GANSW718456789","city":"ABERDEEN","country":"AU","fullAddress":"ASHFIELD 108 DARTBROOK RD, ABERDEEN NSW 2336","latitude":-32.14308543,"longitude":150.87353519,"postcode":"2336","state":"NSW","street":"ASHFIELD 108 DARTBROOK RD"}';
        System.runAs(currentUser){
            Test.startTest();
            Boolean addBusinessResult = LSC_AccountController.addBusiness(abnPayload, businessDetailsPayload, postalAddressPayload, streetAddressPayload);
            Test.stopTest();     
            system.assertEquals(false, addBusinessResult,'addBusinessFailTest');
        }  
    }

    @isTest
    Public static void getBusinessDetailsByIdTest(){
        User currentUser = [Select Id from User where email = 'communityUser1245@gmail.com' Limit 1];
        Account accountRec = [Select Id from Account Limit 1];
          System.runAs(currentUser){
            Test.startTest();
           LSC_AccountController.BusinessDetailsWrapper businessDetailsWrapper = LSC_AccountController.getBusinessDetailsById(accountRec.Id);
            Test.stopTest(); 
            system.assertEquals(businessDetailsWrapper.Id, accountRec.Id,'Business Account Exists');
        }  
    }
    
    @isTest
    Public static void getRelatedContactsByIdTest(){
        User currentUser = [Select Id from User where email = 'communityUser1245@gmail.com' Limit 1];
        Account accountRec = [Select Id from Account Limit 1];
          System.runAs(currentUser){
            Test.startTest();
            String newBusinessContact ='{"roles":"Director;Admin","isUser":true,"recContact":{"FirstName":"HiBusiness","LastName":"Test","Phone":"0412345678","Email":"HiBusinessTest@yopmail.com","AccountId":'+'\"'+accountRec.Id+'\"'+'},"activateUser":false,"inviteUser":false}';
            LSC_BusinessDetailsController.addNewBusinessContact(newBusinessContact);
            List<LSC_AccountController.BusinessDetailsContactWrapper> lstBusinessDetailContacts = LSC_AccountController.getRelatedContactsById(accountRec.Id);
            Test.stopTest(); 
            system.assertEquals(2, lstBusinessDetailContacts.size(),'Business Details Contacts Exists');
        }  
    }
    @isTest
    Public static void processBusinessDetailsTest(){
        User currentUser = [Select Id from User where email = 'communityUser1245@gmail.com' Limit 1];
        Account accountRec = [Select Id from Account Limit 1];
          System.runAs(currentUser){
            Test.startTest();
            String strPostalAddress='{"autoAddress":true,"addressId":"GANSW705312945","city":"MARSDEN PARK","country":"AU","fullAddress":"MARSDEN PARK PUBLIC SCHOOL 363 GARFIELD RD WEST, MARSDEN PARK NSW 2765","latitude":-33.69642506,"longitude":150.83362142,"postcode":"2765","state":"NSW","street":"MARSDEN PARK PUBLIC SCHOOL 363 GARFIELD RD WEST"}';
            try{
                String updateStatus = LSC_AccountController.processBusinessDetails(JSON.serialize(''));
            }Catch(Exception ex){
                System.assert(ex.getMessage().contains('Error updating Business Details'),'Exception while updating Business Details');
            }
            
            LSC_AccountController.BusinessDetailsWrapper businessDetailsWrapper = LSC_AccountController.getBusinessDetailsById(accountRec.Id);
            String updateStatus = LSC_AccountController.processBusinessDetails(JSON.serialize(businessDetailsWrapper));
            Test.stopTest(); 
            system.assertEquals('Business details updated Successfully', updateStatus,'Business Details Updated successfully');
        }  
    }

    
}