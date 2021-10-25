public class LSC_PrintTransactionDetails {
    
    public LSC_Transaction__c transactiondetail {get; set;}
    public String constructionStreetName {get; set;}
    public String constructionZipCodeCountry {get; set;}
    public String billingStreetName {get; set;}
    public String billingZipCodeCountry {get; set;}
    private ApexPages.StandardController ctrl; 
    public Boolean renderPage { get; set; }
    public Boolean isInstalment { get; set; }
    public String applicantName { get; set; }
    public String applicantMailingAddress { get; set; }
    public String recordId {get;set;}
    public String levyKeyPrefix {get;set;}
    public Boolean isLevyPrint {get;set;}

    public LSC_PrintTransactionDetails(ApexPages.StandardController stdController) {
        Apexpages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=LevyReceipt.pdf');  
        try{
            recordId = ApexPages.currentPage().getParameters().get('id');
            Schema.DescribeSObjectResult levy = LSC_Levy__c.sObjectType.getDescribe();
            levyKeyPrefix = levy.getKeyPrefix();
            if(recordId.startsWith(levyKeyPrefix)){
              isLevyPrint = true;
                // get Transaction ID
              for (LSC_Transaction__c t : [SELECT id,RecordType.Name from LSC_Transaction__c WHERE LSC_LevyId__c =: recordId and LSC_LevyId__r.LSC_ApplicationStatus__c = 'Paid' and LSC_Status__c = 'Paid'    and RecordType.Name in ('Levy','Interest','Top Up','Refund')]){
                  if(t.RecordType.Name == 'Levy'){
                    recordId = t.id;
                    break;
                  }
                  else{
                    recordId = t.id;
                  }
              }
            }else{
                isLevyPrint = false;
            }
            Boolean userAccess = [SELECT Id, UserRecordAccess.HasReadAccess FROM LSC_Transaction__c WHERE Id =: recordId].UserRecordAccess.HasReadAccess;
            if(userAccess == false){
                this.renderPage = false;
                if(UserInfo.getUserType() == 'Standard'){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This record is either not the correct type of record or is not Paid/Approved'));
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Page cannot be accessed.'));
                }
                return;
            }
        }catch(exception ex){
            this.renderPage = false;  
            if(UserInfo.getUserType() == 'Standard'){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This record is either not the correct type of record or is not Paid/Approved'));
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Page cannot be accessed.'));
            }         
            return;
        }
        if(ApexPages.currentPage().getParameters().get('id').startsWith(levyKeyPrefix)){
            String queryStr = 'SELECT id, LSC_Status__c, RecordType.Name,LSC_PaidAmount__c, LSC_TotalAmount__c, LSC_LevyId__r.LSC_ApplicationNumber__c, LSC_LevyId__r.LSC_LastLevyPaidDate__c,'+            
            'LSC_LevyId__r.LSC_LocalGovtAreaOrGovtAuthority__c,  LSC_LevyId__r.LSC_SiteAddressStreet__c, LSC_LevyId__r.LSC_SiteAddressCity__c, LSC_LevyId__r.LSC_SiteAddressState__c,'+
            'LSC_LevyId__r.LSC_SiteAddressPostCode__c, LSC_LevyId__r.id, LSC_Stage__c, LSC_Surcharge__c, LSC_LevyId__r.LSC_CostOfWorks__c, LSC_LevyId__r.LSC_VoluntaryLabourCostofWorks__c,'+
            'LSC_LevyId__r.LSC_ApprovedVoluntaryLabourcost__c, LSC_LevyId__r.LSC_TotalLevyPayable__c, LSC_LevyId__r.LSC_TotalPaidCredit__c, LSC_LevyId__r.LSC_AccountId__r.Name, LSC_LevyId__r.LSC_AccountId__r.BillingAddress,'+
            'LSC_LevyId__r.LSC_AccountId__r.LSC_ABN__c, LSC_LevyId__r.Name, LSC_LevyId__r.LSC_HasExemption__c, LSC_LevyId__r.LSC_TotalSurcharge__c, LSC_LevyId__r.RecordType.Name, LSC_LevyId__r.LSC_TotalPaidAmount__c,'+
            'LSC_LevyId__r.LSC_AccountId__r.RecordType.Name, LSC_LevyId__r.LSC_AccountId__r.BillingStreet,  LSC_LevyId__r.LSC_AccountId__r.BillingCity, LSC_LevyId__r.LSC_AccountId__r.BillingState,  LSC_LevyId__r.LSC_AccountId__r.BillingPostalCode,'+
            'LSC_LevyId__r.LSC_AccountId__r.BillingCountry, LSC_LevyId__r.LSC_AccountId__r.LSC_IndividualFirstName__c, LSC_LevyId__r.LSC_AccountId__r.LSC_IndividualLastName__c, LSC_LevyId__r.LSC_ApplicantFirstName__c,'+
            'LSC_LevyId__r.LSC_ApplicantLastName__c,LSC_LevyId__r.LSC_ApplicantMailingAddress__c, LSC_LevyId__r.LSC_TotalPaidDebit__c,LSC_LevyId__r.LSC_ApplicationType__c, LSC_LevyId__r.LSC_TotalInterestPaidAmount__c  FROM LSC_Transaction__c where id = :recordId LIMIT 1';
            for(LSC_Transaction__c t : Database.query(queryStr)){
                this.transactiondetail = t;
            }
        }else{
            if (!Test.isRunningTest()){
                stdController.addFields(getFieldNames());
            }
            this.transactiondetail = (LSC_Transaction__c) stdController.getRecord();
        }
        if(UserInfo.getUserType() == 'Standard'){
            if(!isLevyPrint && transactiondetail.RecordType.Name != 'Instalment'){
                this.renderPage = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This record is either not the correct type of record or is not Paid/Approved.'));
                return;
            }else if(transactiondetail.LSC_Status__c != 'Paid' && (transactiondetail.RecordType.Name != 'Installment' || transactiondetail.RecordType.Name != 'Levy' || transactiondetail.RecordType.Name != 'Interest' || transactiondetail.RecordType.Name != 'Top Up')) {
                this.renderPage = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This record is either not the correct type of record or is not Paid/Approved.'));
                return;
            }
        }
        else{
            if(transactiondetail.LSC_Status__c != 'Paid'){
                this.renderPage = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Page cannot be accessed.'));
                return;
            }
            
        }

        if(transactiondetail.RecordType.Name == 'Instalment') {
            this.isInstalment = true;
        }
        constructionStreetName = (String.isNotBlank(transactiondetail.LSC_LevyId__r.LSC_SiteAddressStreet__c) ? transactiondetail.LSC_LevyId__r.LSC_SiteAddressStreet__c : '') + ' '+ (String.isNotBlank(transactiondetail.LSC_LevyId__r.LSC_SiteAddressCity__c) ? transactiondetail.LSC_LevyId__r.LSC_SiteAddressCity__c : '');
        constructionStreetName += ' ' + (String.isNotBlank(transactiondetail.LSC_LevyId__r.LSC_SiteAddressState__c) ? transactiondetail.LSC_LevyId__r.LSC_SiteAddressState__c : '') + ' '+ (String.isNotBlank(transactiondetail.LSC_LevyId__r.LSC_SiteAddressPostCode__c) ? transactiondetail.LSC_LevyId__r.LSC_SiteAddressPostCode__c : '');
        
        billingStreetName = transactiondetail.LSC_LevyId__r.LSC_AccountId__r.BillingStreet + ' '+ transactiondetail.LSC_LevyId__r.LSC_AccountId__r.BillingCity;
        billingStreetName += ' ' + transactiondetail.LSC_LevyId__r.LSC_AccountId__r.BillingState + ' ' + transactiondetail.LSC_LevyId__r.LSC_AccountId__r.BillingPostalCode  + ' '+transactiondetail.LSC_LevyId__r.LSC_AccountId__r.BillingCountry;
        
            this.applicantName = transactiondetail.LSC_LevyId__r.LSC_ApplicantFirstName__c == Null? transactiondetail.LSC_LevyId__r.LSC_AccountId__r.Name : (transactiondetail.LSC_LevyId__r.LSC_ApplicantFirstName__c+' '+transactiondetail.LSC_LevyId__r.LSC_ApplicantLastName__c);
            this.applicantMailingAddress = transactiondetail.LSC_LevyId__r.LSC_ApplicantFirstName__c == Null? billingStreetName : transactiondetail.LSC_LevyId__r.LSC_ApplicantMailingAddress__c;
        
        this.renderPage = true;
    }

    public static List<String> getFieldNames(){
        return new List<String> {
            'id',         
            'LSC_Status__c', 
            'RecordType.Name',
            'LSC_PaidAmount__c', 
            'LSC_TotalAmount__c', 
            'LSC_LevyId__r.LSC_ApplicationNumber__c', 
            'LSC_LevyId__r.LSC_LastLevyPaidDate__c',             
            'LSC_LevyId__r.LSC_LocalGovtAreaOrGovtAuthority__c', 
            'LSC_LevyId__r.LSC_SiteAddressStreet__c', 
            'LSC_LevyId__r.LSC_SiteAddressCity__c', 
            'LSC_LevyId__r.LSC_SiteAddressState__c', 
            'LSC_LevyId__r.LSC_SiteAddressPostCode__c', 
            'LSC_LevyId__r.id', 
            'LSC_Stage__c',
            'LSC_Surcharge__c',
            'LSC_LevyId__r.LSC_CostOfWorks__c', 
            'LSC_LevyId__r.LSC_VoluntaryLabourCostofWorks__c',
            'LSC_LevyId__r.LSC_ApprovedVoluntaryLabourcost__c',
            'LSC_LevyId__r.LSC_TotalLevyPayable__c',
            'LSC_LevyId__r.LSC_TotalPaidCredit__c',
            'LSC_LevyId__r.LSC_AccountId__r.Name',
            'LSC_LevyId__r.LSC_AccountId__r.BillingAddress',
            'LSC_LevyId__r.LSC_AccountId__r.LSC_ABN__c',
            'LSC_LevyId__r.Name',
            'LSC_LevyId__r.LSC_HasExemption__c',
            'LSC_LevyId__r.LSC_TotalSurcharge__c',
            'LSC_LevyId__r.RecordType.Name',
            'LSC_LevyId__r.LSC_TotalPaidAmount__c',
            'LSC_LevyId__r.LSC_AccountId__r.RecordType.Name',
            'LSC_LevyId__r.LSC_AccountId__r.BillingStreet', 
            'LSC_LevyId__r.LSC_AccountId__r.BillingCity', 
            'LSC_LevyId__r.LSC_AccountId__r.BillingState', 
            'LSC_LevyId__r.LSC_AccountId__r.BillingPostalCode',  
            'LSC_LevyId__r.LSC_AccountId__r.BillingCountry',
            'LSC_LevyId__r.LSC_AccountId__r.LSC_IndividualFirstName__c', 
            'LSC_LevyId__r.LSC_AccountId__r.LSC_IndividualLastName__c',
            'LSC_LevyId__r.LSC_ApplicantFirstName__c',
            'LSC_LevyId__r.LSC_ApplicantLastName__c',
            'LSC_LevyId__r.LSC_ApplicantMailingAddress__c',
            'LSC_LevyId__r.LSC_TotalPaidDebit__c',
            'LSC_LevyId__r.LSC_ApplicationType__c',
            'LSC_LevyId__r.LSC_TotalInterestPaidAmount__c'
        };                    
    }
}