public with sharing class LSC_FileUploadViewController {
    public LSC_FileUploadViewController() {

    }

    @AuraEnabled(cacheable=true)
    public static List<file> getRelatedFiles(String recordId){
        List<File> files = new List<File>();

        for(ContentDocumentLink conLink : [SELECT 
                                                ContentDocument.Id, 
                                                ContentDocument.Title, 
                                                ContentDocument.CreatedDate, 
                                                ContentDocument.FileType
                                                    FROM ContentDocumentLink 
                                                        WHERE LinkedEntityId =: recordId]){
            File file = new File();
            file.Title = conLink.ContentDocument.Title;
            file.Id = conLink.ContentDocument.Id;
            file.CreatedDate = conLink.ContentDocument.CreatedDate;
            file.Type = conLink.ContentDocument.FileType;
            files.add(file);
        }
        return files;
    }

    public class File{
        @AuraEnabled public String Title;
        @AuraEnabled public String Type;
        @AuraEnabled public Id Id;
        @AuraEnabled public Datetime CreatedDate;
    }
}