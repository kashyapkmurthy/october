public without sharing class LSC_CaseRecordDetailsController {
    
    @AuraEnabled(cacheable=true)
    public static List<String> getAttachments(String recordId) {
        List<String> result = new List<String>();
        List<ContentDocumentLink> cdls = [SELECT Id, ContentDocument.Title, ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
        for(ContentDocumentLink cdl : cdls) {
            result.add(cdl.ContentDocument.Title + '.' + cdl.ContentDocument.FileExtension);
        }
        return result;
    }
}