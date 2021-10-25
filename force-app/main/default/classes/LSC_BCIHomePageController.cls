public with sharing class LSC_BCIHomePageController {
	private static final Map<String, String> APPLY_STYLES = new Map<String, String>{'New' => 'lsc-info-blue', 'In Progress' => 'lsc-info-blue', 'On Hold' => 'lsc-error-red',
        'Awaiting Approving Authority' => 'lsc-warning-orange', 'Escalated' => 'lsc-warning-orange','Pending Approval' => 'lsc-warning-orange', 'Closed Approved' => 'lsc-success-green',
        'Closed Rejected' => 'lsc-error-red', 'Closed' => 'lsc-success-green'};
    @AuraEnabled(cacheable=true)
    public static List<Wrapper> getCaseList() {
        List<Wrapper> results = new List<Wrapper>();
        try{
            List<User> users = [SELECT Id, ContactId, Contact.LSC_SelectedAccountId__c, AccountId FROM User WHERE Id = :UserInfo.getUserId()];

            Id accId;
            if(users[0].ContactId != null && users[0].Contact.LSC_SelectedAccountId__c != null) {
                accId = users[0].Contact.LSC_SelectedAccountId__c;
            }
            else if(users[0].AccountId != null) {
                accId = users[0].AccountId;
            }  
            //Get all Cases related to logged in User Account
            for(Case c : [SELECT Id, LastModifiedDate, CreatedDate, CaseNumber, LSC_LevyId__r.Id, Subject, Status FROM Case WHERE AccountId =: accId ORDER BY createdDate DESC]) {
                results.add(new Wrapper((Case)c));
            }
        }catch(Exception e){
            LSC_LogHandler.logException('LSC_BCIHomePageController', 'getCaseList', e.getMessage(),e.getLineNumber(),e.getStackTraceString());
        }
        return results;
    }
    

    @AuraEnabled(cacheable=true)
    public static List<Wrapper> getCaseAndTransactionList() {
        List<Wrapper> results = new List<Wrapper>();
        try{
            Id transInterestRecTypeId = LSC_Transaction__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Interest').getRecordTypeId();
            Id transInstalmentRecTypeId = LSC_Transaction__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Instalment').getRecordTypeId();
            List<User> users = [SELECT Id, ContactId, Contact.LSC_SelectedAccountId__c, AccountId FROM User WHERE Id = :UserInfo.getUserId()];

            Id accId;
            if(users[0].ContactId != null && users[0].Contact.LSC_SelectedAccountId__c != null) {
                accId = users[0].Contact.LSC_SelectedAccountId__c;
            }
            else if(users[0].AccountId != null) {
                accId = users[0].AccountId;
            }  
            //Get all On Hold Cases related to logged in User Account
            for(Case c : [SELECT Id, LastModifiedDate, CaseNumber, CreatedDate, LSC_LevyId__r.Id, Subject, Status FROM Case WHERE AccountId =: accId AND Status = 'On Hold']) {
                results.add(new Wrapper((Case)c));
            }
            Map<Id, Wrapper> levyTransMap = new Map<Id, Wrapper>();
            //Get all overdue Transactions with pending status related to logged in User Account
            for(LSC_Transaction__c t : [SELECT Id, Name, LastModifiedDate, CreatedDate, LSC_LevyId__r.Id, LSC_LevyId__r.Name, LSC_DueDate__c FROM LSC_Transaction__c WHERE LSC_LevyId__r.LSC_AccountId__r.Id =: accId AND 
                                        (RecordTypeId =: transInterestRecTypeId OR RecordTypeId =: transInstalmentRecTypeId) AND 
                                        LSC_DueDate__c < TODAY AND LSC_Status__c = 'Pending' ORDER BY LSC_DueDate__c DESC]) {
                levyTransMap.put(t.LSC_LevyId__r.Id, new Wrapper((LSC_Transaction__c)t));
            }
            results.addAll(levyTransMap.values());
                    
            //Sort the final list by dueDate
            results.sort();
        }catch(Exception e){
            LSC_LogHandler.logException('LSC_BCIHomePageController', 'getCaseList', e.getMessage(),e.getLineNumber(),e.getStackTraceString());
        }
        return results;
    }    
    
    @AuraEnabled(cacheable=true)
    public static List<columnAttributes> getColumns(boolean renderShared) {
        system.debug('get columns...'+renderShared);
        Integer linkInitWidth = renderShared == true ? 160 : null;
        Integer dateInitWidth = renderShared == true ? 120 : null;
        List<columnAttributes> columns = new List<columnAttributes>();   
        TypeAttributesLabel lblAttr = new TypeAttributesLabel('link');
        TypeAttributes typeAttr = new TypeAttributes(lblAttr, '_blank');
        columnAttributes column1 = new columnAttributes('Id', 'url', 'url', typeAttr, linkInitWidth , false, false);
        columns.add(column1);
        columnAttributes column2 = new columnAttributes('Date', 'dueDate', 'date', null, dateInitWidth, false, false);
        columns.add(column2);
        columnAttributes column3 = new columnAttributes('Action', 'action', 'text', null, 0, false, true);
        columns.add(column3);
        return columns;
    }
    
    
	@TestVisible
    public class Wrapper implements Comparable {
        @AuraEnabled
        public String id {get;set;}

        @AuraEnabled
        public String link {get;set;}

        @AuraEnabled
        public String subject {get;set;}

        @AuraEnabled
        public Datetime created {get;set;}
        
        @AuraEnabled
        public Datetime dueDate {get;set;}

        @AuraEnabled
        public String url {get;set;}         
        
        @AuraEnabled
        public String status {get;set;}     
        
        @AuraEnabled
        public String action {get;set;}
        
        @AuraEnabled
        public String styleClass {get;set;}

        @AuraEnabled
        public Integer initWidth {get;set;}        

        public Wrapper(Case c) {
            this.id = c.Id;
            this.link = c.CaseNumber;
            this.subject = c.Subject;	
            this.action = 'Your response required';
            this.url = '/bci/s/case/' + c.Id;
            this.status = c.Status;
            this.created = c.CreatedDate;
            this.dueDate = c.LastModifiedDate;
            this.styleClass = APPLY_STYLES.get(c.Status);
            this.initWidth = 150;
        }
        
        public Wrapper(LSC_Transaction__c t) {
            this.id = t.Id;
            this.link = t.LSC_LevyId__r.Name;
            this.action = 'Payment overdue';
            this.url = '/bci/s/levy/' + t.LSC_LevyId__r.Id;
            this.dueDate = t.LSC_DueDate__c;
        }
        
        public Integer compareTo(Object instance){
            Wrapper that = (Wrapper)instance;
            if (this.dueDate > that.dueDate) return 1;
            if (this.dueDate < that.dueDate) return -1;
            return 0;
        }
    }   
    
    public class columnAttributes {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
        @AuraEnabled public TypeAttributes typeAttributes;
        @AuraEnabled public Integer initialWidth;
        @AuraEnabled public Boolean sortable;
        @AuraEnabled public Boolean wrapText;
    
        public columnAttributes(String lbl, String fieldNme, String dataType, TypeAttributes typeAtts, Integer initialWidth, Boolean sortable, Boolean wrapText) {
            this.label = lbl;
            this.fieldName = fieldNme;
            this.type = dataType;
            this.typeAttributes = typeAtts;
            this.initialWidth = initialWidth;
            this.sortable = sortable;
            this.wrapText = wrapText;
        }
    }
    
    public class TypeAttributes {
        @AuraEnabled public TypeAttributesLabel label;
        @AuraEnabled public String target;
    
        public TypeAttributes(TypeAttributesLabel lbl, String target) {
            this.label = lbl;
            this.target = target;
        }
    }
    
    public class TypeAttributesLabel{
       @AuraEnabled public String fieldName;
        
        public TypeAttributesLabel(String fldName) {
            this.fieldName = fldName;
        }
    }
}