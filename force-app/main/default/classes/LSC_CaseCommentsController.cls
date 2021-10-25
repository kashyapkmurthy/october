public with sharing class LSC_CaseCommentsController {

    @AuraEnabled
    public static ResultWrapper createComment(String recordId, String body, List<String> docIds) {
        if (LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId())) {
            return new ResultWrapper(null, System.label.BCI_Session_Expiry_Error);
        }
        if(recordId != null && body != null) {
            try {
                CaseComment c = new CaseComment();
                c.CommentBody = body;
                c.ParentId = recordId;
                c.IsPublished = true;
                insert c; 
                if(docIds != null && docIds.size() > 0) {
                    List<ContentDocumentLink> newCdls = new List<ContentDocumentLink>();
                    for(String docId : docIds) {
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = docId;
                        cdl.LinkedEntityId = recordId;
                        cdl.ShareType = 'I';
                        newCdls.add(cdl);
                    }                
                    insert newCdls;
                }                
                return new ResultWrapper(c.Id, null);
            }
            catch(Exception e) {
                return new ResultWrapper(null, 'Internal error');
            }
        }
        else {
            return new ResultWrapper(null, 'Internal error');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Wrapper> getComments(String recordId) {
        List<Wrapper> result = new List<Wrapper>();
        if(recordId != null) {
            List<CaseComment> comments = [SELECT Id, CommentBody, CreatedBy.FirstName, CreatedBy.LastName, CreatedBy.Profile.UserType, CreatedDate FROM CaseComment WHERE ParentId = :recordId AND IsPublished = true AND IsDeleted = false ORDER BY CreatedDate DESC];            
            for(CaseComment cc : comments) {
                result.add(new Wrapper(cc));
            }
        }
        return result;        
    }

    @AuraEnabled
    public static String deleteDocuments(List<String> docIds) {
        try{
            if(docIds != null && docIds.size() > 0) {
                delete [SELECT Id FROM ContentDocument WHERE Id IN :docIds];
            }
            return 'SUCCESS';
        }
        catch(Exception ex){
            return 'FAILED';
        }
    }


    public class Wrapper {
        @AuraEnabled
        public String id {get;set;} 

        @AuraEnabled
        public String name {get;set;}

        @AuraEnabled
        public String body {get;set;}

        @AuraEnabled
        public Datetime created {get;set;}      
        
        public Wrapper(CaseComment c) {
            this.id = c.Id;
            if(c.CreatedBy.Profile.UserType == 'Standard') {
                this.name = c.CreatedBy.FirstName + ' (Long Service Corporation)';
            }
            else {
                this.name = c.CreatedBy.FirstName == null ? '' : c.CreatedBy.FirstName + ' '; 
                this.name += c.CreatedBy.LastName;
            }
            this.body = c.CommentBody;
            this.created = c.CreatedDate;
        }
    }   
    
    public class ResultWrapper {
        @AuraEnabled
        public String id {get; set;}      
        
        @AuraEnabled
        public String error {get; set;}   
        
        public ResultWrapper(String id, String error) {
            this.id = id;
            this.error = error;
        }
    }    
}