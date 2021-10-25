@isTest
public class LSC_LevyPaymentUtilityTest {
	@testSetup static void setup() {
       Id sysAdminprofileId = [Select Id from Profile where Profile.Name = 'System Administrator'].Id;
       Id userRleId = [Select Id from UserRole where DeveloperName='LSC_Director'].Id;
       User sysAdmn = new User( email='admincorp@gmail.com',
                           profileid = sysAdminprofileId, 
                           UserName='greg.chapel@gmail.com'+'.test', 
                           Alias = 'GCL',
                           FirstName = 'Greg',
                           LastName = 'Chapel',
                           userRoleId = userRleId,        
                               EmailEncodingKey = 'UTF-8',
                               TimeZoneSidKey = 'Australia/Sydney',
                               LocaleSidKey = 'en_AU',
                               LanguageLocaleKey = 'en_US');  
        insert sysAdmn;
        System.runAs(sysAdmn){
            Id profileId = [Select Id from Profile where Profile.Name = 'LSC Customer Community Login User'].Id;
            Id accIndividualRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Individual').getRecordTypeId();
            Id accBusinessRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Business').getRecordTypeId();
            //Business Account
            Account businessAccount = new Account(name = 'BusinessAccount', Type='Commercial', recordTypeId=accBusinessRecordTypeId);
            insert businessAccount;
            Contact businessContact = new contact(LastName = 'Businessuser', AccountId = businessAccount.Id, email='greg.chapel@gmail.com', LSC_SelectedAccountId__c = businessAccount.Id); 
            insert businessContact;
            AccountContactRelation acr = [Select Id, LSC_IsLevyPayer__c from AccountContactRelation where ContactId =: businessContact.Id];
            acr.LSC_IsLevyPayer__c = true;
            update acr;
            User u1 = new User( email='greg.chapel@gmail.com',
                               profileid = profileId, 
                               UserName='greg.chapel@gmail.com'+'.test7654', 
                               Alias = 'GCL',
                               ContactId = businessContact.Id,
                               FirstName = 'Greg',
                               LastName = 'Chapel',EmailEncodingKey = 'UTF-8',
                               TimeZoneSidKey = 'Australia/Sydney',
                               LocaleSidKey = 'en_AU',
                               LanguageLocaleKey = 'en_US');    
            insert u1;
            
            //Business Account - nfp
            Account businessNfpAccount = new Account(name = 'BusinessNFPAccount', Type='Not For Profit', recordTypeId=accBusinessRecordTypeId);
            insert businessNfpAccount;
            Contact businessNfpContact = new contact(LastName = 'Businessuser', AccountId = businessNfpAccount.Id, email='greg.chapelnfp@gmail.com'); 
            insert businessNfpContact;
            AccountContactRelation acrNfp = [Select Id, LSC_IsLevyPayer__c from AccountContactRelation where ContactId =: businessNfpContact.Id];
            acrNfp.LSC_IsLevyPayer__c = true;
            update acrNfp;
            User u2 = new User( email='greg.chapelnfp@gmail.com',
                               profileid = profileId, 
                               UserName='greg.chapelnfp@gmail.com'+'.test7654', 
                               Alias = 'GCLnfp',
                               ContactId = businessNfpContact.Id,
                               FirstName = 'Greg',
                               LastName = 'Chapelnfp',EmailEncodingKey = 'UTF-8',
                               TimeZoneSidKey = 'Australia/Sydney',
                               LocaleSidKey = 'en_AU',
                               LanguageLocaleKey = 'en_US');    
            insert u2;
            
            //Individual Account
            Account individualAccount = new Account(name = 'IndividualAccount', recordTypeId=accIndividualRecordTypeId);
            insert individualAccount;
            Contact individualContact = new contact(LastName = 'Individualuser', AccountId = individualAccount.Id, email='greg.chapelindividual@gmail.com'); 
            insert individualContact;
            AccountContactRelation acrInd = [Select Id, LSC_IsLevyPayer__c from AccountContactRelation where ContactId =: individualContact.Id];
            acrInd.LSC_IsLevyPayer__c = true;
            update acrInd;
            User u3 = new User( email='greg.chapelindividual@gmail.com',
                               profileid = profileId, 
                               UserName='greg.chapelindividual@gmail.com'+'.test7654', 
                               Alias = 'GCLind',
                               ContactId = individualContact.Id,
                               FirstName = 'Greg',
                               LastName = 'Chapelind',EmailEncodingKey = 'UTF-8',
                               TimeZoneSidKey = 'Australia/Sydney',
                               LocaleSidKey = 'en_AU',
                               LanguageLocaleKey = 'en_US');    
            insert u3;
            //A sample record for testing Approval lock
            Account apprAcc = new Account(name = 'approvalAccount', recordTypeId=accIndividualRecordTypeId);
            insert apprAcc;
            Approval.lock(apprAcc.Id);
        }
    }
    
 	@isTest
    Public static void getUserAccountInfoTest(){       
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        String documentId = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1].ContentDocumentId;
        ContentDocumentLink newCDL = new ContentDocumentLink(ContentDocumentId = documentId, LinkedEntityId = currentUser.Id);
        System.runAs(currentUser){
            Test.startTest();
            String AccountInfoResult = LSC_LevyPaymentUtility.getUserAccountInfo();
            String docResult = LSC_LevyPaymentUtility.deleteDocument(documentId);
            Test.stopTest();     
            system.assertEquals('Business', AccountInfoResult);
            system.assertEquals('SUCCESS', docResult);
        }
    } 
        
    @isTest
    Public static void getUserNFPAccountInfoTest(){       
        User currentUser = [Select Id from User where email = 'greg.chapelnfp@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            String AccountInfoResult = LSC_LevyPaymentUtility.getUserAccountInfo();
            Test.stopTest();     
            system.assertEquals('Organisation', AccountInfoResult);
        }
    } 
    
    @isTest
    Public static void checkRecordLockedInputNullTest(){       
        User currentUser = [Select Id from User where email = 'greg.chapelnfp@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Boolean recordLock = LSC_LevyPaymentUtility.checkRecordLocked(null);
            Test.stopTest();     
            system.assertEquals(false, recordLock);
        }
    }    
    
    @isTest
    Public static void checkRecordLockedTest(){       
        Id accId = [Select Id from Account where Name = 'approvalAccount'].Id;
        User currentUser = [Select Id from User where email = 'greg.chapelnfp@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Boolean recordLock = LSC_LevyPaymentUtility.checkRecordLocked(accId);
            Test.stopTest();     
            system.assertEquals(true, recordLock);
        }
    }     
    
    @isTest
    Public static void currentUserAccountIdTest(){
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        String AccountId = [Select Id from Account where Name = 'BusinessAccount' Limit 1].Id;
        System.runAs(currentUser){
            Test.startTest();
            String AccIDResult = LSC_LevyPaymentUtility.currentUserAccountId();
            Test.stopTest();
            system.assertEquals(AccountId, AccIDResult);
        }
    } 
    
    @isTest
    Public static void createLevyPaymentBusinessPresetTest(){
        String requestDetails = '{"userJourney":"Business","developmentDetails":{"appNumber":"asdf","startDate":"2025-04-21","endDate":"2027-05-06","appType":"Development Application","govtAuth":"CENTRAL DARLING SHIRE COUNCIL"},"constructionSiteAddress":{"autoAddress":true,"addressId":"GANSW718456789","city":"ABERDEEN","country":"AU","fullAddress":"ASHFIELD 108 DARTBROOK RD, ABERDEEN NSW 2336","latitude":-32.14308543,"longitude":150.87353519,"postcode":"2336","state":"NSW","street":"ASHFIELD 108 DARTBROOK RD"},"developmentCostsDetails":{"totalBuildConstCost":"10000000","levyPayable":"35000.00"},"instalmentCmpDetails":{"givenName":"Swetha","surName":"Kodatham","phone":"0405060201","email":"swthakdoa@gmail.com","payLevyInstal":"yes","instalOption":"presetInstal","primaryContact":"no"},"variableInstalments":[],"presetInstalments":[{"id":0,"payNo":1,"presetInstal":"8750.00","dueDate":"21-04-2021"},{"id":1,"payNo":2,"presetInstal":"8750.00","dueDate":"25-07-2021"},{"id":2,"payNo":3,"presetInstal":"8750.00","dueDate":"28-10-2021"},{"id":3,"payNo":4,"presetInstal":"8750.00","dueDate":"31-01-2022"}],"uploadedFiles":[],"developmentApproval":{"approvingAuthority":"Get Certified","contactName":"adminCorp","phone":"0408050102","email":"admincorp@gmail.com"},"authRepDetails":{"yourRole":"yourRoleBusinessBehalf","givenName":"John","surName":"Doe","phone":"0401020504","email":"johndoe@gmail.com"},"postalAddress":{"autoAddress":true,"addressId":"GANSW717851245","city":"BECKOM","country":"AU","fullAddress":"ASHFIELD 1067 LONDON HILL RD, BECKOM NSW 2665","latitude":-34.4068844,"longitude":146.99660822,"postcode":"2665","state":"NSW","street":"ASHFIELD 1067 LONDON HILL RD"},"declaration":true}';
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Map<String, Object> passResult = LSC_LevyPaymentUtility.createLevyPayment(requestDetails);
            Test.stopTest();
        	system.assertEquals('success', passResult.get('result'));
        }
    } 
  
    @isTest
    Public static void createLevyPaymentBusinessStageTest(){
    	String requestDetails = '{"userJourney":"Business","developmentDetails":{"appNumber":"sdf","startDate":"2025-04-21","endDate":"2027-04-28","appType":"Development Application","govtAuth":"CENTRAL DARLING SHIRE COUNCIL"},"constructionSiteAddress":{"autoAddress":true,"addressId":"GANSW717851245","city":"BECKOM","country":"AU","fullAddress":"ASHFIELD 1067 LONDON HILL RD, BECKOM NSW 2665","latitude":-34.4068844,"longitude":146.99660822,"postcode":"2665","state":"NSW","street":"ASHFIELD 1067 LONDON HILL RD"},"developmentCostsDetails":{"totalBuildConstCost":"10000000","levyPayable":"35000.00"},"instalmentCmpDetails":{"payLevyInstal":"yes","instalOption":"variableInstal","primaryContact":"yes"},"variableInstalments":[{"id":0,"stage":"sdf/1","startDate":"2021-04-29","levyAmt":17500,"showDel":false,"estimatedCost":5000000},{"id":1,"stage":"sdf/2","startDate":"2021-04-30","levyAmt":17500,"showDel":false,"estimatedCost":5000000},{"id":2,"totalCost":10000000,"totalLevyAmt":35000}],"presetInstalments":[],"uploadedFiles":[],"developmentApproval":{},"authRepDetails":{"yourRole":"yourRoleBusinessApplicant"},"declaration":true}';
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Map<String, Object> passResult = LSC_LevyPaymentUtility.createLevyPayment(requestDetails);
            Test.stopTest();
            system.assertEquals('success', passResult.get('result'));
        }
    }
    
    @isTest
    Public static void createLevyPaymentBusinessNoExempTest(){
    	String requestDetails = '{"userJourney":"Business","developmentDetails":{"appNumber":"sdf","startDate":"2021-04-22","endDate":"2022-05-28","appType":"Development Application","govtAuth":"CENTRAL DARLING SHIRE COUNCIL"},"constructionSiteAddress":{"autoAddress":true,"addressId":"GANSW718456789","city":"ABERDEEN","country":"AU","fullAddress":"ASHFIELD 108 DARTBROOK RD, ABERDEEN NSW 2336","latitude":-32.14308543,"longitude":150.87353519,"postcode":"2336","state":"NSW","street":"ASHFIELD 108 DARTBROOK RD"},"developmentCostsDetails":{"totalBuildConstCost":"10000000","levyPayable":"35000.00"},"instalmentCmpDetails":{"payLevyInstal":"no"},"variableInstalments":[],"presetInstalments":[],"uploadedFiles":[],"developmentApproval":{},"authRepDetails":{"yourRole":"yourRoleBusinessApplicant"},"declaration":true}';
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Map<String, Object> passResult = LSC_LevyPaymentUtility.createLevyPayment(requestDetails);
            Test.stopTest();
            system.assertEquals('success', passResult.get('result'));
        }
    }
    
    @isTest
    Public static void createLevyPaymentIndividualExempTest(){
    	String requestDetails = '{"userJourney":"Individual","developmentDetails":{"appNumber":"sdf","startDate":"2021-04-21","endDate":"2021-05-06","appType":"Development Application","govtAuth":"CENTRAL DARLING SHIRE COUNCIL"},"constructionSiteAddress":{"autoAddress":true,"addressId":"GATAS702291748","city":"SANDY BAY","country":"AU","fullAddress":"ASHFIELD 11 MARGARET ST, SANDY BAY TAS 7005","latitude":-42.89733326,"longitude":147.33078992,"postcode":"7005","state":"TAS","street":"ASHFIELD 11 MARGARET ST"},"ownerBuilderDetails":{"licenceID":"1-3JGW6XR","licenceNumber":"460392P","licenceType":"Owner Builder Permit","licensee":"Samuel John Tanner","startDate":"2020-04-09","status":"Current","expiryDate":null},"developmentCostsDetails":{"totalBuildConstCost":"85000","estCostVoluntaryLabor":"45000","levyPayable":"297.00","levyExemptionOption":"yes"},"developmentApproval":{},"authRepDetails":{"yourRole":"yourRoleApplicant"},"declaration":true}';
        User currentUser = [Select Id from User where email = 'greg.chapelindividual@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Map<String, Object> passResult = LSC_LevyPaymentUtility.createLevyPayment(requestDetails);
            Test.stopTest();
            system.assertEquals('success', passResult.get('result'));
        }
    }
    
    //Total cost greater than 500,000
    @isTest
    Public static void createLevyPaymentIndividualExemp1Test(){
    	String requestDetails = '{"userJourney":"Individual","developmentDetails":{"planningPortalNumber":"aaa","appNumber":"ddd","startDate":"2021-05-22","endDate":"2021-05-28","appType":"Development Application","govtAuth":"CENTRAL DARLING SHIRE COUNCIL"},"constructionSiteAddress":{"autoAddress":true,"addressId":"GANSW718456789","city":"ABERDEEN","country":"AU","fullAddress":"ASHFIELD 108 DARTBROOK RD, ABERDEEN NSW 2336","latitude":-32.14308543,"longitude":150.87353519,"postcode":"2336","state":"NSW","street":"ASHFIELD 108 DARTBROOK RD"},"ownerBuilderDetails":{"licenceID":"1-3JGWGTB","licenceNumber":"460391P","licenceType":"Owner Builder Permit","licensee":"Sam Al Maraee","startDate":"2020-04-09","status":"Current","expiryDate":null},"developmentCostsDetails":{"totalBuildConstCost":"500000","estCostVoluntaryLabor":"249999","levyPayable":"875.00","levyExemptionOption":"yes"},"developmentApproval":{},"authRepDetails":{"yourRole":"yourRoleApplicant"},"declaration":true}';
        User currentUser = [Select Id from User where email = 'greg.chapelindividual@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Map<String, Object> passResult = LSC_LevyPaymentUtility.createLevyPayment(requestDetails);
            Test.stopTest();
            system.assertEquals('success', passResult.get('result'));
        }
    }
    
    @isTest
    Public static void createLevyPaymentIndividualNoExempTest(){
    	String requestDetails = '{"userJourney":"Individual","developmentDetails":{"appNumber":"wer","startDate":"2021-05-04","endDate":"2021-05-08","appType":"Development Application","govtAuth":"CENTRAL DARLING SHIRE COUNCIL"},"constructionSiteAddress":{"autoAddress":true,"addressId":"GANSW717851245","city":"BECKOM","country":"AU","fullAddress":"ASHFIELD 1067 LONDON HILL RD, BECKOM NSW 2665","latitude":-34.4068844,"longitude":146.99660822,"postcode":"2665","state":"NSW","street":"ASHFIELD 1067 LONDON HILL RD"},"developmentCostsDetails":{"totalBuildConstCost":"84789","levyPayable":"296.00","levyExemptionOption":"no"},"developmentApproval":{},"authRepDetails":{"yourRole":"yourRoleBehalf","givenName":"John","surName":"sode","phone":"0480874564","email":"johnsode@gmail.com"},"postalAddress":{"autoAddress":true,"addressId":"GANSW717851245","city":"BECKOM","country":"AU","fullAddress":"ASHFIELD 1067 LONDON HILL RD, BECKOM NSW 2665","latitude":-34.4068844,"longitude":146.99660822,"postcode":"2665","state":"NSW","street":"ASHFIELD 1067 LONDON HILL RD"},"declaration":true}';
        User currentUser = [Select Id from User where email = 'greg.chapelindividual@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Map<String, Object> passResult = LSC_LevyPaymentUtility.createLevyPayment(requestDetails);
            Test.stopTest();
            system.assertEquals('success', passResult.get('result'));
        }
    }
    
    @isTest
    Public static void createLevyPaymentBusinessNfpExempTest(){
        String requestDetails = '{"userJourney":"Organisation","developmentDetails":{"appNumber":"sdf","startDate":"2021-04-21","endDate":"2021-04-29","appType":"Development Application","govtAuth":"CENTRAL DARLING SHIRE COUNCIL"},"constructionSiteAddress":{"autoAddress":true,"addressId":"GANSW717132432","city":"CANOWINDRA","country":"AU","fullAddress":"MARSDEN 287 RYGATES LANE, CANOWINDRA NSW 2804","latitude":-33.52924683,"longitude":148.65709328,"postcode":"2804","state":"NSW","street":"MARSDEN 287 RYGATES LANE"},"developmentCostsDetails":{"totalBuildConstCost":"45874","estCostVoluntaryLabor":"5879","levyPayable":"139.00","levyExemptionOption":"yes"},"developmentApproval":{},"declaration":true}';
        User currentUser = [Select Id from User where email = 'greg.chapelnfp@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Map<String, Object> passResult = LSC_LevyPaymentUtility.createLevyPayment(requestDetails);
            Test.stopTest();
        	system.assertEquals('success', passResult.get('result'));
        }
    } 
    
    @isTest
    Public static void createLevyPaymentBusinessNfpNoExempTest(){
        String requestDetails = '{"userJourney":"Organisation","developmentDetails":{"appNumber":"wer","startDate":"2021-04-22","endDate":"2021-04-24","appType":"Development Application","govtAuth":"CENTRAL DARLING SHIRE COUNCIL"},"constructionSiteAddress":{"autoAddress":true,"addressId":"GANSW716893659","city":"QUAKERS HILL","country":"AU","fullAddress":"QUAKERS COURT SHOPPING CENTRE SHOP 11 76 FALMOUTH RD, QUAKERS HILL NSW 2763","latitude":-33.74030124,"longitude":150.88592346,"postcode":"2763","state":"NSW","street":"QUAKERS COURT SHOPPING CENTRE SHOP 11 76 FALMOUTH RD"},"developmentCostsDetails":{"totalBuildConstCost":"45789","levyPayable":"160.00","levyExemptionOption":"no"},"developmentApproval":{},"declaration":true}';
        User currentUser = [Select Id from User where email = 'greg.chapelnfp@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            Map<String, Object> passResult = LSC_LevyPaymentUtility.createLevyPayment(requestDetails);
            Test.stopTest();
        	system.assertEquals('success', passResult.get('result'));
        }
    } 
    
    @isTest
    Public static void createLevyPaymentInvalidPayloadTest(){
        String requestDetails = '{"userJourney":"Organisation","developmentDetails":{"appNumber":"wer","startDate":"2021/04/22","endDate":"2021-04-24","appType":"Development Application","govtAuth":"CENTRAL DARLING SHIRE COUNCIL"},"constructionSiteAddress":{"autoAddress":true,"addressId":"GANSW716893659","city":"QUAKERS HILL","country":"AU","fullAddress":"QUAKERS COURT SHOPPING CENTRE SHOP 11 76 FALMOUTH RD, QUAKERS HILL NSW 2763","latitude":-33.74030124,"longitude":150.88592346,"postcode":"2763","state":"NSW","street":"QUAKERS COURT SHOPPING CENTRE SHOP 11 76 FALMOUTH RD"},"developmentCostsDetails":{"totalBuildConstCost":"45789","levyPayable":"160.00","levyExemptionOption":"no"},"developmentApproval":{},"declaration":true}';
        User currentUser = [Select Id from User where email = 'greg.chapelnfp@gmail.com' Limit 1];
        AuraHandledException expectedException;
        System.runAs(currentUser){
            Test.startTest();
            try
    		{
            	Map<String, Object> passResult = LSC_LevyPaymentUtility.createLevyPayment(requestDetails);
            }
         	catch (AuraHandledException e)
            {
                expectedException = e;
            }
            Test.stopTest();
        }
    } 
}