/**
 * @description       :
 * @author            : emily.jiang@customerservice.nsw.gov.au
 * @group             :
 * @last modified on  : 07-28-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   07-28-2021   emily.jiang@customerservice.nsw.gov.au   Initial Version
 **/
@isTest
private class LSC_LegacyLevyController_Test {
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

        LSC_LegacyTransaction__c refundTransaction = LSC_TestDataFactory.createLegacyTransactions(
            legacyLevyList[0],
            'Refund',
            false
        );

        transactions.add(refundTransaction);

        LSC_LegacyTransaction__c commissionTransaction = LSC_TestDataFactory.createLegacyTransactions(
            legacyLevyList[0],
            'Commission',
            false
        );

        transactions.add(commissionTransaction);

        insert transactions;
    }

    @IsTest
    static void getDataTest() {
        LSC_LegacyLevy__c legacyLevy = [
            SELECT Id, LSC_IsApproved__c, LSC_CorrectedRefundAmount__c, LSC_CostOfWorks__c
            FROM LSC_LegacyLevy__c
            LIMIT 1
        ];
        LSC_LegacyLevyController.LLWrapper result;
        Test.startTest();
        result = LSC_LegacyLevyController.getData(legacyLevy.Id);
        Test.stopTest();
        System.assertEquals(result.costOfWorks, legacyLevy.LSC_CostOfWorks__c);
    }

    @isTest
    static void submitApprovalTest() {
        LSC_LegacyLevy__c legacyLevy = [
            SELECT
                Id,
                LSC_IsApproved__c,
                LSC_CorrectedRefundAmount__c,
                LSC_CostOfWorks__c,
                LSC_NewLevyAccount__c
            FROM LSC_LegacyLevy__c
            LIMIT 1
        ];
        Double costOfWorks = 200000;
        Double payable = 0.035 * 200000;
        Double paid = payable - 50;
        Double writeOffAmount = 50;
        Double refund = 50;
        String lga = 'ALBURY CITY COUNCIL';

        LSC_LegacyLevyController.ResultWrapper result;
        Test.startTest();
        result = LSC_LegacyLevyController.submitApproval(
            legacyLevy.Id,
            legacyLevy.LSC_NewLevyAccount__c,
            UserInfo.getUserId(),
            paid,
            refund,
            writeOffAmount,
            lga
        );
        Test.stopTest();
        System.assertEquals(String.isBlank(result.error), true);
    }
}