public with sharing class LSC_CouncilImportController {
    @AuraEnabled
    public static List<ReportLine> getReport(String recordId, String year, String month) {
        List<ReportLine> report = new List<ReportLine>();
        Date d = Date.newInstance(Integer.valueOf(year), Integer.valueOf(month), 1);
        Map<Id,ReportLine> mapLevyReport = new Map<Id,ReportLine>();
        List<LSC_Levy__c> levies = [SELECT Id, LSC_ApplicationType__c, LSC_TotalOverpaymentAmount__c, LSC_ApplicationNumber__c, LSC_Comments__c, LSC_CostOfWorks__c, LSC_LevyPayable__c, LSC_TotalPaidCredit__c, LSC_TotalAmountDue__c FROM LSC_Levy__c WHERE LSC_AccountId__c = :recordId AND LSC_CouncilImportDate__c = :d AND (LSC_TotalAmountDue__c > 50 OR LSC_TotalOverpaymentAmount__c > 50)];
        for(LSC_Levy__c l : levies) {
            ReportLine rl = new ReportLine();
            rl.type = l.LSC_ApplicationType__c;
            rl.no = l.LSC_ApplicationNumber__c;
            rl.cost = l.LSC_CostOfWorks__c;
            rl.payable = l.LSC_LevyPayable__c;
            rl.paid = l.LSC_TotalPaidCredit__c;
            rl.comment = l.LSC_Comments__c;
            rl.id = l.Id;
            if(l.LSC_TotalAmountDue__c > 50) {
                rl.reason = 'Underpayment amount is $' + String.valueOf(l.LSC_TotalAmountDue__c.setScale(2));
            }
            else if(l.LSC_TotalOverpaymentAmount__c > 50) {
                rl.reason = 'Overpayment amount is $' + String.valueOf(l.LSC_TotalOverpaymentAmount__c.setScale(2));
            } 
            report.add(rl);
        }
        List<LSC_TransactionLineItem__c> tlis = [SELECT Id, LSC_Amount__c, LSC_TotalAmount__c, LSC_TransactionId__r.LSC_LevyId__c, LSC_TransactionId__r.LSC_CommissionAmount__c, LSC_TransactionId__r.LSC_LevyId__r.LSC_ApplicationType__c, LSC_TransactionId__r.LSC_LevyId__r.LSC_ApplicationNumber__c, LSC_TransactionId__r.LSC_LevyId__r.LSC_Comments__c,
                                                        LSC_TransactionId__r.LSC_LevyId__r.LSC_CostOfWorks__c, LSC_TransactionId__r.LSC_LevyId__r.LSC_LevyPayable__c, LSC_TransactionId__r.LSC_LevyId__r.LSC_TotalPaidCredit__c FROM LSC_TransactionLineItem__c WHERE LSC_TransactionId__r.LSC_LevyId__r.LSC_AccountId__c = :recordId AND RecordType.Name = 'Commission' AND LSC_TransactionId__r.LSC_LevyId__r.LSC_TotalCommissionAmount__c <> :LSC_GlobalConstants.LSC_COUNCIL_COMMISSION_FEE AND LSC_TransactionId__r.LSC_LevyId__r.LSC_CouncilImportDate__c = :d];
        for(LSC_TransactionLineItem__c tli : tlis) {
            Id levyId = tli.LSC_TransactionId__r.LSC_LevyId__c;
            ReportLine rl = new ReportLine();
            rl.type = tli.LSC_TransactionId__r.LSC_LevyId__r.LSC_ApplicationType__c;
            rl.no = tli.LSC_TransactionId__r.LSC_LevyId__r.LSC_ApplicationNumber__c;
            rl.cost = tli.LSC_TransactionId__r.LSC_LevyId__r.LSC_CostOfWorks__c;
            rl.payable = tli.LSC_TransactionId__r.LSC_LevyId__r.LSC_LevyPayable__c;
            rl.paid = tli.LSC_TransactionId__r.LSC_LevyId__r.LSC_TotalPaidCredit__c;
            rl.id = tli.Id;
            rl.comment = tli.LSC_TransactionId__r.LSC_LevyId__r.LSC_Comments__c;
            rl.commission = tli.LSC_TotalAmount__c;
            if(!mapLevyReport.containsKey(levyId)){
                mapLevyReport.put(levyId,rl);
            }else{
                ReportLine existingRLine = mapLevyReport.get(levyId);
                rl.commission = rl.commission + existingRLine.commission;
                mapLevyReport.get(levyId).commission = rl.commission;
            }
        }
        for (Id levyId: mapLevyReport.keySet()){
           
            Decimal levyCommission = mapLevyReport.get(levyId).commission;
            String reason;
            if(levyCommission > LSC_GlobalConstants.LSC_COUNCIL_COMMISSION_FEE) {
                reason = 'Overpaid Commission amount(Inc GST) is $' + String.valueOf((levyCommission -LSC_GlobalConstants.LSC_COUNCIL_COMMISSION_FEE).setScale(2));
            }
            else if(levyCommission < LSC_GlobalConstants.LSC_COUNCIL_COMMISSION_FEE) {
                reason = 'Underpaid Commission amount(Inc GST) is $' + String.valueOf((LSC_GlobalConstants.LSC_COUNCIL_COMMISSION_FEE-levyCommission).setScale(2));
            }
            mapLevyReport.get(levyId).reason = reason;
        }
        report.addAll(mapLevyReport.values());
        return report;
    } 
    
    @AuraEnabled(cacheable=true)
    public static List<LSC_Levy__c> getLevyRecords(String recordId) {
        try{
        	return [Select Id, LSC_CouncilImportDate__c, LSC_Nil_Return__c, LSC_Comments__c from LSC_Levy__c where LSC_AccountId__c =: recordId AND LSC_LevySource__c = 'Council' AND LSC_CouncilImportDate__c != Null];     
        }
        catch(exception Ex){
            return null;
        }
    }

    @AuraEnabled
    public static ResultWrapper createRecords(List<Map<String,String>> records, String recordId, String year, String month) {
        Savepoint sp = Database.setSavepoint();
        try {
            if(records != null && records.size() > 0 && recordId != null && recordId.length() > 0) {
                Date d = Date.newInstance(Integer.valueOf(year), Integer.valueOf(month), 1);
                List<Account> acc = [SELECT Name FROM Account WHERE Id = :recordId];
                List<String> numbers = new List<String>();
                Set<String> errorRecords = new Set<String>();     
                List<LSC_Levy__c> newLevies = new List<LSC_Levy__c>();
                List<LSC_Transaction__c> newTransactions = new List<LSC_Transaction__c>();
                List<LSC_TransactionLineItem__c> newTLIs = new List<LSC_TransactionLineItem__c>();           
                String errorRecordsList;
                for(Map<String,String> record : records) {
                    numbers.add(record.get('AppNumber'));
                }
                List<LSC_Levy__c> existingLevies = [SELECT Id, LSC_ApplicationNumber__c FROM LSC_Levy__c WHERE LSC_ApplicationNumber__c IN :numbers];
                if(existingLevies != null && existingLevies.size() > 0) {
                    errorRecordsList = '';
                    for(LSC_Levy__c l : existingLevies) {
                        errorRecords.add(l.LSC_ApplicationNumber__c);
                        errorRecordsList += l.LSC_ApplicationNumber__c + ' ';
                    }
                    Integer i = 0;
                    while(i < records.size()) {
                        if(errorRecords.contains(records[i].get('AppNumber'))) {
                            records.remove(i);
                        }
                        else {
                            i++;
                        }
                    }
                }
                if(records != null && records.size() > 0) {
                    for(Map<String,String> record : records) {
                        LSC_Levy__c l = new LSC_Levy__c();
                        LSC_Transaction__c t = new LSC_Transaction__c();
                        LSC_TransactionLineItem__c tli1 = new LSC_TransactionLineItem__c();
                        LSC_TransactionLineItem__c tli2 = new LSC_TransactionLineItem__c();
                        
                        if(record.get('Type') == 'CC') {
                            l.LSC_ApplicationType__c = 'Construction Certificate';
                        }
                        else if(record.get('Type') == 'DA') {
                            l.LSC_ApplicationType__c = 'Development Application';
                        }
                        else if(record.get('Type') == 'CDC') {
                            l.LSC_ApplicationType__c = 'Complying Development Certificate';
                        }
                        else if(record.get('Type') == 'CONTRACT') {
                            l.LSC_ApplicationType__c = 'Council Contract';
                        }               
                        else if(record.get('Type') == 'GC') {
                            l.LSC_ApplicationType__c = 'Government Contract';
                        }   
                        else if(record.get('Type') == 'CCE') {
                            l.LSC_ApplicationType__c = 'Construction Certificate Engineering';
                        }                           
                        else if(record.get('Type') == 'GDA') {
                            l.LSC_ApplicationType__c = 'Government Development Application';
                        }                                                                                    
                        else if(record.get('Type') == 'BA') {
                            l.LSC_ApplicationType__c = 'Building Approval';
                        }   
                        else if(record.get('Type') == 'BC') {
                            l.LSC_ApplicationType__c = 'Building Certificate';
                        }   
                        else if(record.get('Type') == 'CCB') {
                            l.LSC_ApplicationType__c = 'Construction Certificate Building';
                        }   
                        else if(record.get('Type') == 'SWC') {
                            l.LSC_ApplicationType__c = 'Subdivision Works Certificate';
                        }   
                        else if(record.get('Type') == 'SCC') {
                            l.LSC_ApplicationType__c = 'Subdivision Constriction Certificate';
                        }   
                        else if(record.get('Type') == 'LD') {
                            l.LSC_ApplicationType__c = 'Local Development';
                        }   
                        else if(record.get('Type') == 'CW') {
                            l.LSC_ApplicationType__c = 'Civil Works Construction Certificate';
                        }   
                        else if(record.get('Type') == 'PCDC') {
                            l.LSC_ApplicationType__c = 'Private Complying Development Certificate';
                        }   
                        else if(record.get('Type') == 'PWC') {
                            l.LSC_ApplicationType__c = 'Public Works Certificate';
                        }   
                        else if(record.get('Type') == 'SDCC') {
                            l.LSC_ApplicationType__c = 'Subdivision Construction Certificate';
                        }   
                        else if(record.get('Type') == 'DA/CC') {
                            l.LSC_ApplicationType__c = 'Combined DA/CC';
                        }   
                        else if(record.get('Type') == 'S68') {
                            l.LSC_ApplicationType__c = 'S68 Mobile Homes';
                        }   
                        
                        l.LSC_ApplicationNumber__c = record.get('AppNumber');
                        l.LSC_AccountId__c = recordId;
                        if(acc != null && acc.size() > 0 && record.get('Type') != 'PWC' && record.get('Type') != 'GC' && record.get('Type') != 'GDA') {
                            l.LSC_LocalGovtAreaOrGovtAuthority__c = acc[0].Name;
                        }
                        l.LSC_SiteAddressStreet__c = record.get('Street');
                        l.LSC_SiteAddressState__c = 'NSW';
                        l.LSC_SiteAddressPostCode__c = record.get('PostCode');
                        l.LSC_SiteAddressCountry__c = 'Australia';
                        l.LSC_SiteAddressCity__c = record.get('City');
                        l.LSC_CouncilImportDate__c = d;
                        l.LSC_CostOfWorks__c = Double.valueOf(record.get('Cost'));
                        l.LSC_LevyPayable__c = Math.floor(l.LSC_CostOfWorks__c*0.0035);
                        if(l.LSC_LevyPayable__c - 50 < Double.valueOf(record.get('PaidAmount'))) {
                            l.LSC_ApplicationStatus__c = 'Paid';
                        }
                        else {
                            l.LSC_ApplicationStatus__c = 'Ready to be paid';
                        }
                        l.LSC_LevySource__c = 'Council';
                        l.RecordTypeId = Schema.SObjectType.LSC_Levy__c.getRecordTypeInfosByName().get('BCI').getRecordTypeId();
                        l.LSC_Comments__c = record.get('Comments');

                        t.RecordTypeId = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get('Levy').getRecordTypeId();
                        if(l.LSC_ApplicationStatus__c == 'Paid') {
                            t.LSC_Status__c = 'Paid';
                        }
                        else {
                            t.LSC_Status__c = 'Pending';
                        }
                        
                        t.LSC_Amount__c = l.LSC_LevyPayable__c;
                        t.LSC_PaymentDate__c = Date.today();
                        t.LSC_PaymentMethod__c = 'Agency';
                        t.LSC_TransactionSource__c = 'Council';

                        tli1.RecordTypeId = Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get('Payment').getRecordTypeId();
                        tli1.LSC_Amount__c = Double.valueOf(record.get('PaidAmount'));
                        if(tli1.LSC_Amount__c < 0) {
                            tli1.LSC_Amount__c = 0;
                        }
                        tli1.LSC_AccountId__c = recordId;
                        
                        tli1.LSC_PaymentDate__c = Date.today();
                        tli1.LSC_PaymentMethod__c = 'Agency';
                        tli1.LSC_ReceiptDate__c = Date.today();
                        tli1.LSC_Status__c = 'Paid';
                        tli1.LSC_AccountId__c = recordId;

                        tli2.RecordTypeId = Schema.SObjectType.LSC_TransactionLineItem__c.getRecordTypeInfosByName().get('Commission').getRecordTypeId();
                        tli2.LSC_Amount__c = Double.valueOf(record.get('Commission'));
                        tli2.LSC_GST__c = Double.valueOf(record.get('GST'));
                        tli2.LSC_AccountId__c = recordId;
                        tli2.LSC_PaymentDate__c = Date.today();
                        tli2.LSC_PaymentMethod__c = 'Agency';
                        tli2.LSC_ReceiptDate__c = Date.today();
                        tli2.LSC_Status__c = 'Paid';  
                        tli1.LSC_AccountId__c = recordId;
                        
                        newLevies.add(l);
                        newTransactions.add(t);
                        newTLIs.add(tli1);
                        newTLIs.add(tli2);
                    }  
                    insert newLevies;
                    for(Integer i = 0; i < newLevies.size(); i++) {
                        newTransactions[i].LSC_LevyId__c = newLevies[i].Id;
                    }
                    insert newTransactions;
                    for(Integer i = 0; i < newTransactions.size(); i++) {
                        newTLIs[i*2].LSC_TransactionId__c = newTransactions[i].Id;
                        newTLIs[i*2 + 1].LSC_TransactionId__c = newTransactions[i].Id;
                    }
                    insert newTLIs;
                    return new ResultWrapper(true, null, errorRecordsList);
                }
                else {
                    return new ResultWrapper(true, null, errorRecordsList);
                }
            }
            else {
                return new ResultWrapper(false, 'There are no records to create', null);    
            }
        }
        catch(Exception ex) {
            Database.rollback(sp);
            return new ResultWrapper(false, ex.getMessage(), null);
        }                
    } 

    public class ReportLine {
        @AuraEnabled
        public String period { get; set; }

        @AuraEnabled
        public String type { get; set; }
        
        @AuraEnabled
        public String no { get; set; }

        @AuraEnabled
        public Double cost { get; set; }
        
        @AuraEnabled
        public Double payable { get; set; }
        
        @AuraEnabled
        public Double paid { get; set; }     
        
        @AuraEnabled
        public String reason { get; set; }  

        @AuraEnabled
        public String comment { get; set; }

        @AuraEnabled
        public String id { get; set; }
        
        @AuraEnabled
        public Double commission { get; set; }
        
        public ReportLine() {

        }
    }
    
    @TestVisible
    public class ResultWrapper {
        @AuraEnabled
        public Boolean isSuccess {get; set;}      
        
        @AuraEnabled
        public String error {get; set;}   

        @AuraEnabled
        public String errorRecords {get; set;}
        
        public ResultWrapper(Boolean isSuccess, String error, String errorRecords) {
            this.isSuccess = isSuccess;
            this.error = error;
            this.errorRecords = errorRecords;
        }
    } 
}