public class LSC_CreateTransactionRecordFromCase {

    public static void createCaseAndSetTransactionAttributes (List<Case> caseList){

        Id refundRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_CASE_RECORDTYPENAME_REFUND).getRecordTypeId();
        Id exemptionRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_CASE_RECORDTYPENAME_EXEMPTION).getRecordTypeId();
        Id instalmentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_CASE_RECORDTYPENAME_INSTALMENT).getRecordTypeId();

        Id transactionRefundRecordTypeId = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_REFUND).getRecordTypeId();
        Id transactionLevyRecordTypeId = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_LEVY).getRecordTypeId();
        Id transactionInstalmentRecordTypeId = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_TRANSACTION_RECORDTYPENAME_INSTALMENT).getRecordTypeId();
        
        Map<String, Decimal> caseExemptionMap = new Map<String, Decimal>();        
        Map<String, Decimal> caseCostOfWorkMap = new Map<String, Decimal>();
        Map<String, String> caseToLevyStatusMap = new Map<String, String>();
        Map<String, Decimal> caseExemptionRejectedMap = new Map<String, Decimal>();

        List<LSC_Transaction__c > transactionList = new List<LSC_Transaction__c >();
        for(Case caseIter : caseList) {
            if (instalmentRecordTypeId == caseIter.RecordTypeId && caseIter.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_APPROVED){
                List<InstalmentDetailsWrapper> wrapperList = (List<InstalmentDetailsWrapper>) System.JSON.deserialize(caseIter.LSC_InstalmentDetails__c, List<InstalmentDetailsWrapper>.class);

                if (caseIter.LSC_Number_of_Instalments__c != null && Integer.valueOf(caseIter.LSC_Number_of_Instalments__c) != 4){
                    if (caseIter.LSC_LevyId__r.LSC_ConstructionEndDate__c != null && caseIter.LSC_LevyId__r.LSC_ConstructionStartDate__c != null){
                        Integer numOfStage = Integer.valueOf(caseIter.LSC_Number_of_Instalments__c);
                        Integer numberDaysDue = caseIter.LSC_LevyId__r.LSC_ConstructionStartDate__c.daysBetween(caseIter.LSC_LevyId__r.LSC_ConstructionEndDate__c);
                        Integer intervalDays = (numberDaysDue/numOfStage); 
                        Decimal totalLevy = caseIter.LSC_LevyId__r.LSC_TotalLevyPayable__c;
                        Integer numofDays = 0;
                        Decimal firstStagePay = 0; 
                        for (Integer i = 1; i <= numOfStage; i++){
                            LSC_Transaction__c  approvedInstalmentTransactionObj      = new LSC_Transaction__c ();
                            approvedInstalmentTransactionObj.LSC_LevyId__c            = caseIter.LSC_LevyId__c;
                            approvedInstalmentTransactionObj.RecordTypeId             = transactionInstalmentRecordTypeId;
                            approvedInstalmentTransactionObj.LSC_Status__c            = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
                            approvedInstalmentTransactionObj.LSC_DueDate__c           = caseIter.LSC_LevyId__r.LSC_ConstructionStartDate__c.addDays(numofDays); 
                            approvedInstalmentTransactionObj.LSC_Amount__c            = (totalLevy/numOfStage).round(System.RoundingMode.DOWN);  
                            approvedInstalmentTransactionObj.LSC_Comments__c          = caseIter.Type;
                            approvedInstalmentTransactionObj.LSC_CaseId__c            = caseIter.Id;
                            approvedInstalmentTransactionObj.LSC_Stage__c             = String.valueOf(i);
                            approvedInstalmentTransactionObj.LSC_RepEmail__c          = (caseIter.LSC_LevyId__r != null && caseIter.LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r != null) ? caseIter.LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r.Email : null;
                            numofDays = (intervalDays * (i));
                            if (i == 1){
                                firstStagePay = (totalLevy/numOfStage).round(System.RoundingMode.DOWN);     
                            }
                            transactionList.add(approvedInstalmentTransactionObj);    
                        }
                        if (transactionList.size() > 0){
                            for (LSC_Transaction__c tran : transactionList){
                                if (tran.LSC_Stage__c == '1'){
                                    tran.LSC_Amount__c =  firstStagePay + (totalLevy - (firstStagePay *numOfStage));
                                }
                            }
                        }                        
                    }
                }else{
                    for (InstalmentDetailsWrapper wrapper : wrapperList){
                        if (wrapper.levyAmt > 0){
                            LSC_Transaction__c  approvedInstalmentTransactionObj      = new LSC_Transaction__c ();
                            approvedInstalmentTransactionObj.LSC_LevyId__c            = caseIter.LSC_LevyId__c;
                            approvedInstalmentTransactionObj.RecordTypeId             = transactionInstalmentRecordTypeId;
                            approvedInstalmentTransactionObj.LSC_Status__c            = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
                            approvedInstalmentTransactionObj.LSC_DueDate__c           = caseIter.Type == LSC_GlobalConstants.LSC_CASE_STAGE_INSTALMENT_TYPE ? setStagedDateStringToDateFormat(wrapper.startDate) : setStringToDateFormat(wrapper.startDate);
                            approvedInstalmentTransactionObj.LSC_Amount__c            = wrapper.levyAmt; 
                            approvedInstalmentTransactionObj.LSC_Comments__c          = caseIter.Type;
                            approvedInstalmentTransactionObj.LSC_CaseId__c            = caseIter.Id;
                            approvedInstalmentTransactionObj.LSC_Stage__c             = wrapper.payNo;
                            approvedInstalmentTransactionObj.LSC_RepEmail__c          = (caseIter.LSC_LevyId__r != null && caseIter.LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r != null) ? caseIter.LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r.Email : null;
                            transactionList.add(approvedInstalmentTransactionObj);
                        }
                    }
                }
                
                if (caseIter.LSC_LevyId__r != null){
                    caseToLevyStatusMap.put(caseIter.LSC_LevyId__r.Id, LSC_GlobalConstants.LSC_LEVY_APPLICATION_STATUS);
                }
            }else if (!(instalmentRecordTypeId == caseIter.RecordTypeId && caseIter.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_APPROVED)){
                LSC_Transaction__c  transactionObj      = new LSC_Transaction__c ();
                transactionObj.LSC_LevyId__c            = caseIter.LSC_LevyId__c;
                if (refundRecordTypeId == caseIter.RecordTypeId){
                    transactionObj.RecordTypeId         = transactionRefundRecordTypeId;
                    transactionObj.LSC_Status__c        = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
                    transactionObj.LSC_DueDate__c       =  caseIter.ClosedDate == null ? null : date.newinstance(caseIter.ClosedDate.year(), caseIter.ClosedDate.month(), caseIter.ClosedDate.day()) ;
                    transactionObj.LSC_Amount__c        = caseIter.LSC_Amount__c;          
                    transactionObj.LSC_AccountName__c       = caseIter.LSC_AccountName__c;  
                    transactionObj.LSC_AccountNo__c         = String.isNotBlank(caseIter.LSC_AccountNo__c) ? caseIter.LSC_AccountNo__c.deleteWhitespace() : null;
                    transactionObj.LSC_BSB__c               = caseIter.LSC_BSB__c ;
                    transactionObj.LSC_BankCode__c          = caseIter.LSC_BankCode__c;
                    transactionObj.LSC_CaseId__c            = caseIter.Id;
                    transactionObj.LSC_PaymentReference__c  = caseIter.LSC_TransactionLineItemId__r != null ? caseIter.LSC_TransactionLineItemId__r.LSC_PaymentReference__c : null;
                    transactionObj.LSC_RepEmail__c          = (caseIter.LSC_LevyId__r != null && caseIter.LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r != null) ? caseIter.LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r.Email : null;
                            
                    transactionObj.LSC_PaymentMethod__c     = LSC_GlobalConstants.LSC_CASE_REFUND_PAYMENT_METHOD;        
                    if(caseIter.LSC_TransactionLineItemId__c != null && caseIter.LSC_AccountNo__c == null) {
                        if (caseIter.LSC_TransactionLineItemId__r.LSC_PaymentMethod__c == LSC_GlobalConstants.LSC_CASE_REFUND_CARD_PAYMENT_METHOD ||
                            caseIter.LSC_TransactionLineItemId__r.LSC_PaymentMethod__c == LSC_GlobalConstants.LSC_CASE_REFUND_PAYPAL_PAYMENT_METHOD){
                            transactionObj.LSC_PaymentMethod__c = caseIter.LSC_TransactionLineItemId__r.LSC_PaymentMethod__c;
                        }                        
                    }
                    transactionObj.LSC_BranchName__c        = caseIter.LSC_BranchName__c;
                }
                if (exemptionRecordTypeId == caseIter.RecordTypeId && caseIter.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_APPROVED){
                    transactionObj.RecordTypeId         = transactionLevyRecordTypeId;
                    transactionObj.LSC_Status__c        = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
                    transactionObj.LSC_DueDate__c       = caseIter.LSC_LevyId__r.LSC_ConstructionStartDate__c != null ? caseIter.LSC_LevyId__r.LSC_ConstructionStartDate__c.addDays(-1) : null;
                    transactionObj.LSC_Amount__c        = caseIter.LSC_LevyId__r.LSC_TotalLevyPayable__c.round(System.RoundingMode.DOWN);       
                    transactionObj.LSC_RepEmail__c      = (caseIter.LSC_LevyId__r != null && caseIter.LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r != null) ? caseIter.LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r.Email : null;             
                    if (caseIter.LSC_LevyId__r != null){
                        if (caseIter.LSC_ApprovedVoluntaryLabourCost__c != null){
                            caseExemptionMap.put(caseIter.LSC_LevyId__r.Id, caseIter.LSC_ApprovedVoluntaryLabourCost__c);
                            caseCostOfWorkMap.put(caseIter.LSC_LevyId__r.Id, caseIter.LSC_LevyId__r.LSC_CostOfWorks__c);
                            transactionObj.LSC_Amount__c = ((caseIter.LSC_LevyId__r.LSC_CostOfWorks__c * 0.0035).round(System.RoundingMode.DOWN) - caseIter.LSC_Exemption_Amount__c);
                        } 
                        if (caseIter.LSC_LevyId__r != null){
                            caseToLevyStatusMap.put(caseIter.LSC_LevyId__r.Id, LSC_GlobalConstants.LSC_LEVY_APPLICATION_STATUS);
                        }                        
                    }                                       
                }                

                if (exemptionRecordTypeId == caseIter.RecordTypeId && caseIter.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_REJECTED){
                    transactionObj.RecordTypeId         = transactionLevyRecordTypeId;
                    transactionObj.LSC_Status__c        = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
                    transactionObj.LSC_DueDate__c       = caseIter.LSC_LevyId__r.LSC_ConstructionStartDate__c != null ? caseIter.LSC_LevyId__r.LSC_ConstructionStartDate__c.addDays(-1) : null;
                    transactionObj.LSC_Amount__c        = (caseIter.LSC_LevyId__r.LSC_CostOfWorks__c * 0.0035).round(System.RoundingMode.DOWN); 
                    transactionObj.LSC_RepEmail__c      = (caseIter.LSC_LevyId__r != null && caseIter.LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r != null) ? caseIter.LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r.Email : null;
                    if (caseIter.LSC_LevyId__r != null){
                        caseToLevyStatusMap.put(caseIter.LSC_LevyId__r.Id, LSC_GlobalConstants.LSC_LEVY_APPLICATION_STATUS);
                        caseExemptionRejectedMap.put(caseIter.LSC_LevyId__r.Id, (caseIter.LSC_LevyId__r.LSC_CostOfWorks__c * 0.0035));
                    }
                }  
            
                if (instalmentRecordTypeId == caseIter.RecordTypeId && caseIter.Status == LSC_GlobalConstants.LSC_CASE_STATUS_CLOSED_REJECTED){
                    transactionObj.RecordTypeId         = transactionLevyRecordTypeId;
                    transactionObj.LSC_RepEmail__c      = (caseIter.LSC_LevyId__r != null && caseIter.LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r != null) ? caseIter.LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r.Email : null;
                    transactionObj.LSC_Status__c        = LSC_GlobalConstants.LSC_TRANSACTION_STATUS_PENDING;
                    transactionObj.LSC_DueDate__c       = caseIter.LSC_LevyId__r.LSC_ConstructionStartDate__c != null ? caseIter.LSC_LevyId__r.LSC_ConstructionStartDate__c.addDays(-1) : null;
                    transactionObj.LSC_Amount__c        = caseIter.LSC_LevyId__r.LSC_TotalLevyPayable__c.round(System.RoundingMode.DOWN); 
                    if (caseIter.LSC_LevyId__r != null){
                        caseToLevyStatusMap.put(caseIter.LSC_LevyId__r.Id, LSC_GlobalConstants.LSC_LEVY_APPLICATION_STATUS);
                    } 
                }             
                       
                transactionObj.LSC_Comments__c          = caseIter.Type;
                transactionObj.LSC_CaseId__c            = caseIter.Id;

                transactionList.add(transactionObj);
            }       
        } 

        List<LSC_Levy__c> levyList = new List<LSC_Levy__c>();
        if (!caseExemptionMap.isEmpty()){            
            for (String key: caseExemptionMap.keySet()){
                Decimal approvedAmount = caseExemptionMap.get(key);
                Decimal costOfWork =  caseCostOfWorkMap.get(key).round(System.RoundingMode.DOWN);
                Decimal voluntaryWork =  approvedAmount;
                LSC_Levy__c levy = new LSC_Levy__c();
                levy.id = key;
                if (approvedAmount > 0){
                    levy.LSC_ApprovedVoluntaryLabourcost__c  = voluntaryWork;
                    levy.LSC_LevyPayable__c  = (((costOfWork) * 0.0035).round(System.RoundingMode.DOWN));
                } 
                levy.LSC_ApplicationStatus__c = LSC_GlobalConstants.LSC_LEVY_APPLICATION_STATUS;
                levyList.add(levy);
            }
        }

        if(!caseExemptionRejectedMap.isEmpty()){
            for (String key: caseExemptionRejectedMap.keySet()){
                System.debug('caseExemptionRejectedMap'+caseExemptionRejectedMap);
                LSC_Levy__c levy = new LSC_Levy__c();
                levy.id = key;              
                levy.LSC_LevyPayable__c  =  ((caseExemptionRejectedMap.get(key)).round(System.RoundingMode.DOWN)); //Math.floor(caseExemptionRejectedMap.get(key));
                levy.LSC_ApplicationStatus__c = LSC_GlobalConstants.LSC_LEVY_APPLICATION_STATUS;
                levy.LSC_ApprovedVoluntaryLabourcost__c  = 0;
                levyList.add(levy);
            }    
        }
        
        System.debug('levyList value--->'+levyList);
        System.debug('transactionList value--->'+transactionList);
        if(levyList.size() > 0) {
            update levyList;
        }

        if(transactionList.size() > 0) {
            insert transactionList;
        }
    }

    private static Date setStringToDateFormat(String myDate)
    {
        String[] myDateOnly = myDate.split('-');
        Integer day = integer.valueOf(myDateOnly.get(0));
        Integer month = integer.valueOf(myDateOnly.get(1));
        Integer year = integer.valueOf(myDateOnly.get(2));
        Date d = Date.newInstance(year, month, day);
        return d;
    }

    private static Date setStagedDateStringToDateFormat(String myDate)
    {
        String[] myDateOnly = myDate.split('-');
        Integer day = integer.valueOf(myDateOnly.get(2));
        Integer month = integer.valueOf(myDateOnly.get(1));
        Integer year = integer.valueOf(myDateOnly.get(0));
        Date d = Date.newInstance(year, month, day);
        return d;
    }

    
    public static void createTransactionFromCase (List<Id> caseIdList){
        List <Case> caseList = getAllRelatedCaseDetails(caseIdList);
        createCaseAndSetTransactionAttributes(caseList);
    }

    private static List <Case> getAllRelatedCaseDetails (List<Id> caseIdList){

        String query ='';
        String sobjectApiName = 'Case';
        String strFields = LSC_QueryUtils.getFieldNameForAnObject('Case');       
        String referenceFields = ', LSC_TransactionLineItemId__r.LSC_PaymentReference__c, LSC_LevyId__r.LSC_AuthorisedRepresentativeId__r.Email, LSC_LevyId__r.LSC_ConstructionEndDate__c, LSC_LevyId__r.LSC_ConstructionStartDate__c, LSC_TransactionLineItemId__r.LSC_PaymentMethod__c, LSC_LevyId__r.LSC_LevyPayable__c , LSC_LevyId__r.LSC_TotalLevyPayable__c, LSC_LevyId__r.LSC_CostOfWorks__c, LSC_LevyId__r.LSC_VoluntaryLabourCostofWorks__c, LSC_LevyId__r.LSC_ExemptionPercentage__c ';

        query = 'select ' + strFields + referenceFields+ ' from ' + SobjectApiName + ' where Id IN:caseIdList';
       
        List <Case> caseList = Database.query(query);

        System.debug('caseItem value--->'+caseList);
        for (Case caseItem : caseList){
            System.debug('caseItem Name--->'+caseItem);
        }
        return caseList;
    }

    public class InstalmentDetailsWrapper {
        public String startDate;
        public String stage;
        public String presetInstal;
        public String payNo;
        public Double levyAmt;
        public String id;
        public Double estimatedCost;
        public String dueDate;
    }
    
}