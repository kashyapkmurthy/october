@isTest
public class LSC_PaymentControllerTest {
    @testSetup static void setup() {
        Id sysAdminprofileId = [Select Id from Profile where Profile.Name = 'System Administrator'].Id;
        Id userRleId = [Select Id from UserRole where DeveloperName='LSC_Director'].Id;
        Id transInstalmentRecTypeId = LSC_Transaction__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Instalment').getRecordTypeId();
        Id transInterestRecTypeId = LSC_Transaction__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Interest').getRecordTypeId();
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
            LSC_Levy__c levyRec = new LSC_Levy__c(LSC_AccountId__c = businessAccount.Id);
            insert levyRec;
            List<LSC_Transaction__c> transactionList = new List<LSC_Transaction__c>();
            transactionList.add(new LSC_Transaction__c(LSC_Status__c = 'Pending',LSC_Amount__c=1000, LSC_DueDate__c = Date.today().addDays(-1), RecordTypeId = transInstalmentRecTypeId, LSC_LevyId__c = levyRec.Id));
            transactionList.add(new LSC_Transaction__c(LSC_Status__c = 'Pending', LSC_Amount__c=1100000,LSC_DueDate__c = Date.today().addDays(-1), RecordTypeId = transInstalmentRecTypeId, LSC_LevyId__c = levyRec.Id));
            transactionList.add(new LSC_Transaction__c(LSC_Status__c = 'Pending', LSC_Amount__c=3000,LSC_DueDate__c = Date.today().addDays(-1), RecordTypeId = transInstalmentRecTypeId, LSC_LevyId__c = levyRec.Id));
            insert transactionList;
        }
    }
    
    
    @isTest
    Public static void getTransactionDetailsTest(){       
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        LSC_Transaction__c transactionAmtOver1MRec;
        LSC_Transaction__c transactionPendingRec;
        LSC_Transaction__c transactionPaidRec;
        for (LSC_Transaction__c transactionRec: [SELECT Id,LSC_Amount__c,LSC_Status__c from LSC_Transaction__c]){
            if (transactionRec.LSC_Amount__c > 1000000){
                transactionAmtOver1MRec = transactionRec;
            }else if (transactionRec.LSC_Amount__c == 3000){
                transactionPaidRec = transactionRec;
                transactionPaidRec.LSC_Status__c = 'Paid';
                update transactionPaidRec;
            }else {
                transactionPendingRec = transactionRec;
            }
        }
        System.runAs(currentUser){
            Test.startTest();
            LSC_FetchCPPPaymentReferenceDetail.PaymentReferenceRequestWrapper paymentReftransactionPendingRec =  LSC_PaymentController.getTransactionDetails(transactionPendingRec.Id);
            System.assertEquals(transactionPendingRec.Id, paymentReftransactionPendingRec.payments[0].transactionId,'Transaction data should be returned');
            try{
                LSC_FetchCPPPaymentReferenceDetail.PaymentReferenceRequestWrapper paymentReftransactionInvalidRec =  LSC_PaymentController.getTransactionDetails('123456789');
            }catch(Exception ex){
                System.assert(ex.getMessage().contains('Transaction cannot be accessed or Invalid Transaction Id'),'Transaction ID is invalid');
            }
            try{
                LSC_FetchCPPPaymentReferenceDetail.PaymentReferenceRequestWrapper paymentReftransactionAmtOver1MRec =  LSC_PaymentController.getTransactionDetails(transactionAmtOver1MRec.Id);
            }catch(Exception ex){
                System.assert(ex.getMessage().contains('Amount > $1M'),'Check if Amount > $1M Check');
            }
            try{
                LSC_FetchCPPPaymentReferenceDetail.PaymentReferenceRequestWrapper paymentReftransactionPaidRec =  LSC_PaymentController.getTransactionDetails(transactionPaidRec.Id);
            }catch(Exception ex){
                System.assert(ex.getMessage().contains('Payment can only be made to pending transactions'),'Transaction is Pending or not');
            }
            try{
                LSC_FetchCPPPaymentReferenceDetail.PaymentReferenceRequestWrapper paymentReftransactionNullRec =  LSC_PaymentController.getTransactionDetails(null);
            }catch(Exception ex){
                System.assert(ex.getMessage().contains('TransactionId is Blank.'),'Transaction ID NULL Check');
            }
            Test.stopTest();     
        }  
    } 
    
    @isTest
    Public static void updatePaymentReferenceIdTest(){       
        User currentUser = [Select Id from User where email = 'greg.chapel@gmail.com' Limit 1];
        LSC_Transaction__c transactionRec = [SELECT Id from LSC_Transaction__c where LSC_Status__c = 'Pending' Limit 1];
        LSC_URL_Setting__mdt cppPaymentRefDetailMdt = LSC_URL_Setting__mdt.getInstance(LSC_GlobalConstants.LSC_CUSTOM_METADATA_NAME_CPP_PAYMENT_REDIRECT_URL);
        String paymentReferenceId = 'REF123456';
        System.runAs(currentUser){
            Test.startTest();
            String redirectURL =  LSC_PaymentController.updatePaymentReferenceId(transactionRec.id, paymentReferenceId);
            LSC_Transaction__c transRec = [SELECT Id,LSC_PaymentReference__c from LSC_Transaction__c where LSC_Status__c = 'Pending' Limit 1];  
            System.assertEquals(paymentReferenceId, transRec.LSC_PaymentReference__c,'Payment Reference not Updated');
            System.assertEquals(cppPaymentRefDetailMdt.LSC_URL_Mapping__c+paymentReferenceId, redirectURL, 'Error redirecting to Payment Gateway');
            try{
                redirectURL =  LSC_PaymentController.updatePaymentReferenceId('1234567', paymentReferenceId);
            }catch(Exception ex){
                System.assert(ex.getMessage().contains('Internal Error'),'Internal Error');
            }
            Test.stopTest();  
            
        }
    } 
}