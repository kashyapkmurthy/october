@isTest
public class LSC_CouncilImportControllerTest {
    @testSetup static void setup() {
        Date d = Date.newInstance(Date.Today().Year(), Date.Today().Month(), 1);
        //Create System Admin User
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
            Id accBusinessRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Business').getRecordTypeId();
            Id levyBCIRecordTypeId = LSC_Levy__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_BCI').getRecordTypeId();
            Id transactionLevyRecordTypeId = LSC_Transaction__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Levy').getRecordTypeId();
            Id tliPaymentRecordTypeId = LSC_TransactionLineItem__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Payment').getRecordTypeId();
            Id tliCommissionRecordTypeId = LSC_TransactionLineItem__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Commission').getRecordTypeId();
            //Create Levy Support User
            User levySupportUser =  new User(Email = 'levySupprtuser@gmail.com', UserName = 'levySupprtuser@gmail.com', FirstName = 'Peter',
                                      LastName = 'Pan', ProfileId = profileId, EmailEncodingKey = 'UTF-8',
                                      TimeZoneSidKey = 'Australia/Sydney', Alias = 'petPan',
                                      LocaleSidKey = 'en_AU',
                                      LanguageLocaleKey = 'en_US');
            insert levySupportUser;
            Account businessCouncilAccount = new Account(name = 'THE HILLS SHIRE COUNCIL', LSC_AccountStatus__c = 'Active', LSC_Schemes__c= 'BCI', LSC_EntityStatus__c = 'Active', 
                                                         LSC_EntityTypeName__c = 'Council', Type='Commercial', recordTypeId=accBusinessRecordTypeId, LSC_ABN__c = '25034494656');
            insert businessCouncilAccount;
            List<LSC_Levy__c> levyRecList = new  List<LSC_Levy__c>();
            LSC_Levy__c levyRec1 = new LSC_Levy__c(recordTypeId = levyBCIRecordTypeId, LSC_AccountId__c = businessCouncilAccount.Id, LSC_CostOfWorks__c = 22222, LSC_LevyPayable__c = 77, LSC_ApplicationType__c = 'Development Application',
                                                 LSC_ApplicationNumber__c = 'BA-12345', LSC_LevySource__c = 'Council', LSC_ApplicationStatus__c = 'Ready to be paid', LSC_CouncilImportDate__c = d);
            levyRecList.add(levyRec1);
            LSC_Levy__c levyRec2 = new LSC_Levy__c(recordTypeId = levyBCIRecordTypeId, LSC_AccountId__c = businessCouncilAccount.Id, LSC_CostOfWorks__c = 150000, LSC_LevyPayable__c = 525, LSC_ApplicationType__c = 'Building Approval',
                                                 LSC_ApplicationNumber__c = 'BA-21-12', LSC_LevySource__c = 'Council', LSC_ApplicationStatus__c = 'Ready to be paid', LSC_CouncilImportDate__c = d);
            levyRecList.add(levyRec2);
            insert levyRecList;
            List<LSC_Transaction__c> transList = new  List<LSC_Transaction__c>();
            LSC_Transaction__c transactionRec1 = new LSC_Transaction__c(recordTypeId = transactionLevyRecordTypeId, LSC_PaymentMethod__c = 'Agency', LSC_Amount__c = 77, LSC_Status__c = 'Pending', LSC_LevyId__c = levyRec1.Id,
                                                                       LSC_TransactionSource__c = 'Council', LSC_PaymentDate__c = System.Date.today());
            transList.add(transactionRec1);
            
            LSC_Transaction__c transactionRec2 = new LSC_Transaction__c(recordTypeId = transactionLevyRecordTypeId, LSC_PaymentMethod__c = 'Agency', LSC_Amount__c = 525, LSC_Status__c = 'Pending', LSC_LevyId__c = levyRec2.Id,
                                                                       LSC_TransactionSource__c = 'Council', LSC_PaymentDate__c = System.Date.today());
            transList.add(transactionRec2);
            insert transList;
            List<LSC_TransactionLineItem__c> tliList = new  List<LSC_TransactionLineItem__c>();
            LSC_TransactionLineItem__c tliRec1 = new LSC_TransactionLineItem__c(LSC_TransactionId__c = transactionRec2.Id, LSC_AccountId__c = businessCouncilAccount.Id, recordTypeId = tliPaymentRecordTypeId,
                                                                               LSC_Amount__c = 410.20, LSC_Status__c = 'Paid', LSC_ReceiptDate__c = System.Date.today(), LSC_PaymentMethod__c = 'Agency',
                                                                               LSC_PaymentDate__c = System.Date.today());
            tliList.add(tliRec1);
            LSC_TransactionLineItem__c tliRec2 = new LSC_TransactionLineItem__c(LSC_TransactionId__c = transactionRec2.Id, LSC_AccountId__c = businessCouncilAccount.Id, recordTypeId = tliCommissionRecordTypeId,
                                                                               LSC_Amount__c = 18, LSC_Status__c = 'Paid', LSC_GST__c = 1.80, LSC_ReceiptDate__c = System.Date.today(), LSC_PaymentMethod__c = 'Agency',
                                                                               LSC_PaymentDate__c = System.Date.today());
            tliList.add(tliRec2);
            LSC_TransactionLineItem__c tliRec3 = new LSC_TransactionLineItem__c(LSC_TransactionId__c = transactionRec1.Id, LSC_AccountId__c = businessCouncilAccount.Id, recordTypeId = tliPaymentRecordTypeId,
                                                                               LSC_Amount__c = 212, LSC_Status__c = 'Paid', LSC_ReceiptDate__c = System.Date.today(), LSC_PaymentMethod__c = 'Agency',
                                                                               LSC_PaymentDate__c = System.Date.today());
            tliList.add(tliRec3);
            LSC_TransactionLineItem__c tliRec4 = new LSC_TransactionLineItem__c(LSC_TransactionId__c = transactionRec1.Id, LSC_AccountId__c = businessCouncilAccount.Id, recordTypeId = tliCommissionRecordTypeId,
                                                                               LSC_Amount__c = 22, LSC_Status__c = 'Paid', LSC_GST__c = 2.20, LSC_ReceiptDate__c = System.Date.today(), LSC_PaymentMethod__c = 'Agency',
                                                                               LSC_PaymentDate__c = System.Date.today());    
            tliList.add(tliRec4);
            insert tliList;
        }
    }
    
    @isTest
    Public static void getReportTest(){
        User currentUser = [Select Id from User where email = 'levySupprtuser@gmail.com' Limit 1];
        List<Account> accLst = [Select Id from Account where Name = 'THE HILLS SHIRE COUNCIL'];
        List<LSC_CouncilImportController.ReportLine> report = new List<LSC_CouncilImportController.ReportLine>();
        System.runAs(currentUser){
            Test.startTest();
            report = LSC_CouncilImportController.getReport(accLst[0].Id, String.valueOf(Date.Today().Year()), String.valueOf(Date.Today().Month()));
            Test.stopTest();  
        }
        system.assertEquals(true, report.Size() > 0);
    }
    
    @isTest
    Public static void getLevyRecordsTest(){
        User currentUser = [Select Id from User where email = 'levySupprtuser@gmail.com' Limit 1];
        List<Account> accLst = [Select Id from Account where Name = 'THE HILLS SHIRE COUNCIL'];
        List<LSC_Levy__c> levyLst;
        System.runAs(currentUser){
            Test.startTest();
            levyLst = LSC_CouncilImportController.getLevyRecords(accLst[0].Id);
            Test.stopTest();  
        }
        system.assertEquals(true, levyLst.Size() > 0);
    }
    
    @isTest
    Public static void createRecordsTest(){
        User currentUser = [Select Id from User where email = 'levySupprtuser@gmail.com' Limit 1];
        List<Account> accLst = [Select Id from Account where Name = 'THE HILLS SHIRE COUNCIL'];
        List<String> appTypes = new List<String>{'CC', 'DA', 'CDC', 'CONTRACT', 'GC', 'CCE', 'GDA', 'BA', 'BC', 'CCB', 'SWC', 'SCC', 'LD', 'CW', 'PCDC', 'PWC', 'SDCC', 'DA/CC', 'S68'};
        LSC_CouncilImportController.ResultWrapper result;
        List<Map<String, String>> recordsToBeInserted = new List<Map<String, String>>();
        for(integer i=0; i< appTypes.Size(); i++){
            Map<String, String> recordData = new Map<String, String>{'AppNumber'=>'CC-21-00024557', 'City'=>null, 'Comments'=>'updating test comments', 'Commission'=>'18', 'Cost'=>'150000.00', 'GST'=>'1.80', 'PaidAmount'=>'525', 'PostCode'=>null, 'Street'=>'4 Zep Place, KELLYVILLE RIDGE  NSW  2155', 'Type'=>appTypes[i]};
            recordsToBeInserted.add(recordData);
        }
        System.runAs(currentUser){
            Test.startTest();
            result = LSC_CouncilImportController.createRecords(recordsToBeInserted, accLst[0].Id, String.valueOf(Date.Today().Year()), String.valueOf(Date.Today().Month()));
            Test.stopTest(); 
        }
        system.assertEquals(true, result!=null);
    }    
}