@isTest
private class LSC_CaseTrigger_Test {

    
    static testMethod void testEqualInstalmentTransaction() {
        //Status
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        insert levyList;


        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Instalment').getRecordTypeId();
        List<Case> cases = LSC_TestDataFactory.createCase(1, accounts[0], contacts[0], levyList[0], caseRT);
        cases[0].Status = 'Awaiting Approving Authority';
        cases[0].LSC_InstalmentDetails__c = '[{"startDate":null,"stage":null,"presetInstal":"8750.00","payNo":"1","id":"0","estimatedCost":null,"dueDate":"24-05-2021"},{"startDate":null,"stage":null,"presetInstal":"8750.00","payNo":"2","id":"1","estimatedCost":null,"dueDate":"02-09-2021"},{"startDate":null,"stage":null,"presetInstal":"8750.00","payNo":"3","id":"2","estimatedCost":null,"dueDate":"11-12-2021"},{"startDate":null,"stage":null,"presetInstal":"8750.00","payNo":"4","id":"3","estimatedCost":null,"dueDate":"22-03-2022"}]'; 
        cases[0].LSC_Number_of_Instalments__c = '5';

        insert cases;

        cases[0].status = 'Closed Approved';

        Test.startTest();
           
            update cases;
        Test.stopTest();

    }

    static testMethod void testStagedInstalmentTransaction() {
        //Status
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        insert levyList;


        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Instalment').getRecordTypeId();
        List<Case> cases = LSC_TestDataFactory.createCase(1, accounts[0], contacts[0], levyList[0], caseRT);
        cases[0].Status = 'Awaiting Approving Authority';
        cases[0].Type = 'Staged instalments';
        cases[0].LSC_InstalmentDetails__c = '[{"totalLevyAmt":null,"totalCost":null,"startDate":"2021-07-12","showDel":false,"payNo":"375/1","levyAmt":7000.0,"estimatedCost":2000000.0},{"totalLevyAmt":null,"totalCost":null,"startDate":"2021-10-12","showDel":false,"payNo":"375/2","levyAmt":7000.0,"estimatedCost":2000000.0},{"totalLevyAmt":null,"totalCost":null,"startDate":"2022-01-12","showDel":false,"payNo":"375/3","levyAmt":7000.0,"estimatedCost":2000000.0},{"totalLevyAmt":null,"totalCost":null,"startDate":"2022-04-12","showDel":false,"payNo":"375/4","levyAmt":7000.0,"estimatedCost":2000000.0},{"totalLevyAmt":null,"totalCost":null,"startDate":"2022-07-12","showDel":true,"payNo":"375/5","levyAmt":7000.0,"estimatedCost":2000000.0},{"totalLevyAmt":35000.0,"totalCost":1.0E7,"startDate":null,"showDel":null,"payNo":null,"levyAmt":null,"estimatedCost":null}]'; 
        cases[0].LSC_Number_of_Instalments__c = '4';

        insert cases;

        cases[0].status = 'Closed Approved';

        Test.startTest();
           
            update cases;
        Test.stopTest();

    }

    static testMethod void testRefundTransaction() {
        //Status
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        insert levyList;


        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
        List<Case> cases = LSC_TestDataFactory.createCase(1, accounts[0], contacts[0], levyList[0], caseRT);
        cases[0].Status = 'Awaiting Approving Authority';
        cases[0].LSC_InstalmentDetails__c = '[{"startDate":"2021-06-07","payNo":"DA538/1","levyAmt":8750.0,"estimatedCost":2500000.0},{"startDate":"2021-09-06","payNo":"DA538/2","levyAmt":8750.0,"estimatedCost":2500000.0},{"startDate":"2021-12-06","payNo":"DA538/3","levyAmt":8750.0,"estimatedCost":2500000.0},{"startDate":"2022-03-07","payNo":"DA538/4","levyAmt":8750.0,"estimatedCost":2500000.0}]'; 
        cases[0].LSC_Number_of_Instalments__c = '4';

        insert cases;

        cases[0].status = 'Closed Approved';

        Test.startTest();
           
            update cases;
        Test.stopTest();

    }

    
    static testMethod void testExemptionTransaction() {
        //Status
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        insert levyList;


        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Exemption').getRecordTypeId();
        List<Case> cases = LSC_TestDataFactory.createCase(1, accounts[0], contacts[0], levyList[0], caseRT);
        cases[0].Status = 'Awaiting Approving Authority';
        cases[0].LSC_ApprovedVoluntaryLabourCost__c = 34000;
        
        insert cases;

        cases[0].status = 'Closed Approved';

        Test.startTest();
           
            update cases;
        Test.stopTest();

    }

    static testMethod void testExemptionRejectedTransaction() {
        //Status
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        insert levyList;


        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Exemption').getRecordTypeId();
        List<Case> cases = LSC_TestDataFactory.createCase(1, accounts[0], contacts[0], levyList[0], caseRT);
        cases[0].Status = 'Awaiting Approving Authority';
        cases[0].LSC_ApprovedVoluntaryLabourCost__c = 34000;
        cases[0].LSC_RejectionReasons__c = 'ABCD';
        
        insert cases;

        cases[0].status = 'Closed Rejected';

        Test.startTest();
           
            update cases;
        Test.stopTest();

    }

    static testMethod void testInstalmentRejectedTransaction() {
        //Status
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        insert levyList;


        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Instalment').getRecordTypeId();
        List<Case> cases = LSC_TestDataFactory.createCase(1, accounts[0], contacts[0], levyList[0], caseRT);
        cases[0].Status = 'Awaiting Approving Authority';
        cases[0].LSC_ApprovedVoluntaryLabourCost__c = 34000;
        cases[0].LSC_RejectionReasons__c = 'ABCD';
        
        insert cases;

        cases[0].status = 'Closed Rejected';

        Test.startTest();
           
            update cases;
        Test.stopTest();

    }

    static testMethod void testUnusedMethod() {

        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        insert levyList;   

        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Instalment').getRecordTypeId();
        List<Case> cases = LSC_TestDataFactory.createCase(1, accounts[0], contacts[0], levyList[0], caseRT);
        cases[0].Status = 'Awaiting Approving Authority';
        cases[0].LSC_ApprovedVoluntaryLabourCost__c = 34000;
        cases[0].LSC_RejectionReasons__c = 'ABCD';
        
        insert cases;

        Map<Id, SObject> items = new Map<Id, SObject>();
        items.put(cases[0].Id, cases[0]);

        Test.startTest();
        LSC_CaseTriggerHandler handler = new LSC_CaseTriggerHandler();
            handler.BeforeDelete(items); 
            handler.AfterInsert(items);
            handler.AfterDelete(items);
            handler.AfterUndelete(items);
        	handler.isDisabled();
        Test.stopTest();
    }

}