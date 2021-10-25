public with sharing class LSC_LevyRecordController {
    @AuraEnabled(cacheable=true)
    public static List<CaseWrapper> getCases(String id) {
        List<CaseWrapper> results = new List<CaseWrapper>();
        if(id != null) {
            List<Case> cases = [SELECT Id, CaseNumber, Status, Subject, CreatedDate FROM Case WHERE LSC_LevyId__c = :id];
        
            for(Case c : cases) {
                results.add(new CaseWrapper(c));
            }
        }

        return results;
    }
    

    @AuraEnabled(cacheable=true)
    public static EFTWrapper getEFT(String label) {
        LSC_EFTDetails__mdt eft = LSC_EFTDetails__mdt.getInstance(label);
        Id accountId = LSC_LevyPaymentUtility.currentUserAccountId();
        Boolean eftAllowed = [SELECT Id,LSC_EFTPaymentAllowed__c FROM Account WHERE id =: accountId].LSC_EFTPaymentAllowed__c;
        if(eft != null) {
            return new EFTWrapper(eft.LSC_BSB__c, eft.LSC_AccountNumber__c,eftAllowed);
        }
        else {
            return null;
        }
    }    

    @AuraEnabled(cacheable=true)
    public static List<TransactionWrapper> getTransactions(String id) {
        List<TransactionWrapper> results = new List<TransactionWrapper>();
        if(id != null) {
            List<LSC_Transaction__c> transactions = [SELECT Id, Name, LSC_PaymentDate__c, LSC_PaidDate__c, LSC_Stage__c, LSC_TotalAmount__c, LSC_PaidAmount__c, LSC_DueDate__c, LSC_Status__c, RecordType.Name FROM LSC_Transaction__c WHERE LSC_LevyId__c = :id AND RecordType.Name != 'Instalment' AND RecordType.Name != 'Levy'];
            Integer i = 1;
            for(LSC_Transaction__c t : transactions) {
                results.add(new TransactionWrapper(t, i));
                i++;
            }
        }
        return results;
    }    

    @AuraEnabled(cacheable=true)
    public static List<TLIWrapper> getPayments(String id) {
        List<TLIWrapper> results = new List<TLIWrapper>();
        if(id != null) {
            List<LSC_TransactionLineItem__c> tlis = [SELECT Id, LSC_TotalAmount__c, LSC_PaymentDate__c, LSC_Status__c, LSC_TransactionId__r.RecordType.Name FROM LSC_TransactionLineItem__c WHERE LSC_TransactionId__r.LSC_LevyId__c = :id AND RecordType.Name = 'Payment'];
            Integer i = 1;
            for(LSC_TransactionLineItem__c tli : tlis) {
                results.add(new TLIWrapper(tli, i));
                i++;
            }
        }
        return results;
    }    


    @AuraEnabled(cacheable=true)
    public static List<TransactionWrapper> getInstalments(String id) {
        List<TransactionWrapper> results = new List<TransactionWrapper>();
        if(id != null) {
            List<LSC_Transaction__c> transactions = [SELECT Id, Name, LSC_PaymentDate__c, LSC_PaidDate__c, LSC_Stage__c, LSC_TotalAmount__c, LSC_PaidAmount__c, LSC_DueDate__c, LSC_Status__c, RecordType.Name, (SELECT Id FROM TransactionLineItems__r WHERE LSC_Status__c = 'Processing') FROM LSC_Transaction__c WHERE LSC_LevyId__c = :id AND RecordType.Name = 'Instalment' ORDER BY LSC_DueDate__c ASC];
            Integer i = 1;
            for(LSC_Transaction__c t : transactions) {
                TransactionWrapper tw = new TransactionWrapper(t, i);
                if(t.LSC_Status__c != 'Paid') {
                    if(t.TransactionLineItems__r != null && t.TransactionLineItems__r.size() > 0) {
                        tw.buttonClass = 'button-hide';
                    }
                }
                results.add(tw);
                i++;
            }            
        }
        return results;
    }      

    @AuraEnabled
    public static String deleteDocument(String docId){
        try{
            delete [SELECT Id FROM ContentDocument WHERE Id = :docId];
            return 'SUCCESS';
        }
        catch(Exception ex){
            return 'FAILED';
        }
    }

    @AuraEnabled
    public static Wrapper createTopup(String id, Double cost) {
        if (LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId())) {
            return new Wrapper(null, System.label.BCI_Session_Expiry_Error);
        }
        List<LSC_Levy__c> levies = [SELECT Id, LSC_CostOfWorks__c, LSC_LevyPayable__c, LSC_ExemptionAmount__c, LSC_TotalInterestPaidAmount__c, LSC_TotalPaidCredit__c, LSC_ApplicationStatus__c, LSC_AuthorisedRepresentativeId__r.Email FROM LSC_Levy__c WHERE Id = :id];        
        if(levies != null && levies.size() > 0) {
            LSC_Levy__c levy = levies[0];
            if(levy.LSC_ApplicationStatus__c == 'Paid') {
                levy.LSC_CostOfWorks__c = cost;
                levy.LSC_LevyPayable__c = Math.floor(cost * 0.0035);
                Double topupAmount = levy.LSC_LevyPayable__c - levy.LSC_ExemptionAmount__c + levy.LSC_TotalInterestPaidAmount__c - levy.LSC_TotalPaidCredit__c;
                if(topupAmount > 0) {
                    Savepoint sp = Database.setSavepoint();
                    try {
                        LSC_Transaction__c t = new LSC_Transaction__c();
                        t.RecordTypeId = Schema.SObjectType.LSC_Transaction__c.getRecordTypeInfosByName().get('Top Up').getRecordTypeId();
                        t.LSC_Amount__c = topupAmount;
                        t.LSC_DueDate__c = Date.today();
                        t.LSC_Status__c = 'Pending';
                        t.LSC_LevyId__c = id;
                        t.LSC_RepEmail__c = levy.LSC_AuthorisedRepresentativeId__r != null ? levy.LSC_AuthorisedRepresentativeId__r.Email : null;
                        insert t;

                        update  levy;
                        return new Wrapper(t.Id, null);
                    }
                    catch(Exception ex) {
                        Database.rollback(sp);
                        return new Wrapper(null, 'Error creating a new Top Up');                         
                    }
                }
                else {
                    return new Wrapper(null, 'Top Up amount can\'t be negative');                                    
                }
            }
            else {
                return new Wrapper(null, 'You can only Top Up a paid Levy');                
            }
        }
        else {
            return new Wrapper(null, 'Error creating a new Top Up');
        }
    }   

    @AuraEnabled
    public static Wrapper createCase(String id, String type, String category, String subject, String details, String bsb, String accountNumber, String accountName, String bankName, Decimal costOfWork, Decimal refundAmount, Decimal voluntaryLaborCost, String jsonData, List<String> docIds) {
        if (LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId())) {
            return new Wrapper(null, System.label.BCI_Session_Expiry_Error);
        }
        List<LSC_Levy__c> levies = [SELECT Id, LSC_ApplicationStatus__c FROM LSC_Levy__c WHERE Id = :id];        
        if(levies != null && levies.size() > 0) {
            LSC_Levy__c levy = levies[0];
            if(type != null && type == 'refund' && levy.LSC_ApplicationStatus__c != 'Paid') {
                return new Wrapper(null, 'Only a fully paid levy can be refunded');
            }
            else {
                Savepoint sp = Database.setSavepoint();
                try {
                    Case c = new Case();
                    List<User> users = [SELECT Id, AccountId, ContactId, Account.RecordType.Name, Contact.LSC_SelectedAccountId__c FROM User WHERE Id = :UserInfo.getUserId()];
                    if(users != null && users.size() > 0) {
                        if(users[0].Contact.LSC_SelectedAccountId__c != null) {
                            c.AccountId = users[0].Contact.LSC_SelectedAccountId__c;
                        }
                        else {
                            c.AccountId = users[0].AccountId;
                        }
                    }
                    c.LSC_LevyId__c = id;
                    Database.DMLOptions dmlOpts = new Database.DMLOptions();
                    dmlOpts.assignmentRuleHeader.useDefaultRule = true;
                    c.setOptions(dmlOpts);                    
                    if(type == 'refund') {

                        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
                        c.Subject = 'Refund request';
                        c.LSC_NewCostOfWork__c  = costOfWork;
                        c.LSC_Amount__c = refundAmount;
                        if(String.isBlank(bsb)){
                            List<LSC_TransactionLineItem__c> tlis = [SELECT Id, LSC_PaymentMethod__c FROM LSC_TransactionLineItem__c WHERE LSC_TransactionId__r.LSC_LevyId__c = :id AND RecordType.Name = 'Payment' AND (LSC_Status__c = 'Paid' OR LSC_Status__c = 'Processing')];
                            if(tlis != null && tlis.size() == 1 && tlis[0].LSC_PaymentMethod__c != 'Agency') {
                                c.LSC_TransactionLineItemId__c = tlis[0].Id;
                            }
                        }
                        else{
                            c.LSC_AccountName__c = accountName;
                            if(bsb != null && bsb.length() > 0) {
                                c.LSC_BSB__c = bsb.left(3) + '-' + bsb.right(3); 
                            }
                            c.LSC_AccountNo__c = accountNumber;
                            LSC_BSBDirectory__mdt bsbDirectory = LSC_BSBDirectory__mdt.getInstance('X'+bsb);
                            if(bsbDirectory != null) {
                                c.LSC_BankCode__c = bsbDirectory.LSC_Bank__c;
                                c.LSC_BranchName__c = bsbDirectory.LSC_Branch__c;
                            }      
                            else {
                                c.LSC_BankCode__c = bankName;
                            }    
                        }           
                    }
                    else {
                        c.Subject = subject;
                        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
                    }
                    c.Description = details;
                    c.Type = category;
                    c.LSC_Scheme__c = 'BCI';
                    c.Origin = 'Portal';
                    if (category == 'Requesting an owner builder partial exemption refund' || category == 'Requesting a non-profit partial exemption refund'){
                        c.LSC_NewCostOfWork__c  = null;    
                    }
                    insert c;

                    //
                    if (c != null && c.Id != null && levy.Id != null && voluntaryLaborCost >0){
                        LSC_Levy__c l = new LSC_Levy__c();
                        l.Id = levy.Id;
                        l.LSC_VoluntaryLabourCostofWorks__c = voluntaryLaborCost;
                        if (category == 'Requesting a non-profit partial exemption refund'){
                            l.LSC_ExemptionType__c   = 'Non-Profit'; 
                        }
                        if (category == 'Requesting an owner builder partial exemption refund'){
                            l.LSC_ExemptionType__c   = 'Owner Builder'; 
                        }
                        if (String.isNotBlank(jsonData)){
                            LSC_FetchOwnerBuilderLicenceDetail.LicenceDetails ownerBuilderDetail = (LSC_FetchOwnerBuilderLicenceDetail.LicenceDetails) System.JSON.deserialize(jsonData, LSC_FetchOwnerBuilderLicenceDetail.LicenceDetails.class);
                            //l.LSC_OwnerBuilderLicenceNo__c = licenceNumber;
                            l.LSC_OwnerBuilderLicenceNo__c = ownerBuilderDetail.licenceNumber;
                            l.LSC_OwnerBuilderLicenceStartDate__c = Date.valueOf(ownerBuilderDetail.startDate);
                            l.LSC_OwnerBuilderLicenceeName__c = ownerBuilderDetail.licensee;
                            l.LSC_OwnerBuilderLicenceId__c = ownerBuilderDetail.licenceID;
                            l.LSC_OwnerBuilderLicenceType__c = ownerBuilderDetail.licenceType;
                            l.LSC_OwnerBuilderLicenceStatus__c = ownerBuilderDetail.status;
                            l.LSC_HasOwnerBuilderLicence__c = true;
                        }
                        update l;
                    }
                    if(docIds != null && docIds.size() > 0) {
                        List<ContentDocumentLink> newCdls = new List<ContentDocumentLink>();
                        for(String docId : docIds) {
                            ContentDocumentLink cdl = new ContentDocumentLink();
                            cdl.ContentDocumentId = docId;
                            cdl.LinkedEntityId = c.Id;
                            cdl.ShareType = 'I';
                            newCdls.add(cdl);
                        }                
                        insert newCdls;
                    }
                    return new Wrapper(c.Id, null);
                }
                catch(Exception ex) {
                    Database.rollback(sp);
                    return new Wrapper(null, 'Error handling the request');
                }                
            }
        }
        else {
            return new Wrapper(null, 'Error handling the request');
        }
    }        

    @AuraEnabled(cacheable=true)
    public static OverdueWrapper getOverdueInstalment(String id) {
        OverdueWrapper result = new OverdueWrapper(false, null);
        if(id != null) {
            List<LSC_Transaction__c> transactions = [SELECT Id, LSC_DueDate__c, LSC_Status__c FROM LSC_Transaction__c WHERE LSC_LevyId__c = :id AND RecordType.Name = 'Instalment' AND LSC_DueDate__c < TODAY AND LSC_Status__c = 'Pending' ORDER BY LSC_DueDate__c ASC];
            if(transactions.size() > 0) {
                return new OVerdueWrapper(true, transactions[0].LSC_DueDate__c);
            }
        }
        return result;
    }      

    @AuraEnabled
    public static LevyWrapper getLevyDetails(String id) {
        LevyWrapper result = new LevyWrapper();
        if(id != null) {
            List<LSC_Levy__c> levy = [SELECT Id, LSC_AccountId__c, LSC_ApplicantLastName__c, UserRecordAccess.HasReadAccess, LSC_AccountId__r.LSC_EFTPaymentAllowed__c, LSC_ApplicationNumber__c, Name, LSC_SiteAddressStreet__c, LSC_SiteAddressCity__c, LSC_SiteAddressState__c, LSC_SiteAddressPostCode__c, LSC_LastLevyPaidDate__c, LSC_CostOfWorks__c, 
                                            LSC_VoluntaryLabourCostofWorks__c, LSC_OwnerBuilderLicenceNo__c, LSC_TotalLevyPayable__c, LSC_LevySource__c, LSC_TotalPayableDebit__c, LSC_TotalPaidCredit__c, LSC_TotalRefundAmount__c, LSC_TotalWriteOffAmount__c, LSC_ExemptionAmount__c, LSC_TotalPaidAmount__c, LSC_TotalInterestAmount__c, LSC_TotalInterestPaidAmount__c, LSC_ApplicationStatus__c, 
                                            LSC_HasInstallments__c, LSC_AuthorisedRepresentativeId__c, LSC_PrivateCertifierCompany__c, LSC_PrivateCertifierName__c, LSC_PrivateCertifierPhone__c, LSC_PrivateCertifierEmail__c,
                                             (SELECT Id, RecordType.Name, LSC_Status__c, Name, LSC_AmountDue__c, LSC_DueDate__c FROM Transactions__r WHERE LSC_Status__c = 'Pending' AND LSC_ProcessingAmount__c = 0 AND (RecordType.Name = 'Levy' OR RecordType.Name = 'Top Up' OR RecordType.Name = 'Interest') ORDER BY LSC_DueDate__c ASC)
                                      FROM LSC_Levy__c WHERE Id = :id AND LSC_ApplicationStatus__c != 'Cancelled'];
            List<AccountContactRelation> acrs = new List<AccountContactRelation>();
            if(UserInfo.getUserType() != 'Standard' && levy != null && levy.size() > 0) {
                List<User> u = [SELECT ContactId FROM User WHERE Id = :userInfo.getUserId()];
                if(u != null && u.size() > 0 && u[0].ContactId != null) {
                    acrs = [SELECT Id FROM AccountContactRelation WHERE ContactId = :u[0].ContactId AND IsActive = true AND AccountId = :levy[0].LSC_AccountId__c];
                }
            }
            if(levy != null && levy.size() > 0 && levy[0].UserRecordAccess.HasReadAccess && (UserInfo.getUserType() == 'Standard' || acrs.size() > 0)) {
                List<LSC_TransactionLineItem__c> tlis = [SELECT Id, LSC_PaymentMethod__c FROM LSC_TransactionLineItem__c WHERE LSC_TransactionId__r.LSC_LevyId__c = :id AND RecordType.Name = 'Payment' AND (LSC_Status__c = 'Paid' OR LSC_Status__c = 'Processing') AND LSC_TransactionId__r.RecordType.Name != 'Refund'];
                List<LSC_Transaction__c> refunds = [SELECT Id FROM LSC_Transaction__c WHERE LSC_LevyId__c = :id AND RecordType.Name = 'Refund'];
                result = new LevyWrapper(levy[0]);
                if(levy[0].Transactions__r != null && levy[0].Transactions__r.size() > 0) {
                    for(LSC_Transaction__c tr : levy[0].Transactions__r) {
                        if(tr.RecordType.Name == 'Refund') {
                           continue;
                        }
                        else if(tr.RecordType.Name == 'Interest') {
                            result.hasInterest = true;
                            result.interestId = tr.Id;
                        }
                        else {
                            if(tr.RecordType.Name == 'Levy') {
                                result.dueDate = tr.LSC_DueDate__c;
                            }
                            result.canPay = true;
                            result.transactionId = tr.Id;
                            result.transactionName = tr.Name;
                            if(tr.LSC_AmountDue__c >= 1000000) {
                                result.isBigTransaction = true;
                            }
                        }
                    }
                } 
                else {
                    result.canPay = false;
                    if(levy[0].LSC_ApplicationStatus__c == 'Paid') {
                        List<LSC_Transaction__c> trs = [SELECT Id, LSC_AmountDue__c FROM LSC_Transaction__c WHERE LSC_LevyId__c = :levy[0].Id AND RecordType.Name != 'Instalment' AND LSC_Status__c = 'Paid' ORDER BY LSC_DueDate__c DESC];
                        if(trs != null && trs.size() > 0) {
                            result.transactionId = trs[0].Id;
                            if(trs[0].LSC_AmountDue__c >= 1000000) {
                                result.isBigTransaction = true;
                            }
                        }
                    }
                }
                //Determines if the levy is refundable only via EFT
                if((refunds != null && refunds.size() > 0) || 
                    levy[0].LSC_HasInstallments__c || 
                    levy[0].LSC_LevySource__c == 'Legacy' || 
                    levy[0].LSC_ApplicantLastName__c != null || 
                    (tlis != null && tlis.size() > 0 && (
                    tlis.size() > 1 || 
                    (tlis[0].LSC_PaymentMethod__c != 'PayPal' && 
                    tlis[0].LSC_PaymentMethod__c != 'Card')))) {
                    result.eftRefund = true;
                }

                //Determines if refundable
                if(levy[0].LSC_TotalPayableDebit__c < levy[0].LSC_TotalPaidCredit__c && levy[0].LSC_ApplicationStatus__c == 'Paid') {
                    result.canRefund = true;
                }
                else {
                    result.canRefund = false;
                }

                //Determines if topupable
                if(levy[0].LSC_TotalPayableDebit__c == 0 && levy[0].LSC_ApplicationStatus__c == 'Paid') {
                    result.canTopup = true;
                }
                else {
                    result.canTopup = false;
                }

            }
        }
        return result;
    }          

    public class OverdueWrapper {
        @AuraEnabled
        public Boolean hasOverdue {get; set;}

        @AuraEnabled
        public Date overdueDate {get; set;}  
        
        public OverdueWrapper(Boolean has, Date due) {
            this.hasOverdue = has;
            this.overdueDate = due;
        }
    }

    public class LevyWrapper {
        @AuraEnabled
        public String id {get; set;}

        @AuraEnabled
        public String transactionId {get; set;}

        @AuraEnabled
        public Boolean isBigTransaction {get; set;}

        @AuraEnabled
        public String daNumber {get; set;}        

        @AuraEnabled
        public String siteAddress {get; set;}
        
        @AuraEnabled
        public Date datePaid {get; set;}

        @AuraEnabled
        public Date dueDate {get; set;}        
        
        @AuraEnabled
        public Double totalCost {get; set;}
        
        @AuraEnabled
        public Double levyDue {get; set;}
        
        @AuraEnabled
        public Double amountPaid {get; set;}

        @AuraEnabled
        public Double writeOffAmount {get; set;}

        @AuraEnabled
        public Double totalRefundAmount {get; set;}

        @AuraEnabled
        public Double exemptionAmount {get; set;}        
        
        @AuraEnabled
        public Double balanceDue {get; set;}
        
        @AuraEnabled
        public Double interestDue {get; set;}

        @AuraEnabled
        public Double interestPaid {get; set;}        
                
        @AuraEnabled
        public Boolean canPay {get; set;}        
        
        @AuraEnabled
        public String name {get; set;}    
        
        @AuraEnabled
        public String status {get; set;}        

        @AuraEnabled
        public String transactionName {get; set;}            

        @AuraEnabled
        public String approverCompany {get; set;}        

        @AuraEnabled
        public String approverName {get; set;}

        @AuraEnabled
        public String interestId {get; set;}        

        @AuraEnabled
        public String approverPhone {get; set;}        

        @AuraEnabled
        public String approverEmail {get; set;}

        @AuraEnabled
        public Boolean eftRefund {get; set;}

        @AuraEnabled
        public Boolean eftAllowed {get; set;}  
        
        @AuraEnabled
        public Boolean hasInstalments {get; set;}   
        
        @AuraEnabled
        public Boolean hasInterest {get; set;}           
        
        @AuraEnabled
        public Boolean hasAccess {get; set;}    
        
        @AuraEnabled
        public Boolean canRefund {get; set;}    

        @AuraEnabled
        public Boolean canTopup {get; set;}    
                
        public LevyWrapper(LSC_Levy__c levy) { 
            this.id = levy.Id;
            this.daNumber = levy.LSC_ApplicationNumber__c;
            
            this.siteAddress = (String.isNotBlank(levy.LSC_SiteAddressStreet__c) ? levy.LSC_SiteAddressStreet__c + ', ' : '') + (String.isNotBlank(levy.LSC_SiteAddressCity__c) ? levy.LSC_SiteAddressCity__c : '') + ' ' + (String.isNotBlank(levy.LSC_SiteAddressState__c) ? levy.LSC_SiteAddressState__c : '') + ' ' + (String.isNotBlank(levy.LSC_SiteAddressPostCode__c) ? levy.LSC_SiteAddressPostCode__c : '');
            this.datePaid = levy.LSC_LastLevyPaidDate__c;
            this.totalCost = levy.LSC_CostOfWorks__c;
            this.levyDue = levy.LSC_TotalLevyPayable__c;
            this.name = levy.Name;
            this.exemptionAmount = levy.LSC_ExemptionAmount__c;
            this.status = levy.LSC_ApplicationStatus__c;
            this.hasInstalments = levy.LSC_HasInstallments__c;
            this.amountPaid = levy.LSC_TotalPaidCredit__c;
            this.writeOffAmount = levy.LSC_TotalWriteOffAmount__c; 
            this.totalRefundAmount = levy.LSC_TotalRefundAmount__c;
            this.interestPaid = levy.LSC_TotalInterestPaidAmount__c;
            this.interestDue = levy.LSC_TotalInterestAmount__c - levy.LSC_TotalInterestPaidAmount__c; 
            this.balanceDue = levy.LSC_TotalLevyPayable__c - levy.LSC_TotalPaidCredit__c - this.interestDue < 0 ? 0 : levy.LSC_TotalLevyPayable__c - levy.LSC_TotalPaidCredit__c - this.interestDue;
            
            this.approverCompany = levy.LSC_PrivateCertifierCompany__c;
            this.approverName = levy.LSC_PrivateCertifierName__c;
            this.approverPhone = levy.LSC_PrivateCertifierPhone__c;
            this.eftAllowed = levy.LSC_AccountId__r.LSC_EFTPaymentAllowed__c;
            this.approverEmail = levy.LSC_PrivateCertifierEmail__c;
            this.canPay = false;
            this.eftRefund = false;   
            this.hasAccess = true;   
            this.isBigTransaction = false;        
        }

        public LevyWrapper() {
            this.canPay = false;
            this.eftRefund = false;
            this.hasAccess = false;
            this.isBigTransaction = false;
        }
    }    

    public class TransactionWrapper {
        @AuraEnabled
        public String id {get; set;}

        @AuraEnabled
        public String name {get; set;}        

        @AuraEnabled
        public Integer index {get; set;}        

        @AuraEnabled
        public String stage {get; set;}

        @AuraEnabled
        public Double amount {get; set;}

        @AuraEnabled
        public Double paidAmount {get; set;}

        @AuraEnabled
        public Date dueDate {get; set;} 

        @AuraEnabled
        public Date datePaid {get; set;}         

        @AuraEnabled
        public String status {get; set;}  

        @AuraEnabled
        public String dueDateClass {get; set;}          
        
        @AuraEnabled
        public String buttonClass {get; set;}      
        
        @AuraEnabled
        public String type {get; set;}              

        @AuraEnabled
        public String buttonTitle {get; set;}                 
        
        public TransactionWrapper(LSC_Transaction__c t, Integer index) {
            this.id = t.Id;
            this.name = t.Name;
            this.stage = t.LSC_Stage__c;
            this.amount = t.LSC_TotalAmount__c;
            if(t.RecordType.Name == 'Interest' || t.RecordType.Name == 'Instalment') {
                this.dueDate = t.LSC_DueDate__c;
                this.dueDateClass = (t.LSC_Status__c == 'Pending' && t.LSC_DueDate__c < Date.today()) ? 'text-error' : '';   
            }            
            else {
                this.dueDateClass = 'duedate-hide';
            }
            this.status = t.LSC_Status__c;
            this.datePaid = t.LSC_PaidDate__c;
            this.type = t.RecordType.Name;
            this.paidAmount = t.LSC_PaidAmount__c;

            this.buttonClass = (t.LSC_Status__c == 'Paid' || t.LSC_Status__c == 'Pending') ? '' : 'button-hide';
            this.buttonTitle = (t.LSC_Status__c == 'Paid') ? 'Print receipt' : 'Pay now';
            this.index = index;
        }
    }

    public class CaseWrapper {
        @AuraEnabled
        public String id {get; set;}

        @AuraEnabled
        public String url {get; set;}

        @AuraEnabled
        public String status {get; set;}

        @AuraEnabled
        public String subject {get; set;}

        @AuraEnabled
        public Datetime created {get; set;} 

        @AuraEnabled
        public String ticket {get; set;}         
        
        public CaseWrapper(Case c) {
            this.id = c.Id;
            this.url = '/bci/s/case/' + c.Id;
            this.subject = c.Subject;
            this.created = c.CreatedDate;
            this.status = c.Status;
            this.ticket = c.CaseNumber;            
        }
    }

    public class TLIWrapper {
        @AuraEnabled
        public String id {get; set;}

        @AuraEnabled
        public String status {get; set;}

        @AuraEnabled
        public String type {get; set;}

        @AuraEnabled
        public Double amount {get; set;} 

        @AuraEnabled
        public Date datePaid {get; set;}   

        @AuraEnabled
        public Integer index {get; set;}    
        
        public TLIWrapper(LSC_TransactionLineItem__c t, Integer index) {
            this.id = t.Id;
            this.amount = t.LSC_TotalAmount__c;
            this.datePaid = t.LSC_PaymentDate__c;
            this.status = t.LSC_Status__c;
            this.type = t.LSC_TransactionId__r.RecordType.Name;
            this.index = index;      
        }
    }    

    public class Wrapper {
        @AuraEnabled
        public String id {get; set;}      
        
        @AuraEnabled
        public String error {get; set;}   
        
        public Wrapper(String id, String error) {
            this.id = id;
            this.error = error;
        }
    }

    public class EFTWrapper {
        @AuraEnabled
        public String bsb {get; set;}      
        
        @AuraEnabled
        public String accountNumber {get; set;} 
        
        @AuraEnabled
        public Boolean eftAllowed {get; set;} 
        
        public EFTWrapper(String bsb, String accountNumber,Boolean eftAllowed) {
            this.bsb = bsb;
            this.accountNumber = accountNumber;
            this.eftAllowed = eftAllowed;
        }
    }    
}