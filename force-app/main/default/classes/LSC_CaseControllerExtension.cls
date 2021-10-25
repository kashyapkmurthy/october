public with sharing class LSC_CaseControllerExtension {
    public Case recCase {get;set;}
    public Boolean renderPage { get; set; }
    //Instalment Approval Varibales
    public List<displayInstalmentDetails> displayInstalDetails{get;set;}
    public Decimal totalAmountDue {get;set;}
    public Integer loopCounter {get;set;}
    public String applicantName { get; set; }
    public String applicantMailingAddress { get; set; }
    
    public LSC_CaseControllerExtension(ApexPages.StandardController stdController) {
        try{
            //Check if User has access to this record
            Boolean userAccess = [SELECT Id, UserRecordAccess.HasReadAccess FROM Case WHERE Id =: ApexPages.currentPage().getParameters().get('id')].UserRecordAccess.HasReadAccess;
            if(userAccess == false){
                this.renderPage = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Page cannot be accessed. Please contact your service desk for further assistance.'));
                return;
            }
            
            
            // Get record
            if (!Test.isRunningTest()){
                stdController.addFields(getFieldNames());
            }
            this.recCase = (Case) stdController.getRecord();
            
            //Render Page only if VF page user is trying to access is according to the case type and Case should be Closed Approved.
            String currentVFPageName = getVFPageName();
   
            if ((this.recCase.Status == 'Closed Approved')  &&
                ((currentVFPageName == 'ExemptionApprovalOwnerBuilder' && this.recCase.Type == 'Owner builder') ||
                 (currentVFPageName == 'ExemptionApprovalNonProfit' && this.recCase.Type == 'Non profit') ||
                 //(currentVFPageName == 'ExemptionApproval' && this.recCase.Type == 'Bushfire recovery') ||
                 (currentVFPageName == 'InstalmentApproval' && (this.recCase.Type == 'Equal instalments' || this.recCase.Type == 'Staged instalments')))){
                     this.renderPage = true;
                 } else{
                     this.renderPage = false;
                     if(UserInfo.getUserType() == 'Standard'){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This record is either not the correct type of record or is not Paid/Approved'));
                    }else{
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Page cannot be accessed.'));
                    }
                     return;
                 }
            String billingStreetName = this.recCase.Account.BillingStreet+' '+this.recCase.Account.BillingCity+' '+this.recCase.Account.BillingState+' '+this.recCase.Account.BillingPostalCode;
            //Development Applicatant details
            this.applicantName = this.recCase.LSC_LevyId__r.LSC_ApplicantFirstName__c == Null? this.recCase.Account.Name : this.recCase.LSC_LevyId__r.LSC_ApplicantFirstName__c+' '+this.recCase.LSC_LevyId__r.LSC_ApplicantLastName__c;
            this.applicantMailingAddress = this.recCase.LSC_LevyId__r.LSC_ApplicantFirstName__c == Null? billingStreetName : this.recCase.LSC_LevyId__r.LSC_ApplicantMailingAddress__c;
           
            //For InstalmentApproval PDF the following checks need to be satisfied
            if(this.recCase.Type == 'Equal instalments' || this.recCase.Type == 'Staged instalments'){
                this.parseInstalmentDetails();
            }
            
        }catch(exception ex){
            //Catch Exceptions
            system.debug('In exception...'+ex.getMessage()+' '+ex.getStackTraceString());
            this.renderPage = false;           
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'It looks like there was a problem. Please contact your service desk for further assistance.'));
        }
    }
    
    
    public static List<String> getFieldNames(){
        return new List<String> {
            'Id',
                'CaseNumber',
                'ClosedDate',
                'Type',
                'Status',
                'LSC_InstalmentDetails__c',
                'LSC_ApprovedExemptionPercentage__c',
                'LSC_ApprovedVoluntaryLabourCost__c',
                'account.Name',
                'account.BillingStreet',
                'account.BillingCity',
                'account.BillingState',
                'account.BillingPostalCode',
                'account.LSC_ABN__c',
                'LSC_LevyId__r.Id',
                'LSC_LevyId__r.Name',
                'LSC_LevyId__r.LSC_OwnerBuilderLicenceNo__c',
                'LSC_LevyId__r.LSC_ApplicationNumber__c',
                'LSC_LevyId__r.LSC_ApplicationType__c',
                'LSC_LevyId__r.LSC_LocalGovtAreaOrGovtAuthority__c',
                'LSC_LevyId__r.LSC_SiteAddressStreet__c',
                'LSC_LevyId__r.LSC_SiteAddressCity__c',
                'LSC_LevyId__r.LSC_SiteAddressState__c',
                'LSC_LevyId__r.LSC_SiteAddressPostCode__c',
                'LSC_LevyId__r.LSC_VoluntaryLabourCostofWorks__c',
                'LSC_LevyId__r.LSC_CostOfWorks__c',
                'LSC_LevyId__r.LSC_TotalLevyPayable__c',
                'LSC_LevyId__r.LSC_ApplicantFirstName__c',
                'LSC_LevyId__r.LSC_ApplicantLastName__c',
                'LSC_LevyId__r.LSC_ApplicantMailingAddress__c'
                };
                    
                    }
    
    private void parseInstalmentDetails(){
        List<LSC_LevyPaymentUtility.InstalDetailsWrapper> instalmentDetails;
        displayInstalDetails = new List<displayInstalmentDetails>();
        Decimal cost;
        Integer instalNo = 0;
        totalAmountDue = 0;
        loopCounter = 0;
        instalmentDetails = (List<LSC_LevyPaymentUtility.InstalDetailsWrapper>)JSON.deserialize(this.recCase.LSC_InstalmentDetails__c, List<LSC_LevyPaymentUtility.InstalDetailsWrapper>.class);
        if(this.recCase.Type == 'Staged instalments')
            loopCounter = instalmentDetails.Size() - 1;
        else
            loopCounter = instalmentDetails.Size();
        //Prepare instalment details array to display them to the User
        for(LSC_LevyPaymentUtility.InstalDetailsWrapper i: instalmentDetails){
            displayInstalmentDetails tempArray = new displayInstalmentDetails();
            instalNo++;
            if(instalNo <= loopCounter){
                tempArray.instalmentNo = instalNo;
                if(instalNo == 1){
                    tempArray.dueDate = 'Prior to works commencing';
                }else{
                    String newDate = i.startDate;
                    system.debug(newDate);
                    List<String> dateParts = newDate.split('-');
                    Datetime dateWithTime;
                    if(this.recCase.Type == 'Staged instalments')
                        dateWithTime = Datetime.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
                    else
                        dateWithTime = Datetime.newInstance(Integer.valueOf(dateParts[2]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[0]));
                    tempArray.dueDate = dateWithTime.format('dd/MM/yyyy');
                }
                cost = i.levyAmt;
                tempArray.amountDue = cost.setScale(2);
                totalAmountDue += tempArray.amountDue;
                displayInstalDetails.add(tempArray);
            }
        }
    }
    
    private string getVFPageName()  {
        String pageName = ApexPages.CurrentPage().getUrl();    
        pageName = pageName.replaceFirst('/apex/','');         
        pageName = EncodingUtil.urlEncode(pageName, 'UTF-8');  
        string[] pageNameExtra = pageName.split('%3F',0);  
        pageName = pageNameExtra[0];                           
        return pageName;                                      
    }
    
    public class displayInstalmentDetails{
        public Integer instalmentNo {get;set;}
        public String dueDate {get;set;}
        public Decimal amountDue {get;set;}
    }
}