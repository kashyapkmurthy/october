/**
* @description       : Retrieves Transaction Details using Transaction ID. 
*                       Also, updates the CPP reference ID returned from CPP on Transaction Record.
* @author            : Surya Reddy
* @last modified on  : 04-19-2021
* @last modified by  : Surya Reddy
* Modifications Log 
* Ver   Date         Author        Modification
* 1.0   04-15-2021   Surya Reddy   Initial Version
**/
public with sharing class LSC_PaymentController {
    @AuraEnabled(cacheable=true)
    public static LSC_FetchCPPPaymentReferenceDetail.PaymentReferenceRequestWrapper getTransactionDetails(String transactionId) {
        
        LSC_FetchCPPPaymentReferenceDetail.PaymentRequest paymentReferenceRequest ;
        LSC_FetchCPPPaymentReferenceDetail.PaymentReferenceRequestWrapper paymentReferenceRequestWrapper;
        
        if(transactionId != null) {
            List<LSC_Transaction__c> lstTransactions = [SELECT Id,LSC_Status__c,LSC_AmountDue__c,LSC_LevyId__r.LSC_ApplicationNumber__c,LSC_LevyId__r.RecordType.Name from LSC_Transaction__c where Id =: transactionId];
            if(lstTransactions != null && lstTransactions.size() > 0){
                for (LSC_Transaction__c recTransaction : lstTransactions){
                    if (recTransaction.LSC_AmountDue__c > 1000000){
                        throw createAuraException('Amount > $1M');
                    }else{
                        if(recTransaction.LSC_Status__c.equals('Pending')){
                            LSC_URL_Setting__mdt cppCallingSystemURLMdt = LSC_URL_Setting__mdt.getInstance(LSC_GlobalConstants.LSC_CUSTOM_METADATA_NAME_CPP_CALLING_SYSTEM_URL);
                            paymentReferenceRequestWrapper = new LSC_FetchCPPPaymentReferenceDetail.PaymentReferenceRequestWrapper();
                            paymentReferenceRequest = new LSC_FetchCPPPaymentReferenceDetail.PaymentRequest(); 
                            paymentReferenceRequest.paymentDescription = 'Long Service BCI Levy';
                            paymentReferenceRequest.amount = recTransaction.LSC_AmountDue__c;
                            paymentReferenceRequest.applicationNumber = recTransaction.LSC_LevyId__r.LSC_ApplicationNumber__c;
                            paymentReferenceRequest.paymentScheme = recTransaction.LSC_LevyId__r.RecordType.Name;
                            paymentReferenceRequest.transactionId = transactionId;
                            paymentReferenceRequest.paymentCaller = cppCallingSystemURLMdt.LSC_URL_Mapping__c;
                            paymentReferenceRequestWrapper.payments = new List<LSC_FetchCPPPaymentReferenceDetail.PaymentRequest>{paymentReferenceRequest};
                                //paymentReferenceRequestWrapper.payments.add();
                                }else{
                                    throw createAuraException('Payment can only be made to pending transactions');  
                                }
                    }
                }
            }else{
                throw createAuraException('Transaction cannot be accessed or Invalid Transaction Id');
            }
        }else{
            throw createAuraException(' TransactionId is Blank.');
        }
        System.debug('paymentReferenceRequestWrapper:::'+paymentReferenceRequestWrapper);
        return paymentReferenceRequestWrapper;
    }
    
    
    //Update Transaction Id and return Payment Redirect URL
    @AuraEnabled
    public static String updatePaymentReferenceId(String transactionId, String paymentReferenceId)   
    {     
        String redirectUrl;
        try{
            if(transactionId != null && paymentReferenceId != null){
                LSC_Transaction__c recTransaction = new LSC_Transaction__c();
                recTransaction.Id = transactionId;
                recTransaction.LSC_PaymentReference__c = paymentReferenceId;
                update recTransaction;
                
                LSC_URL_Setting__mdt cppPaymentRefDetailMdt = LSC_URL_Setting__mdt.getInstance(LSC_GlobalConstants.LSC_CUSTOM_METADATA_NAME_CPP_PAYMENT_REDIRECT_URL);
                redirectUrl = cppPaymentRefDetailMdt.LSC_URL_Mapping__c+paymentReferenceId;
            }
        }catch(DmlException ex){
            throw createAuraException('Error updating Payment reference Id');
        }catch(Exception ex){
            throw createAuraException('Internal Error');
        }
        return redirectUrl;
    }
    
    public static AuraHandledException createAuraException(String message) {
        AuraHandledException auraException = new AuraHandledException(message);
        auraException.setMessage(message);
        system.debug(auraException);
        return auraException;
    }
}