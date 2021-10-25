public with sharing class LSC_LevyListController {

    @AuraEnabled(cacheable=true)
    public static List<Wrapper> getLevies(String searchKey, String sortBy, String sortDirection) {
        List<Wrapper> results = new List<Wrapper>();
        List<User> users = [SELECT Id, ContactId, Contact.LSC_SelectedAccountId__c, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        if(UserInfo.getUserType() != 'Standard' && users[0].ContactId != null && users[0].Contact.LSC_SelectedAccountId__c != null) {
            List<AccountContactRelation> acrs = [SELECT Id FROM AccountContactRelation WHERE ContactId = :users[0].ContactId AND IsActive = true AND AccountId = :users[0].Contact.LSC_SelectedAccountId__c];
            if(acrs.isEmpty()) {
                return results;
            }
        }
        Id accId;

        String query = 'SELECT Id, Name, LSC_TotalPayableDebit__c, LSC_TotalPaidCredit__c, LSC_HasInstallments__c, LSC_ApplicationNumber__c, LSC_SiteAddressStreet__c, LSC_SiteAddressCity__c, LSC_SiteAddressState__c, LSC_SiteAddressPostCode__c, LSC_ApplicationStatus__c, (SELECT Id, RecordType.Name, LSC_Status__c, Name, LSC_AmountDue__c FROM Transactions__r WHERE (LSC_Status__c = \'Pending\' AND LSC_ProcessingAmount__c = 0 AND (RecordType.Name = \'Levy\' OR RecordType.Name = \'Top Up\' OR RecordType.Name = \'Interest\')) OR (RecordType.Name != \'Instalment\' AND LSC_Status__c = \'Paid\') ORDER BY LSC_DueDate__c ASC) FROM LSC_Levy__c WHERE LSC_ApplicationStatus__c != \'Cancelled\' ';


        if (searchKey != null && searchKey != '') {
            String key = '%' + searchKey + '%';
            query += ' AND (Name LIKE :key OR LSC_ApplicationNumber__c LIKE :key OR LSC_ApplicationStatus__c LIKE :key OR LSC_SiteAddressStreet__c LIKE :key OR LSC_SiteAddressCity__c LIKE :key OR LSC_SiteAddressPostCode__c LIKE :key) ';
            if(users[0].ContactId != null && users[0].Contact.LSC_SelectedAccountId__c != null) {
                accId = users[0].Contact.LSC_SelectedAccountId__c;
                query += 'AND LSC_AccountId__c = :accId ';
            }
            else if(users[0].AccountId != null) {
                accId = users[0].AccountId;
                query += 'AND LSC_AccountId__c = :accId ';
            }            
        }
        else {
            if(users[0].ContactId != null && users[0].Contact.LSC_SelectedAccountId__c != null) {
                accId = users[0].Contact.LSC_SelectedAccountId__c;
                query += ' AND LSC_AccountId__c = :accId ';
            }
            else if(users[0].AccountId != null) {
                accId = users[0].AccountId;
                query += ' AND LSC_AccountId__c = :accId ';
            }             
        }

        if (sortBy != null && sortDirection != null) {
            String sortColumn = 'Name';
            if(sortBy == 'refNo') {
                sortColumn = 'Name';
            }
            else if(sortBy == 'daNo') {
                sortColumn = 'LSC_ApplicationNumber__c';
            }
            else if(sortBy == 'address') {
                sortColumn = 'LSC_SiteAddressStreet__c';
            }
            else if(sortBy == 'status') {
                sortColumn = 'LSC_ApplicationStatus__c';
            }
            query += ' ORDER BY ' + sortColumn + ' ' + sortDirection;
        }
        
        for(SObject s : Database.query(query)) {
            LSC_Levy__c l = (LSC_Levy__c)s;
            Wrapper w = new Wrapper(l);
            for (LSC_Transaction__c t : l.Transactions__r){
                if(t.LSC_Status__c != 'Paid'){
                    switch on t.recordtype.name {
                        when 'Levy','Top Up' {
                            w.isPayable = true;
                            w.transactionId = t.Id;
                            w.transactionAmountDue = t.LSC_AmountDue__c;
                        }
                        when 'Interest' {
                            w.isInterestPayable = true;
                            w.interestId = t.Id;
                            w.transactionAmountDue = t.LSC_AmountDue__c;
                        }
                    }
                }else if(String.isBlank(w.transactionId)){
                    w.transactionId = t.Id;
                    w.transactionAmountDue = t.LSC_AmountDue__c;
                }
            }
            results.add(w);
        }
        return results;
    }

    public class Wrapper {
        @AuraEnabled
        public String id {get;set;}

        @AuraEnabled
        public String refNo {get;set;}

        @AuraEnabled
        public String daNo {get;set;}

        @AuraEnabled
        public String address {get;set;}

        @AuraEnabled
        public String status {get;set;} 

        @AuraEnabled
        public String url {get;set;}         

        @AuraEnabled
        public Boolean hasInstalments {get;set;}      
        
        @AuraEnabled
        public Boolean isPayable {get;set;}  

        @AuraEnabled
        public Boolean canTopup {get;set;}  

        @AuraEnabled
        public Boolean canRefund {get;set;}  
       
        @AuraEnabled
        public String transactionId {get;set;}
        
        @AuraEnabled
        public Boolean isInterestPayable {get;set;}

        @AuraEnabled
        public String interestId {get;set;}

        @AuraEnabled
        public Decimal transactionAmountDue {get;set;}
        
        public Wrapper(LSC_Levy__c levy) { 
            this.id = levy.Id;
            this.hasInstalments = levy.LSC_HasInstallments__c;
            this.refNo = levy.Name;
            this.daNo = levy.LSC_ApplicationNumber__c;
            this.url = '/bci/s/levy/' + levy.Id;
            this.address = levy.LSC_SiteAddressStreet__c != null ? levy.LSC_SiteAddressStreet__c + ', ' : '';
            this.address += levy.LSC_SiteAddressCity__c != null ? levy.LSC_SiteAddressCity__c + ' ' : '';
            this.address += levy.LSC_SiteAddressState__c != null ? levy.LSC_SiteAddressState__c + ' ' : '';
            this.address += levy.LSC_SiteAddressPostCode__c != null ? levy.LSC_SiteAddressPostCode__c : ''; 
            this.status = levy.LSC_ApplicationStatus__c;
            this.isPayable = false;
            this.isInterestPayable = false;
            //Determines if refundable
            if(levy.LSC_TotalPayableDebit__c < levy.LSC_TotalPaidCredit__c && levy.LSC_ApplicationStatus__c == 'Paid') {
                this.canRefund = true;
            }
            else {
                this.canRefund = false;
            }

            //Determines if topupable
            if(levy.LSC_TotalPayableDebit__c == 0 && levy.LSC_ApplicationStatus__c == 'Paid') {
                this.canTopup = true;
            }
            else {
                this.canTopup = false;
            }            
        }
    }
}