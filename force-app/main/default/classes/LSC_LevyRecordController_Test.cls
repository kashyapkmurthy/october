/**
 * @description       :
 * @author            : emily.jiang@customerservice.nsw.gov.au
 * @group             :
 * @last modified on  : 07-28-2021
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   07-28-2021   emily.jiang@customerservice.nsw.gov.au   Initial Version
 **/
@isTest
private class LSC_LevyRecordController_Test {
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
        }

    }

    @isTest
    static void getCasesTest() {
        LSC_Levy__c levy = [SELECT Id FROM LSC_Levy__c LIMIT 1];

        Case levyCase = [SELECT Id FROM Case LIMIT 1];

        List<LSC_LevyRecordController.CaseWrapper> result;
        Test.startTest();
        result = LSC_LevyRecordController.getCases(levy.Id);
        Test.stopTest();

        System.assertEquals(result.size(), 1);
        System.assertEquals(result[0].id, levyCase.Id);
    }

    @isTest
    static void getEFTTest() {
        User u = [
            SELECT Id, FirstName, LastName
            FROM User
            WHERE FirstName = 'Greg' AND LastName = 'Chapel' AND Email = 'greg.chapel@gmail.com'
            LIMIT 1
        ];

        LSC_LevyRecordController.EFTWrapper result;
        String label = 'BCI';

        System.runAs(u) {
            Test.startTest();
            result = LSC_LevyRecordController.getEFT(label);
            Test.stopTest();
            System.assertEquals(result.eftAllowed, false);
        }
    }

    @IsTest
    static void getTransactionsTest() {
        LSC_Levy__c levy = [SELECT Id FROM LSC_Levy__c LIMIT 1];
        List<LSC_Transaction__c> transactionList = LSC_TestDataFactory.createTransaction(
            1,
            levy,
            Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName()
                .get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_INTEREST)
                .getRecordTypeId()
        );

        for (LSC_Transaction__c tran : transactionList) {
            tran.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
        }

        insert transactionList;

        List<LSC_LevyRecordController.TransactionWrapper> result;
        Test.startTest();
        result = LSC_LevyRecordController.getTransactions(levy.Id);
        Test.stopTest();
        System.assertEquals(result.size(), 1);
        System.assertEquals(result[0].id, transactionList[0].Id);
    }

    @IsTest
    static void getPaymentsTest() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        LSC_Levy__c levy = [SELECT Id FROM LSC_Levy__c LIMIT 1];
        List<LSC_Transaction__c> transactionList = LSC_TestDataFactory.createTransaction(
            1,
            levy,
            Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName()
                .get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_INSTALMENT)
                .getRecordTypeId()
        );

        for (LSC_Transaction__c tran : transactionList) {
            tran.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
        }

        insert transactionList;

        List<LSC_TransactionLineItem__c> transactionLineItems = LSC_TestDataFactory.createTransactionLineItems(
            1,
            acc,
            transactionList[0],
            Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName()
                .get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_PAYMENT)
                .getRecordTypeId(),
            100,
            'Paid'
        );

        insert transactionLineItems;

        List<LSC_LevyRecordController.TLIWrapper> result;
        Test.startTest();
        result = LSC_LevyRecordController.getPayments(levy.Id);
        Test.stopTest();
        System.assertEquals(result.size(), 1);
        System.assertEquals(result[0].id, transactionLineItems[0].Id);
    }

    @IsTest
    static void getInstalmentsTest() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        LSC_Levy__c levy = [SELECT Id FROM LSC_Levy__c LIMIT 1];
        List<LSC_Transaction__c> transactionList = LSC_TestDataFactory.createTransaction(
            1,
            levy,
            Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName()
                .get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_INSTALMENT)
                .getRecordTypeId()
        );

        for (LSC_Transaction__c tran : transactionList) {
            tran.LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
        }

        insert transactionList;

        List<LSC_TransactionLineItem__c> transactionLineItems = LSC_TestDataFactory.createTransactionLineItems(
            1,
            acc,
            transactionList[0],
            Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName()
                .get(LSC_GlobalConstants.LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_PAYMENT)
                .getRecordTypeId(),
            100,
            'Paid'
        );

        insert transactionLineItems;

        List<LSC_LevyRecordController.TransactionWrapper> result;
        Test.startTest();
        result = LSC_LevyRecordController.getInstalments(levy.Id);
        Test.stopTest();
        System.assertEquals(result.size(), 1);
        System.assertEquals(result[0].id, transactionList[0].Id);
    }

    @isTest
    static void createTopupTest() {
        User u = [
            SELECT Id, FirstName, LastName
            FROM User
            WHERE FirstName = 'Greg' AND LastName = 'Chapel' AND Email = 'greg.chapel@gmail.com'
            LIMIT 1
        ];
        LSC_Levy__c levy = [SELECT Id FROM LSC_Levy__c LIMIT 1];
        LSC_LevyRecordController.Wrapper result;
        System.runAs(u) {
            Test.startTest();
            result = LSC_LevyRecordController.createTopup(levy.Id, 123456789);
            Test.stopTest();
            System.assertEquals(String.isBlank(result.error), true);
        }
    }

    @isTest
    static void createTopupError2Test() {
        User u = [
            SELECT Id, FirstName, LastName
            FROM User
            WHERE FirstName = 'Greg' AND LastName = 'Chapel' AND Email = 'greg.chapel@gmail.com'
            LIMIT 1
        ];
        LSC_Levy__c levy = [SELECT Id, LSC_ApplicationStatus__c FROM LSC_Levy__c LIMIT 1];
        levy.LSC_ApplicationStatus__c = 'Ready to be paid';
        update levy;
        LSC_LevyRecordController.Wrapper result;
        System.runAs(u) {
            Test.startTest();
            result = LSC_LevyRecordController.createTopup(levy.Id, 123456789);
            Test.stopTest();
            System.assertEquals(result.error, 'You can only Top Up a paid Levy');
        }
    }

    @isTest
    static void createTopupError3Test() {
        Account businessAccount = [SELECT Id FROM Account LIMIT 1];
        Contact businessContact = [SELECT Id FROM Contact LIMIT 1];
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(
            1,
            businessAccount,
            businessContact
        );
        for (LSC_Levy__c levy : levyList) {
            levy.LSC_ApprovedVoluntaryLabourcost__c = 223456789;
        }
        insert levyList;
        User u = [
            SELECT Id, FirstName, LastName
            FROM User
            WHERE FirstName = 'Greg' AND LastName = 'Chapel' AND Email = 'greg.chapel@gmail.com'
            LIMIT 1
        ];
        LSC_LevyRecordController.Wrapper result;
        System.runAs(u) {
            Test.startTest();
            result = LSC_LevyRecordController.createTopup(levyList[0].Id, 123456789);
            Test.stopTest();
            System.assertEquals(result.error, 'Top Up amount can\'t be negative');
        }
    }

    @isTest
    static void deleteDocumentTest() {
        Account businessAccount = [SELECT Id FROM Account LIMIT 1];
        String NETWORK_NAME = 'BCI';
        List<String> documentIds = new List<String>();
        String base64StringImageTest = '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';
        String expectedFileName = 'testimage.gif';
        Id networkId = [SELECT Id FROM Network WHERE Name = :NETWORK_NAME LIMIT 1].Id;
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = EncodingUtil.base64Decode(base64StringImageTest);
        cv.Title = expectedFileName;
        cv.PathOnClient = expectedFileName;
        cv.NetworkId = networkId;
        insert cv;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id]
        .ContentDocumentId;
        cdl.LinkedEntityId = businessAccount.Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        String contentDocumentId = cdl.ContentDocumentId;
        String result;
        Test.startTest();
        result = LSC_LevyRecordController.deleteDocument(contentDocumentId);
        Test.stopTest();
        System.assertEquals(result, 'SUCCESS');
    }

    @isTest
    static void createCaseTest() {
        User u = [
            SELECT Id, FirstName, LastName
            FROM User
            WHERE FirstName = 'Greg' AND LastName = 'Chapel' AND Email = 'greg.chapel@gmail.com'
            LIMIT 1
        ];
        Account businessAccount = [SELECT Id FROM Account LIMIT 1];
        LSC_Levy__c levy = [SELECT Id FROM LSC_Levy__c LIMIT 1];
        String NETWORK_NAME = 'BCI';
        List<String> documentIds = new List<String>();
        String base64StringImageTest = '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';
        String expectedFileName = 'testimage.gif';
        Id networkId = [SELECT Id FROM Network WHERE Name = :NETWORK_NAME LIMIT 1].Id;
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = EncodingUtil.base64Decode(base64StringImageTest);
        cv.Title = expectedFileName;
        cv.PathOnClient = expectedFileName;
        cv.NetworkId = networkId;
        insert cv;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id]
        .ContentDocumentId;
        cdl.LinkedEntityId = businessAccount.Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        String contentDocumentId = cdl.ContentDocumentId;
        List<String> docIds = new List<String>();
        docIds.add(contentDocumentId);
        Decimal costOfWork = 12345678;
        Decimal refundAmount = 100;
        String levyId = levy.Id;
        LSC_LevyRecordController.Wrapper result;
        System.runAs(u) {
            Test.startTest();
            result = LSC_LevyRecordController.createCase(
                levyId,
                'Refund',
                'Refund - Levy paid at Agency',
                'test subject',
                'test details',
                '123456',
                '213456',
                'test account name',
                'test bank name',
                costOfWork,
                refundAmount,
                0.0,
                null,
                docIds
            );
            Test.stopTest();
        }
    }

    @IsTest
    static void getLevyDetailsTest() {
        User u = [
            SELECT Id, FirstName, LastName
            FROM User
            WHERE FirstName = 'Greg' AND LastName = 'Chapel' AND Email = 'greg.chapel@gmail.com'
            LIMIT 1
        ];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        LSC_Levy__c levy = [SELECT Id FROM LSC_Levy__c LIMIT 1];
        List<LSC_Transaction__c> levyTransactionList = LSC_TestDataFactory.createTransaction(
            1,
            levy,
            Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName()
                .get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_LEVY)
                .getRecordTypeId()
        );

        levyTransactionList[0].LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
        insert levyTransactionList;

        LSC_LevyRecordController.LevyWrapper result;
        System.runAs(u) {
            Test.startTest();
            result = LSC_LevyRecordController.getLevyDetails(levy.Id);
            Test.stopTest();
            System.assertEquals(result.id, levy.Id);
        }
    }

    @IsTest
    static void getOverdueInstalmentTest() {
        User u = [
            SELECT Id, FirstName, LastName
            FROM User
            WHERE FirstName = 'Greg' AND LastName = 'Chapel' AND Email = 'greg.chapel@gmail.com'
            LIMIT 1
        ];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        LSC_Levy__c levy = [SELECT Id FROM LSC_Levy__c LIMIT 1];
        List<LSC_Transaction__c> transactionList = LSC_TestDataFactory.createTransaction(
            1,
            levy,
            Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName()
                .get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_INSTALMENT)
                .getRecordTypeId()
        );

        transactionList[0].LSC_Status__c = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
        transactionList[0].LSC_DueDate__c = Date.today().addDays(-5);
        insert transactionList;

        LSC_LevyRecordController.OverdueWrapper result;
        System.runAs(u) {
            Test.startTest();
            result = LSC_LevyRecordController.getOverdueInstalment(levy.Id);
            Test.stopTest();
            System.assertEquals(result.hasOverdue, true);
        }
    }
}