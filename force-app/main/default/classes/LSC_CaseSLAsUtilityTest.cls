@isTest
public class LSC_CaseSLAsUtilityTest {
    private static final List<String> daysLst = new List<String>{'Tue', 'Wed'};
    private static final String currentDateTime = System.now().format(); //Current User Timezone 
    private static final DateTime caseCreationDate = daysLst.contains(dateTime.parse(currentDateTime).format('E'))? dateTime.parse(currentDateTime) - 8: dateTime.parse(currentDateTime) - 10;//Any weekday
    
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
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'LSC BCI Levy Support' LIMIT 1].Id; 
            Id caseInstalmentRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Instalment').getRecordTypeId();
            User levySupportUser =  new User(Email = 'levySupprtuser@gmail.com', UserName = 'levySupprtuser@gmail.com', FirstName = 'Peter',
                                      LastName = 'Pan', ProfileId = profileId, EmailEncodingKey = 'UTF-8',
                                      TimeZoneSidKey = 'Australia/Sydney', Alias = 'petPan',
                                      LocaleSidKey = 'en_AU',
                                      LanguageLocaleKey = 'en_US');
            insert levySupportUser;
            Id accBusinessRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Business').getRecordTypeId();
            //Business Account
            Account businessAccount = new Account(name = 'BusinessAccount', Type='Commercial', recordTypeId=accBusinessRecordTypeId);
            insert businessAccount;
            //Business Contact
            Contact businessContact = new contact(LastName = 'Businessuser', AccountId = businessAccount.Id, email='greg.chapel@gmail.com', LSC_SelectedAccountId__c = businessAccount.Id); 
            insert businessContact;
            //Create Levy
            List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, businessAccount, businessContact);
        	insert levyList;
            //Create Instalment Cases with New status
            List<Case> caseLst = new List<Case>();
            List<Case> cases = LSC_TestDataFactory.createCase(5, businessAccount, businessContact, levyList[0], caseInstalmentRecordTypeId);
            List<String> caseStatusLst = new List<String>{'New', 'In Progress', 'On Hold', 'Pending Approval'};
            for(Case c :cases){
               c.LSC_InstalmentDetails__c = '[{"totalLevyAmt":null,"totalCost":null,"startDate":"30-07-2021","showDel":null,"payNo":"1","levyAmt":8750.0,"estimatedCost":null},{"totalLevyAmt":null,"totalCost":null,"startDate":"31-01-2022","showDel":null,"payNo":"2","levyAmt":8750.0,"estimatedCost":null},{"totalLevyAmt":null,"totalCost":null,"startDate":"03-08-2022","showDel":null,"payNo":"3","levyAmt":8750.0,"estimatedCost":null},{"totalLevyAmt":null,"totalCost":null,"startDate":"04-02-2023","showDel":null,"payNo":"4","levyAmt":8750.0,"estimatedCost":null}]';
               c.Type = 'Equal instalments';
               c.LSC_Number_of_Instalments__c = '4';     
            }
            caseLst.addAll(cases);
            insert caseLst;
            caseLst.clear();
            //Set created date for a Case
            test.setCreatedDate(cases[0].Id, caseCreationDate);
            //Update Cases with different status - Covers ManageSLAs method
            for(Integer i = 1; i < caseStatusLst.Size(); i++){
               cases[i].Status = caseStatusLst[i];
               caseLst.add(cases[i]);
               //Set created date for each Case
               test.setCreatedDate(cases[i].Id, caseCreationDate);
            }
            update caseLst;    
        }
    }
    
    //Test Case with New status
    @isTest
    Public static void getDataNewCaseTest(){
        User currentUser = [Select Id from User where email = 'levySupprtuser@gmail.com' Limit 1];
        Case caseRec = [Select Id from Case where Status = 'New' Limit 1];
        LSC_CaseSLAsUtility.SLAWrapper result;
        System.runAs(currentUser){
            Test.startTest();
            result = LSC_CaseSLAsUtility.getData(caseRec.Id);
            Test.stopTest();     
            system.assertEquals(true, result != Null);
        }  
    }
    
    //Test Case - update New Case status
    @isTest
    Public static void getDataNewCaseUpdateTest(){
        User currentUser = [Select Id from User where email = 'levySupprtuser@gmail.com' Limit 1];
        Case caseRec = [Select Id from Case where Status = 'New' Limit 1];
        caseRec.Status = 'In Progress';
        update caseRec;
        LSC_CaseSLAsUtility.SLAWrapper result;
        System.runAs(currentUser){
            Test.startTest();
            result = LSC_CaseSLAsUtility.getData(caseRec.Id);
            Test.stopTest();     
            system.assertEquals(true, result != Null);
        }  
    }
    
    //Test Case with In Progress -> On Hold changed status - covers ManageSLAs method as well on Case status update
    @isTest
    Public static void getDataOnHoldCaseTest(){
        //Update Progress start to a business day
        DateTime caseProgressStartDate = caseCreationDate.format('E') == 'Fri'? caseCreationDate + 3 : caseCreationDate + 1;
        User currentUser = [Select Id from User where email = 'levySupprtuser@gmail.com' Limit 1];
        Case caseRec = [Select Id, LSC_InProgressStart__c from Case where Status = 'In Progress' Limit 1];
        caseRec.Status = 'On Hold';
        caseRec.LSC_InProgressStart__c = caseProgressStartDate;
        update caseRec;
        LSC_CaseSLAsUtility.SLAWrapper result;
        System.runAs(currentUser){
            Test.startTest();
            result = LSC_CaseSLAsUtility.getData(caseRec.Id);
            Test.stopTest();     
            system.assertEquals(true, result != Null);
        }  
    }
    
    //Test Case with On Hold -> Pending Approval changed status - covers ManageSLAs method as well on Case status update
    @isTest
    Public static void getDataPendingApprCaseTest(){
        //Update Hold start to a business day
        DateTime caseHoldStartDate = caseCreationDate.format('E') == 'Fri'? caseCreationDate + 3 : caseCreationDate + 1;
        User currentUser = [Select Id from User where email = 'levySupprtuser@gmail.com' Limit 1];
        Case caseRec = [Select Id, LSC_OnHoldStart__c from Case where Status = 'On Hold' Limit 1];
        caseRec.Status = 'Pending Approval';
        caseRec.LSC_OnHoldStart__c = caseHoldStartDate;
        update caseRec;
        LSC_CaseSLAsUtility.SLAWrapper result;
        System.runAs(currentUser){
            Test.startTest();
            result = LSC_CaseSLAsUtility.getData(caseRec.Id);
            Test.stopTest();     
            system.assertEquals(true, result != Null);
        }  
    }
    
    //Test Case with Pending Approval -> Closed Approved changed status - covers ManageSLAs method as well on Case status update
    @isTest
    Public static void getDataClosedCaseTest(){
        //Update Approval start to a business day
        DateTime caseApprovalStartDate = caseCreationDate.format('E') == 'Fri'? caseCreationDate + 3 : caseCreationDate + 1;
        User currentUser = [Select Id from User where email = 'levySupprtuser@gmail.com' Limit 1];
        Case caseRec = [Select Id, LSC_ApprovalStart__c from Case where Status = 'Pending Approval' Limit 1];
        caseRec.Status = 'Closed Approved';
        caseRec.LSC_ApprovalStart__c = caseApprovalStartDate;
        update caseRec;
        LSC_CaseSLAsUtility.SLAWrapper result;
        System.runAs(currentUser){
            Test.startTest();
            result = LSC_CaseSLAsUtility.getData(caseRec.Id);
            Test.stopTest();     
            system.assertEquals(true, result != Null);
        }  
    }    
    
}