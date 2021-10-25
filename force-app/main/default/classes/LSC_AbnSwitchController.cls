public with sharing class LSC_AbnSwitchController {
    @AuraEnabled(cacheable=true)
    public static ABNWrapper getData() {
        ABNWrapper result = new ABNWrapper();
        List<User> users = [SELECT Id, AccountId, ContactId, Account.RecordType.Name, Contact.LSC_SelectedAccountId__c FROM User WHERE Id = :UserInfo.getUserId()];
        if(users != null && users.size() > 0) {
            if(users[0].AccountId != null && users[0].Account.RecordType.Name == 'Business') {
                List<AccountContactRelation> acrs = [SELECT Id, AccountId, Account.Name FROM AccountContactRelation WHERE ContactId = :users[0].ContactId AND IsActive = true];
                if(acrs != null && acrs.size() >= 1) {
                    result.hasAbns = true;
                    if(users[0].Contact.LSC_SelectedAccountId__c != null) {
                        result.currentAbn = users[0].Contact.LSC_SelectedAccountId__c;
                    }
                    else {
                        result.currentAbn = users[0].AccountId;
                    }
                    for(AccountContactRelation acr : acrs) {
                        Option o = new Option(acr.Account.Name, acr.AccountId);
                        result.options.add(o);
                    }
                }
            }
        }       
        return result;        
    }   

    @AuraEnabled
    public static Boolean switchAbn(String accountId) {
        try{
            if(accountId != null) {
                List<User> users = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
                if(users != null && users.size() > 0 && users[0].ContactId != null) {
                    List<AccountContactRelation> acrs = [SELECT Id FROM AccountContactRelation WHERE AccountId = :accountId AND ContactId = :users[0].ContactId];
                    if(acrs != null && acrs.size() > 0) {
                        Contact c = new Contact(Id = users[0].ContactId, LSC_SelectedAccountId__c = accountId);
                        update c;
                        return true;
                    }
                    else {
                        return false;
                    }
                }
                else {
                    return false;
                }
            }
        }catch(Exception e){
            LSC_LogHandler.logException('LSC_AbnSwitchController', 'switchAbn', e.getMessage(),e.getLineNumber(),e.getStackTraceString());
        }
        return false;
    }    
    
    public class ABNWrapper {
        @AuraEnabled
        public Boolean hasAbns {get; set;}

        @AuraEnabled
        public List<Option> options {get; set;}

        @AuraEnabled
        public String currentAbn {get; set;}     

        public ABNWrapper() {
            hasAbns = false;
            options = new List<Option>();
        }
    }  
    
    public class Option {
        @AuraEnabled
        public String label {get; set;}

        @AuraEnabled
        public String value {get; set;}

        public Option(String label, String value) {
            this.label = label;
            this.value = value;
        }

    }
}