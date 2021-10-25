@istest
private class LSC_LevyTriggerHandlerTest {
    static testMethod void testPayableLevy() {
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        levyList[0].LSC_LevyPayable__c = null;
        Test.startTest();
            insert levyList;
        Test.stopTest();

    }

    static testMethod void testNonPayableLevy() {
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        levyList[0].LSC_LevyPayable__c = null;
        levyList[0].LSC_CostOfWorks__c = 23999;
        Test.startTest();
            insert levyList;
        Test.stopTest();
    }
    
    static testMethod void testupdatePayableLevy() {
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        levyList[0].LSC_LevyPayable__c = null;
        levyList[0].LSC_CostOfWorks__c = 25999;
        insert levyList;
        
        Test.startTest();
            levyList[0].LSC_ApplicationStatus__c = 'Awaiting Exemption Decision';
        	levyList[0].LSC_CostOfWorks__c = 23999;
            update levyList;
        Test.stopTest();

    }
    
    static testMethod void testUpdateNonPayableLevy() {
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        levyList[0].LSC_LevyPayable__c = null;
        levyList[0].LSC_CostOfWorks__c = 25999;
        insert levyList;
        
        Test.startTest();
        	levyList[0].LSC_ApplicationStatus__c = 'Awaiting Exemption Decision';
        	levyList[0].LSC_CostOfWorks__c = 27999;
            update levyList;
        Test.stopTest();
    }
    
    static testMethod void testUpdateLevyStatusReadyToPay() {
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        levyList[0].LSC_LevyPayable__c = null;
        levyList[0].LSC_CostOfWorks__c = 25999;
        levyList[0].LSC_ApplicationStatus__c = 'Awaiting Exemption Decision';
        insert levyList;
        
        Test.startTest();        	
        	levyList[0].LSC_ApplicationStatus__c = 'Ready to be paid';
        try{
            update levyList;
        }catch (Exception ex){
            boolean hasMessage = ex.getMessage().contains('Awaiting Exemption Decision can only be changed to Ready to be paid or Cancelled') ? true : false;
            System.assertEquals(true, hasMessage);
        }        
        
        Test.stopTest();
    }
    
    static testMethod void testUpdateLevyStatusInstalmentDecision() {
        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        accounts.get(0).LSC_SyncedWithSAP__c = true;
        accounts.get(0).LSC_SAPBPNo__c = '1234567890';
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;  
        
        List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(1, accounts.get(0), contacts.get(0));
        levyList[0].LSC_LevyPayable__c = null;
        levyList[0].LSC_CostOfWorks__c = 25999;
        levyList[0].LSC_ApplicationStatus__c = 'Awaiting Instalments Decision';
        insert levyList;
        
        Test.startTest();        	
        	levyList[0].LSC_ApplicationStatus__c = 'Ready to be paid';
        try{
            update levyList;
        }catch (Exception ex){
            boolean hasMessage = ex.getMessage().contains('Awaiting Instalments Decision can only be changed to Ready to be paid or Cancelled') ? true : false;
            System.assertEquals(true, hasMessage);
        }        
        
        Test.stopTest();
    }
    
    
}