@istest
private class LSC_CaseControllerExtension_Test {
    static 
    testMethod void ExemptionCaseTest() {
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        insert levyList;


        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Exemption').getRecordTypeId();
        List<Case> cases = LSC_TestDataFactory.createCase(1, accounts[0], contacts[0], levyList[0], caseRT);
        cases[0].Status = 'Closed Approved';
        cases[0].LSC_ApprovedVoluntaryLabourCost__c = 34000;
        
        insert cases;
        
		Test.startTest();
        PageReference pageRef = Page.ExemptionApprovalOwnerBuilder;
        Test.setCurrentPage(pageRef);

        pageRef.getParameters().put('Id', String.valueOf(cases[0].Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(cases[0]);
        LSC_CaseControllerExtension testAccPlan = new LSC_CaseControllerExtension(sc);
        LSC_CaseControllerExtension.getFieldNames();
        Test.stopTest();

    }

    static 
    testMethod void InstallmentCaseTest() {
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
        cases[0].Status = 'Closed Approved';
        cases[0].Type = 'Staged instalments';
        cases[0].LSC_InstalmentDetails__c = '[{"totalLevyAmt":null,"totalCost":null,"startDate":"2021-07-12","showDel":false,"payNo":"375/1","levyAmt":7000.0,"estimatedCost":2000000.0},{"totalLevyAmt":null,"totalCost":null,"startDate":"2021-10-12","showDel":false,"payNo":"375/2","levyAmt":7000.0,"estimatedCost":2000000.0},{"totalLevyAmt":null,"totalCost":null,"startDate":"2022-01-12","showDel":false,"payNo":"375/3","levyAmt":7000.0,"estimatedCost":2000000.0},{"totalLevyAmt":null,"totalCost":null,"startDate":"2022-04-12","showDel":false,"payNo":"375/4","levyAmt":7000.0,"estimatedCost":2000000.0},{"totalLevyAmt":null,"totalCost":null,"startDate":"2022-07-12","showDel":true,"payNo":"375/5","levyAmt":7000.0,"estimatedCost":2000000.0},{"totalLevyAmt":35000.0,"totalCost":1.0E7,"startDate":null,"showDel":null,"payNo":null,"levyAmt":null,"estimatedCost":null}]'; 
        cases[0].LSC_Number_of_Instalments__c = '4';

        insert cases;
		Test.startTest();
        PageReference pageRef = Page.InstalmentApproval;
        Test.setCurrentPage(pageRef);

        pageRef.getParameters().put('Id', String.valueOf(cases[0].Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(cases[0]);
        LSC_CaseControllerExtension testccExt= new LSC_CaseControllerExtension(sc);
        LSC_CaseControllerExtension.getFieldNames();
        
        pageRef = Page.ExemptionApprovalOwnerBuilder;
        Test.setCurrentPage(pageRef);
        
        try{
            pageRef.getParameters().put('Id2', String.valueOf(cases[0].Id));
            sc = new ApexPages.StandardController(cases[0]);
            LSC_CaseControllerExtension testccExt2 = new LSC_CaseControllerExtension(sc);
        }catch(Exception ex){
            System.assertEquals('It looks like there was a problem. Please contact your service desk for further assistance.', ex.getMessage());
        }
        Test.stopTest();
    }
}