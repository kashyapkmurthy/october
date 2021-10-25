@isTest
public class LSC_BCIHomePageControllerTest {
    @testSetup static void setup() {
       Id sysAdminprofileId = [Select Id from Profile where Profile.Name = 'System Administrator'].Id;
       Id userRleId = [Select Id from UserRole where DeveloperName='LSC_Director'].Id;
       Id transInstalmentRecTypeId = LSC_Transaction__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Instalment').getRecordTypeId();
       Id transInterestRecTypeId = LSC_Transaction__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Interest').getRecordTypeId();
       Integer levyIndex = 0;
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
            Id caseInstalmentRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Instalment').getRecordTypeId();
            //Business Account
            Account businessAccount = new Account(name = 'BusinessAccount', Type='Commercial', recordTypeId=accBusinessRecordTypeId);
            insert businessAccount;
            Contact businessContact = new contact(LastName = 'Businessuser', AccountId = businessAccount.Id, email='greg.chapel@gmail.com'); 
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
            //Insert Levy, Case and Transaction records
            List<Case> caseList = new List<Case>();
            List<LSC_Transaction__c> transactionList = new List<LSC_Transaction__c>();
            //Create Levy
            List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(10, businessAccount, businessContact);
        	insert levyList;
            //Create Cases under 5 different Levies
            List<Case> cases = LSC_TestDataFactory.createCase(5, businessAccount, businessContact, levyList[0], caseInstalmentRecordTypeId);
            for(Case c : cases){
                c.Type = 'Equal instalments';
                c.Status = 'On Hold';
                c.LSC_LevyId__c = levyList[levyIndex].Id;
                c.LSC_InstalmentDetails__c = '[{"totalLevyAmt":null,"totalCost":null,"startDate":"30-07-2021","showDel":null,"payNo":"1","levyAmt":8750.0,"estimatedCost":null},{"totalLevyAmt":null,"totalCost":null,"startDate":"31-01-2022","showDel":null,"payNo":"2","levyAmt":8750.0,"estimatedCost":null},{"totalLevyAmt":null,"totalCost":null,"startDate":"03-08-2022","showDel":null,"payNo":"3","levyAmt":8750.0,"estimatedCost":null},{"totalLevyAmt":null,"totalCost":null,"startDate":"04-02-2023","showDel":null,"payNo":"4","levyAmt":8750.0,"estimatedCost":null}]';
                c.LSC_Number_of_Instalments__c = '4';
                caseList.add(c);
                levyIndex++;
            }
            insert caseList;
            
            //Create Transactions under 5 different Levies
            for(integer i=5; i<9; i++){
                transactionList.add(new LSC_Transaction__c(LSC_Status__c = 'Pending', LSC_DueDate__c = Date.today().addDays(-1), RecordTypeId = transInstalmentRecTypeId, LSC_LevyId__c = levyList[i].Id));
            }
            transactionList.add(new LSC_Transaction__c(LSC_Status__c = 'Pending', LSC_DueDate__c = Date.today().addDays(-1), RecordTypeId = transInterestRecTypeId, LSC_LevyId__c = levyList[0].Id));
            insert transactionList;
        }
    }
    
    @isTest
    Public static void getCaseListTest(){       
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            List<LSC_BCIHomePageController.Wrapper> caseList = LSC_BCIHomePageController.getCaseList();
            Test.stopTest();     
            system.assertEquals(5, caseList.Size());
        }
    } 
    
    @isTest
    Public static void getCasenTransactionListTest(){       
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            List<LSC_BCIHomePageController.Wrapper> casenTransList = LSC_BCIHomePageController.getCaseAndTransactionList();
            Test.stopTest();  
            system.assertEquals(10, casenTransList.Size());
        }
    } 
    
    @isTest
    Public static void getColumnsTest(){       
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            List<LSC_BCIHomePageController.columnAttributes> tableColumns = LSC_BCIHomePageController.getColumns(true);
            Test.stopTest();  
            system.assertEquals(3, tableColumns.Size());
        }
    } 
}