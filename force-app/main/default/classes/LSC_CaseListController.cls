public with sharing class LSC_CaseListController {

    @AuraEnabled(cacheable=true)
    public static List<Wrapper> getCases(String searchKey, String sortBy, String sortDirection) {
        List<Wrapper> results = new List<Wrapper>();
        List<User> users = [SELECT Id, ContactId, Contact.LSC_SelectedAccountId__c, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        if(UserInfo.getUserType() != 'Standard' && users[0].ContactId != null && users[0].Contact.LSC_SelectedAccountId__c != null) {
            List<AccountContactRelation> acrs = [SELECT Id FROM AccountContactRelation WHERE ContactId = :users[0].ContactId AND IsActive = true AND AccountId = :users[0].Contact.LSC_SelectedAccountId__c];
            if(acrs.isEmpty()) {
                return results;
            }
        }        

        String query = 'SELECT Id, CaseNumber, Subject, CreatedDate, LastModifiedDate, Status FROM Case ';
        Id accId;

        if(searchKey != null && searchKey != '') {
            String key = '%' + searchKey + '%';
            query += ' WHERE (CaseNumber LIKE :key OR Subject LIKE :key OR Status LIKE :key) ';
            if(users[0].ContactId != null && users[0].Contact.LSC_SelectedAccountId__c != null) {
                accId = users[0].Contact.LSC_SelectedAccountId__c;
                query += 'AND AccountId = :accId ';
            }
            else if(users[0].AccountId != null) {
                accId = users[0].AccountId;
                query += 'AND AccountId = :accId ';
            }            
        }
        else {
            if(users[0].ContactId != null && users[0].Contact.LSC_SelectedAccountId__c != null) {
                accId = users[0].Contact.LSC_SelectedAccountId__c;
                query += ' WHERE AccountId = :accId ';
            }
            else if(users[0].AccountId != null) {
                accId = users[0].AccountId;
                query += ' WHERE AccountId = :accId ';
            }             
        }     

        if (sortBy != null && sortDirection != null) {
            String sortColumn = 'CaseNumber';
            if(sortBy == 'ticketNo') {
                sortColumn = 'CaseNumber';
            }
            else if(sortBy == 'updated') {
                sortColumn = 'LastModifiedDate';
            }
            else if(sortBy == 'created') {
                sortColumn = 'CreatedDate';
            }
            else if(sortBy == 'status') {
                sortColumn = 'Status';
            }
            query += ' ORDER BY ' + sortColumn + ' ' + sortDirection;
        }

        for(SObject s : Database.query(query)) {
            results.add(new Wrapper((Case)s));
        }

        return results;
    }

    public class Wrapper {
        @AuraEnabled
        public String id {get;set;}

        @AuraEnabled
        public String ticketNo {get;set;}

        @AuraEnabled
        public String subject {get;set;}

        @AuraEnabled
        public Datetime created {get;set;}

        @AuraEnabled
        public Datetime updated {get;set;} 

        @AuraEnabled
        public String url {get;set;}         
        
        @AuraEnabled
        public String status {get;set;}          
        
        public Wrapper(Case c) {
            this.id = c.Id;
            this.ticketNo = c.CaseNumber;
            this.subject = c.Subject;
            this.url = '/bci/s/case/' + c.Id;
            this.status = c.Status;
            this.created = c.CreatedDate;
            this.updated = c.LastModifiedDate;
        }
    }
}