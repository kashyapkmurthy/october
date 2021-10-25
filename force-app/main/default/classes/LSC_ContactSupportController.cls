public without sharing class LSC_ContactSupportController {
    @AuraEnabled
    public static Wrapper createCase(String recordId, String category, String subject, String details, String name, String phone, String email, List<String> docIds) {
        if (recordId != null && LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId())) {
            return new Wrapper(null, System.label.BCI_Session_Expiry_Error);
        }

        if (LSC_PermissionCheckUtility.isIncompletedRegistrationUser(UserInfo.getUserId())) {
            return new Wrapper(null, System.label.Incompleted_Registration_User_Submit_Support_Case);
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            Case c = new Case();
            c.Subject = subject;
            c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
            c.Description = details;
            c.Type = category;
            c.Origin = 'Portal';
            c.LSC_Scheme__c = 'BCI';
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.useDefaultRule = true;
            c.setOptions(dmlOpts);
            if(recordId != null) {
                List<User> users = [SELECT Id, AccountId, ContactId, Account.RecordType.Name, Contact.LSC_SelectedAccountId__c FROM User WHERE Id = :recordId];
                if(users != null && users[0].AccountId != null && users[0].Account.RecordType.Name == 'Business') {
                    c.ContactId = users[0].ContactId;
                    c.AccountId = (users[0].Contact.LSC_SelectedAccountId__c != null) ? users[0].Contact.LSC_SelectedAccountId__c : users[0].AccountId;
                }
            }
            else {
                c.SuppliedName = name;
                c.SuppliedPhone = phone;
                c.SuppliedEmail = email;
            }
            insert c;
            if(recordId != null && docIds != null && docIds.size() > 0) {
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
}