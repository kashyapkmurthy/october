@isTest
public class LSC_LevyListControllerTest {
    @TestSetup
    static void makeData() {
        Id sysAdminprofileId = [SELECT Id FROM Profile WHERE Profile.Name = 'System Administrator']
        .Id;
        Id userRleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'LSC_Director'].Id;
        Id transInstalmentRecTypeId = LSC_Transaction__c.sObjectType.getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('LSC_Instalment')
            .getRecordTypeId();
        Id transInterestRecTypeId = LSC_Transaction__c.sObjectType.getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('LSC_Interest')
            .getRecordTypeId();
        User sysAdmn = new User(
            email = 'admincorp@gmail.com',
            profileid = sysAdminprofileId,
            UserName = 'greg.chapel@gmail.com' + '.test',
            Alias = 'GCL',
            FirstName = 'Greg',
            LastName = 'Chapel',
            userRoleId = userRleId,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_AU',
            LanguageLocaleKey = 'en_US'
        );
        insert sysAdmn;
        System.runAs(sysAdmn) {
            Id profileId = [
                SELECT Id
                FROM Profile
                WHERE Profile.Name = 'LSC Customer Community Login User'
            ]
            .Id;
            Id accIndividualRecordTypeId = Account.sObjectType.getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('LSC_Individual')
                .getRecordTypeId();
            Id accBusinessRecordTypeId = Account.sObjectType.getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('LSC_Business')
                .getRecordTypeId();
            //Business Account
            Account businessAccount = new Account(
                name = 'BusinessAccount',
                Type = 'Commercial',
                recordTypeId = accBusinessRecordTypeId
            );
            insert businessAccount;
            Contact businessContact = new contact(
                LastName = 'Businessuser',
                AccountId = businessAccount.Id,
                email = 'greg.chapel@gmail.com'
            );
            insert businessContact;
            AccountContactRelation acr = [
                SELECT Id, LSC_IsLevyPayer__c
                FROM AccountContactRelation
                WHERE ContactId = :businessContact.Id
            ];
            acr.LSC_IsLevyPayer__c = true;
            update acr;
            User u1 = new User(
                email = 'greg.chapel@gmail.com',
                profileid = profileId,
                UserName = 'greg.chapel@gmail.com' + '.test7654',
                Alias = 'GCL',
                ContactId = businessContact.Id,
                FirstName = 'Greg',
                LastName = 'Chapel',
                EmailEncodingKey = 'UTF-8',
                TimeZoneSidKey = 'Australia/Sydney',
                LocaleSidKey = 'en_AU',
                LanguageLocaleKey = 'en_US'
            );
            insert u1;

            List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(
                1,
                businessAccount,
                businessContact
            );
            insert levyList;

            Id instalmentCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName()
                .get('Instalment')
                .getRecordTypeId();
            List<Case> cases = LSC_TestDataFactory.createCase(
                1,
                businessAccount,
                businessContact,
                levyList[0],
                instalmentCaseRT
            );
            insert cases;

            List<LSC_Transaction__c> transactionsTypeLevy = LSC_TestDataFactory.createTransaction(1, levyList[0], Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_LEVY).getRecordTypeId());
            transactionsTypeLevy[0].LSC_Status__c = 'Pending';
            insert transactionsTypeLevy;

            List<LSC_Transaction__c> transactionsTypeInterest = LSC_TestDataFactory.createTransaction(1, levyList[0], Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_INTEREST).getRecordTypeId());
            transactionsTypeInterest[0].LSC_Status__c = 'Pending';
            insert transactionsTypeInterest;
        }
    }

    @isTest
    static void getLeviesTestSortByName() {
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        List<LSC_Transaction__c> transactions = [Select id, LSC_Status__c from LSC_Transaction__c];
        transactions[0].LSC_Status__c = 'Paid';
        update transactions;
        System.runAs(currentUser){
            Test.startTest();
            List<LSC_LevyListController.Wrapper> lvWrapper = LSC_LevyListController.getLevies('0', 'refNo', 'DESC');
            Test.stopTest();
            System.assertEquals(lvWrapper.size(), 1);
        }
    }

    @isTest
    static void getLeviesTestSortByApplicationNumber() {
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            List<LSC_LevyListController.Wrapper> lvWrapper = LSC_LevyListController.getLevies('0', 'daNo', 'DESC');
            Test.stopTest();
            System.assertEquals(lvWrapper.size(), 1);
        }
    }

    @isTest
    static void getLeviesTestSortByAddress() {
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            List<LSC_LevyListController.Wrapper> lvWrapper = LSC_LevyListController.getLevies('0', 'address', 'DESC');
            Test.stopTest();
            System.assertEquals(lvWrapper.size(), 1);
        }
    }

    @isTest
    static void getLeviesTestSortByStatus() {
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        System.runAs(currentUser){
            Test.startTest();
            List<LSC_LevyListController.Wrapper> lvWrapper = LSC_LevyListController.getLevies('0', 'status', 'DESC');
            Test.stopTest();
            System.assertEquals(lvWrapper.size(), 1);
        }
    }
}