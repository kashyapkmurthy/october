/**
 * @description       :
 * @author            : emily.jiang@customerservice.nsw.gov.aua
 * @group             :
 * @last modified on  : 07-15-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   07-15-2021   emily.jiang@customerservice.nsw.gov.au   Initial Version
 **/
@isTest
private class LSC_LegacyLevyTrigger_Test {
    @TestSetup
    static void makeData() {
        List<Account> accountList = LSC_TestDataFactory.createAccounts(1);

        insert accountList;

        List<Contact> contactList = LSC_TestDataFactory.createContact(1, accountList[0]);
        insert contactList;

        List<LSC_LegacyLevy__c> legacyLevyList = LSC_TestDataFactory.createLegacyLevys(
            1,
            accountList[0],
            true
        );

        List<LSC_LegacyTransaction__c> transactions = new List<LSC_LegacyTransaction__c>();
        LSC_LegacyTransaction__c paymentTransaction = LSC_TestDataFactory.createLegacyTransactions(
            legacyLevyList[0],
            'Payment',
            false
        );
        transactions.add(paymentTransaction);
        LSC_LegacyTransaction__c writeOffTransaction = LSC_TestDataFactory.createLegacyTransactions(
            legacyLevyList[0],
            'WriteOff',
            false
        );
        transactions.add(writeOffTransaction);
        insert transactions;
    }

    @IsTest
    static void processLevyConversionTest() {
        LSC_LegacyLevy__c legacyLevy = [
            SELECT Id, LSC_IsApproved__c, LSC_CorrectedRefundAmount__c
            FROM LSC_LegacyLevy__c
            LIMIT 1
        ];
        legacyLevy.LSC_IsApproved__c = true;
        legacyLevy.LSC_CorrectedRefundAmount__c = 100;
        Test.startTest();
        update legacyLevy;
        Test.stopTest();
        List<LSC_Levy__c> convertedLevy = [
            SELECT Id, LSC_LegacyLevyId__c
            FROM LSC_Levy__c
            WHERE LSC_LegacyLevyId__c = :legacyLevy.Id
        ];
        List<LSC_Transaction__c> convertedLevyTransactions = [
            SELECT Id
            FROM LSC_Transaction__c
            WHERE LSC_LevyId__c = :convertedLevy[0].Id AND RecordType.Name = 'Levy'
        ];
        List<LSC_Transaction__c> convertedRefundTransactions = [
            SELECT Id
            FROM LSC_Transaction__c
            WHERE LSC_LevyId__c = :convertedLevy[0].Id AND RecordType.Name = 'Refund'
        ];
        System.assertEquals(convertedLevy.size(), 1);
        System.assertEquals(convertedLevyTransactions.size(), 1);
        System.assertEquals(convertedLevyTransactions.size(), 1);
    }

    @IsTest
    static void processLevyConversionWithExistingRefundTransactionTest() {
        LSC_LegacyLevy__c legacyLevy = [
            SELECT Id, LSC_IsApproved__c, LSC_LevyPayable__c
            FROM LSC_LegacyLevy__c
            LIMIT 1
        ];
        legacyLevy.LSC_IsApproved__c = true;
        LSC_LegacyTransaction__c refundTransaction = LSC_TestDataFactory.createLegacyTransactions(
            legacyLevy,
            'Refund',
            false
        );
        insert refundTransaction;
        Test.startTest();
        update legacyLevy;
        Test.stopTest();
        List<LSC_Levy__c> convertedLevy = [
            SELECT Id, LSC_LegacyLevyId__c
            FROM LSC_Levy__c
            WHERE LSC_LegacyLevyId__c = :legacyLevy.Id
        ];
        List<LSC_Transaction__c> convertedLevyTransactions = [
            SELECT Id
            FROM LSC_Transaction__c
            WHERE LSC_LevyId__c = :convertedLevy[0].Id AND RecordType.Name = 'Levy'
        ];
        List<LSC_Transaction__c> convertedRefundTransactions = [
            SELECT Id
            FROM LSC_Transaction__c
            WHERE LSC_LevyId__c = :convertedLevy[0].Id AND RecordType.Name = 'Refund'
        ];
        System.assertEquals(convertedLevy.size(), 1);
        System.assertEquals(convertedLevyTransactions.size(), 1);
        System.assertEquals(convertedLevyTransactions.size(), 1);
    }

    @IsTest
    static void testUnusedMethod() {
        List<LSC_LegacyLevy__c> legacyLevyList = [
            SELECT Id, LSC_IsApproved__c, LSC_LevyPayable__c
            FROM LSC_LegacyLevy__c
        ];
        Map<Id, SObject> items = new Map<Id, SObject>();
        for (LSC_LegacyLevy__c legacyLevy : legacyLevyList) {
            items.put(legacyLevy.Id, legacyLevy);
        }
        Test.startTest();
        LSC_LegacyLevyTriggerHandler handler = new LSC_LegacyLevyTriggerHandler();
        handler.BeforeInsert(legacyLevyList);
        handler.BeforeUpdate(items, items);
        handler.BeforeDelete(items);
        handler.AfterInsert(items);
        handler.AfterDelete(items);
        handler.AfterUndelete(items);
        Test.stopTest();
    }
}