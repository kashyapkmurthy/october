public with sharing class LSC_CaseRecordController {
    @AuraEnabled(cacheable=true)
    public static CaseWrapper getCase(String recordId) {
        CaseWrapper result = new CaseWrapper();
        if(recordId != null) {
            List<Case> cases = [SELECT Id, AccountId, CaseNumber, RecordType.Name, Subject, Description, Status, CreatedDate, Type, LastModifiedDate, ClosedDate, 
                                UserRecordAccess.HasReadAccess,LSC_LevyId__c, LSC_LevyId__r.Name 
                                FROM Case 
                                WHERE Id = :recordId];            
            List<AccountContactRelation> acrs = new List<AccountContactRelation>();
            if(UserInfo.getUserType() != 'Standard' && cases != null && cases.size() > 0) {
                List<User> u = [SELECT ContactId FROM User WHERE Id = :userInfo.getUserId()];
                if(u != null && u.size() > 0 && u[0].ContactId != null) {
                    acrs = [SELECT Id FROM AccountContactRelation WHERE ContactId = :u[0].ContactId AND IsActive = true AND AccountId = :cases[0].AccountId];
                }
            }            
            if(cases != null && cases.size() > 0 && cases[0].UserRecordAccess.HasReadAccess && (UserInfo.getUserType() == 'Standard' || acrs.size() > 0)) {
                result = new CaseWrapper(cases[0]);
            }
        }
        return result;        
    }

    public class CaseWrapper {
        @AuraEnabled
        public String id {get;set;} 

        @AuraEnabled
        public String ticketNumber {get;set;}

        @AuraEnabled
        public String subject {get;set;}

        @AuraEnabled
        public String details {get;set;}

        @AuraEnabled
        public String status {get;set;}    
        
        @AuraEnabled
        public String actionType {get;set;}          

        @AuraEnabled
        public Datetime created {get;set;}  

        @AuraEnabled
        public Datetime updated {get;set;}          
        
        @AuraEnabled
        public Boolean closed {get;set;}        

        @AuraEnabled
        public Boolean hasAccess {get;set;}    

        @AuraEnabled
        public Boolean hasAction {get;set;} 
        
        @AuraEnabled
        public String levyId {get;set;}

        @AuraEnabled
        public String levyName {get;set;}

        public CaseWrapper() {
            this.hasAccess = false;
        }

        public CaseWrapper(Case c) {
            this.id = c.Id;
            this.ticketNumber = c.CaseNumber;
            this.subject = c.Subject;
            this.details = c.Description;
            this.status = c.Status;
            this.created = c.CreatedDate;
            this.updated = c.LastModifiedDate;
            this.closed = c.ClosedDate != null;
            this.hasAccess = true;
            this.levyId = c.LSC_LevyId__c;
            this.levyName = c.LSC_LevyId__c != null ? c.LSC_LevyId__r.Name: null;
            
            if((c.RecordType.Name == 'Instalment' || c.RecordType.Name == 'Exemption') && c.Status == 'Closed Approved') {
                this.hasAction = true;
                if(c.RecordType.Name == 'Instalment') {
                    this.actionType = 'Instalment';
                }
                else if(c.Type == 'Bushfire recovery') {
                    this.actionType = 'Fire';
                }
                else if(c.Type == 'Non profit') {
                    this.actionType = 'NFP';
                }
                else if(c.Type == 'Owner builder') {
                    this.actionType = 'OB';
                }                                
            }
            else {
                this.hasAction = false;
            }
        }
    }       
}