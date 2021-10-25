public without sharing class LSC_LevyPaymentUtility {
    private static final Map<String, String> userType = new Map<String, String>{'Individual' => 'Individual', 'nfp' => 'Organisation', 'Business' => 'Business'};
    private static final Decimal LEVYAMT_PERC_CALC = 0.0035;
	@AuraEnabled(cacheable=true)
    public static String getUserAccountInfo() {
        Account accRec;
        String accType;
        //Get User Account details
        Id contactId = currentUserContactId();
        Id accountId = currentUserAccountId();
        //Check if User is a Levy Payer for this account
        List<AccountContactRelation> acrRecs = [Select AccountId, Account.RecordType.Name, Account.RecordTypeId, Account.Type from AccountContactRelation where ContactId =: contactId and AccountId =: accountId and LSC_IsLevyPayer__c = true];
        if(!acrRecs.isEmpty() && acrRecs.Size() > 0){
			accType = acrRecs[0].Account.RecordType.Name;
            if(accType == 'Business' && acrRecs[0].Account.Type == 'Not For Profit'){
                accType = 'nfp';
            }
            return userType.get(accType);
    	}
        return null;
    }
    
    @AuraEnabled
    public static String deleteDocument(String docId){
        try{
            delete [SELECT Id FROM ContentDocument WHERE Id = :docId];
            return 'SUCCESS';
        }
        catch(Exception e){
            LSC_LogHandler.logException('LSC_LevyPaymentUtility', 'deleteDocument', e.getMessage(),e.getLineNumber(),e.getStackTraceString());
            return 'FAILED';
        }
    }
    
    @TestVisible
    public static String currentUserAccountId(){
        try{
            List<User> users = [Select Id, ContactId, Contact.LSC_SelectedAccountId__c, AccountId from User where Id =: UserInfo.getUserId()];
            Id accountId;
            if(users[0].ContactId != null && users[0].Contact.LSC_SelectedAccountId__c != null) {
                accountId = users[0].Contact.LSC_SelectedAccountId__c;
            }
            else if(users[0].AccountId != null) {
                accountId = users[0].AccountId;
            }
            return accountId;
        }
        catch(Exception e){
            LSC_LogHandler.logException('LSC_LevyPaymentUtility', 'currentUserAccountId', e.getMessage(),e.getLineNumber(),e.getStackTraceString());
            return null;
        }
    }
    
    @TestVisible
    private static String currentUserContactId(){
        try{
            List<User> users = [Select Id, ContactId, Contact.LSC_SelectedAccountId__c, AccountId from User where Id =: UserInfo.getUserId()];
            if(users[0].ContactId != null) {
                return users[0].ContactId;
            }
            return null;
        }
        catch(Exception e){
            LSC_LogHandler.logException('LSC_LevyPaymentUtility', 'currentUserContactId', e.getMessage(),e.getLineNumber(),e.getStackTraceString());
            return null;
        }
    }

    @TestVisible
    private static String currentUserEmailId(){
        try{
            List<User> users = [Select Id, Email from User where Id =: UserInfo.getUserId()];
            if(users[0].Email != null) {
                return users[0].Email;
            }
            return null;
        }
        catch(Exception e){
            LSC_LogHandler.logException('LSC_LevyPaymentUtility', 'currentUserContactId', e.getMessage(),e.getLineNumber(),e.getStackTraceString());
            return null;
        }
    }      
    
    @AuraEnabled(cacheable=true)
    public static Boolean checkRecordLocked(String recordId){
        if(recordId != null)
			return Approval.isLocked(recordId);
        else
            return false;
    }    
    
    @AuraEnabled
    public static Map<String, Object> createLevyPayment(String requestDetails){
        if (LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId())) {
            throw LSC_Utility.createAuraException(System.label.BCI_Session_Expiry_Error);
        }
        Map<string, Object> outputMap = new Map<string, Object>();
        Id levyBCIRecordTypeId = LSC_Levy__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_BCI').getRecordTypeId();
        Id caseExemptionRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Exemption').getRecordTypeId();
        Id caseInstalmentRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Instalment').getRecordTypeId();
        Id transLevyRecordTypeId = LSC_Transaction__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Levy').getRecordTypeId();
        Boolean insertCaseFlag = false, insertTransFlag = false;
        Savepoint sp = Database.setSavepoint();
        try{
            system.debug('I am in create acc..'+requestDetails);
            LevyPaymentWrapper requestMap = (LevyPaymentWrapper)JSON.deserialize(requestDetails, LevyPaymentWrapper.class);
            system.debug('I am in create acc..'+requestMap);
            String userJourney = requestMap.userJourney != null? requestMap.userJourney : '';
            //Create a Case record
            Case caseRec = new Case();
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.useDefaultRule = true;
            caseRec.setOptions(dmlOpts);
            //Create a Transaction record
            LSC_Transaction__c transRec = new LSC_Transaction__c();
            transRec.LSC_RepEmail__c = currentUserEmailId();
            //Create a Levy record
            LSC_Levy__c levyRec = new LSC_Levy__c();
            levyRec.RecordTypeId = levyBCIRecordTypeId;
            levyRec.LSC_AccountId__c = currentUserAccountId();
            //For all the user journeys auth rep field should be current User's contact Id
            levyRec.LSC_AuthorisedRepresentativeId__c = currentUserContactId();
            /* Dev Details */
            levyRec.LSC_ApplicationType__c = requestMap.developmentDetails.appType;
            levyRec.LSC_ApplicationNumber__c = requestMap.developmentDetails.appNumber;
            levyRec.LSC_PlanningNumber__c = requestMap.developmentDetails.planningPortalNumber;
            levyRec.LSC_LocalGovtAreaOrGovtAuthority__c = requestMap.developmentDetails.govtAuth;
            levyRec.LSC_SiteAddressStreet__c = requestMap.constructionSiteAddress.street;
            levyRec.LSC_SiteAddressCity__c = requestMap.constructionSiteAddress.city;
            levyRec.LSC_SiteAddressState__c = requestMap.constructionSiteAddress.state;
            levyRec.LSC_SiteAddressPostCode__c = requestMap.constructionSiteAddress.postcode;
            levyRec.LSC_ConstructionStartDate__c = requestMap.developmentDetails.startDate;
            levyRec.LSC_ConstructionEndDate__c = requestMap.developmentDetails.endDate;
            /* Dev Approval Details */
            levyRec.LSC_HasPrivateCertifier__c = requestMap.developmentApproval.approvingAuthority != null? true : false;
            levyRec.LSC_PrivateCertifierCompany__c = requestMap.developmentApproval.approvingAuthority != null? requestMap.developmentApproval.approvingAuthority : '';
            levyRec.LSC_PrivateCertifierName__c = requestMap.developmentApproval.contactName != null? requestMap.developmentApproval.contactName : '';
            levyRec.LSC_PrivateCertifierPhone__c = requestMap.developmentApproval.phone != null? requestMap.developmentApproval.phone : '';
            levyRec.LSC_PrivateCertifierEmail__c = requestMap.developmentApproval.email != null? requestMap.developmentApproval.email : '';            
            /* Dev Cost Details & Instalments & AuthRep Details */
            levyRec.LSC_LevyPayable__c = requestMap.developmentCostsDetails.levyPayable;
            if(userJourney == 'Individual'){
                String hasExemption = requestMap.developmentCostsDetails.levyExemptionOption;
                system.debug(hasExemption);
                levyRec.LSC_CostOfWorks__c = requestMap.developmentCostsDetails.totalBuildConstCost;
                if(hasExemption == 'yes'){ 
                    levyRec.LSC_ExemptionType__c = 'Owner Builder';
                    levyRec.LSC_HasOwnerBuilderLicence__c = true;
                    levyRec.LSC_VoluntaryLabourCostofWorks__c = requestMap.developmentCostsDetails.estCostVoluntaryLabor;
                    levyRec.LSC_OwnerBuilderLicenceId__c = requestMap.ownerBuilderDetails.licenceID;
                    levyRec.LSC_OwnerBuilderLicenceNo__c = requestMap.ownerBuilderDetails.licenceNumber;
                    levyRec.LSC_OwnerBuilderLicenceStatus__c = requestMap.ownerBuilderDetails.status;
                    levyRec.LSC_OwnerBuilderLicenceStartDate__c = requestMap.ownerBuilderDetails.startDate;
                    levyRec.LSC_OwnerBuilderLicenceExpiryDate__c = requestMap.ownerBuilderDetails.expiryDate;
                    levyRec.LSC_OwnerBuilderLicenceType__c = requestMap.ownerBuilderDetails.licenceType;
                    levyRec.LSC_OwnerBuilderLicenceeName__c = requestMap.ownerBuilderDetails.licensee;
                    //If totalCost is greater than 500000 create Case
                    if(requestMap.developmentCostsDetails.totalBuildConstCost >= 500000){
                        insertCaseFlag = true;
                        levyRec.LSC_ApplicationStatus__c = 'Awaiting Exemption Decision';
                        caseRec.RecordTypeId = caseExemptionRecordTypeId;
                        caseRec.Type = 'Owner builder';
                        caseRec.LSC_Scheme__c = 'BCI';
                        caseRec.Subject = 'Owner Builder Exemption';
                        caseRec.Description = 'Exemption requested for Levy ';
                        caseRec.Origin = 'Portal';
                    }
                    //Set the exemption flag to true where total cost is less than 500000 and calculate exemption percentage
                    else{
                        levyRec.LSC_HasExemption__c = true;
                        levyRec.LSC_ApprovedVoluntaryLabourcost__c = requestMap.developmentCostsDetails.estCostVoluntaryLabor;
                       	Decimal totalCost = requestMap.developmentCostsDetails.totalBuildConstCost;
                        Decimal volLabourCost = requestMap.developmentCostsDetails.estCostVoluntaryLabor;
                        levyRec.LSC_LevyPayable__c = (totalCost * LEVYAMT_PERC_CALC).round(System.RoundingMode.DOWN);
                    }
                } //if exemption is selected as no or (exemption is yes and total cost is less than 500000)
                if(hasExemption == 'no' || requestMap.developmentCostsDetails.totalBuildConstCost < 500000){
                    insertTransFlag = true;
                    system.debug('has exemption mo'+insertTransFlag);
                    levyRec.LSC_ApplicationStatus__c = 'Ready to be paid';
                    transRec.RecordTypeId = transLevyRecordTypeId;
                    transRec.LSC_Status__c = 'Pending';
                }
            } else if(userJourney == 'Organisation'){
                String hasExemption = requestMap.developmentCostsDetails.levyExemptionOption;
                String hasInstalments = requestMap.instalmentCmpDetails != null? requestMap.instalmentCmpDetails.payLevyInstal: null;
                levyRec.LSC_CostOfWorks__c = requestMap.developmentCostsDetails.totalBuildConstCost;
                if(hasExemption == 'yes'){
                    levyRec.LSC_ExemptionType__c = 'Non-Profit';
                    insertCaseFlag = true;
                    levyRec.LSC_VoluntaryLabourCostofWorks__c = requestMap.developmentCostsDetails.estCostVoluntaryLabor;
                    levyRec.LSC_ApplicationStatus__c = 'Awaiting Exemption Decision';
                    caseRec.RecordTypeId = caseExemptionRecordTypeId;
                    caseRec.Type = 'Non profit';
                    caseRec.LSC_Scheme__c = 'BCI';
                    caseRec.Subject = 'Not For Profit Exemption';
                    caseRec.Description = 'Exemption requested for Levy ';
                    caseRec.Origin = 'Portal';
                }
                else if(hasExemption == 'no'){
                    if(hasInstalments == 'yes'){
                        insertCaseFlag = true;
                        levyRec.LSC_ApplicationStatus__c = 'Awaiting Instalments Decision';
                        caseRec.RecordTypeId = caseInstalmentRecordTypeId;
                        caseRec.LSC_Scheme__c = 'BCI';
                        caseRec.Subject = 'Request for instalments';
                        caseRec.Description = 'Intalments were requested for Levy ';
                        caseRec.Origin = 'Portal';
                        String instalmentType = requestMap.instalmentCmpDetails.instalOption;
                        List<InstalDetailsWrapper> instDetailWrapperLst = new List<InstalDetailsWrapper>();
                        if(instalmentType == 'presetInstal'){
                            caseRec.Type = 'Equal instalments';
                            caseRec.LSC_Number_of_Instalments__c = '4';
                            for(InstalmentsWrapper i: requestMap.presetInstalments){
                                InstalDetailsWrapper instDetailWrapper = new InstalDetailsWrapper(i.dueDate, null, i.payNo, i.presetInstal, null, null, null);
                                instDetailWrapperLst.add(instDetailWrapper);
                            }
                            caseRec.LSC_InstalmentDetails__c = JSON.serialize(instDetailWrapperLst);
                        } else if(instalmentType == 'variableInstal'){
                            caseRec.Type = 'Staged instalments';
                            for(InstalmentsWrapper i: requestMap.variableInstalments){
                                InstalDetailsWrapper instDetailWrapper = new InstalDetailsWrapper(i.startDate, i.estimatedCost, i.stage, i.levyAmt, i.totalCost, i.totalLevyAmt, i.showDel);
                                instDetailWrapperLst.add(instDetailWrapper);
                            }
                            caseRec.LSC_InstalmentDetails__c = JSON.serialize(instDetailWrapperLst);
                        }
                        String primContact = requestMap.instalmentCmpDetails.primaryContact;
                        if(primContact == 'no'){
                            levyRec.InstalmentContactFirstName__c = requestMap.instalmentCmpDetails.givenName;
                            levyRec.InstalmentContactLastName__c = requestMap.instalmentCmpDetails.surName;
                            levyRec.LSC_InstalmentContactMobile__c = requestMap.instalmentCmpDetails.phone;
                            levyRec.LSC_InstalmentContactEmail__c = requestMap.instalmentCmpDetails.email;
                        }
                    }else{
                        insertTransFlag = true;
                        levyRec.LSC_ApplicationStatus__c = 'Ready to be paid';
                        transRec.RecordTypeId = transLevyRecordTypeId;
                        transRec.LSC_Status__c = 'Pending';     
                    }
                }
            } else if(userJourney == 'Business'){
                levyRec.LSC_CostOfWorks__c = requestMap.developmentCostsDetails.totalBuildConstCost;
                String hasInstalments = requestMap.instalmentCmpDetails != null? requestMap.instalmentCmpDetails.payLevyInstal: null;
                if(hasInstalments == 'yes'){
                    insertCaseFlag = true;
                    levyRec.LSC_ApplicationStatus__c = 'Awaiting Instalments Decision';
                    caseRec.RecordTypeId = caseInstalmentRecordTypeId;
                    caseRec.LSC_Scheme__c = 'BCI';
                    caseRec.Subject = 'Request for instalments';
                    caseRec.Description = 'Intalments were requested for Levy ';
                    caseRec.Origin = 'Portal';
                    String instalmentType = requestMap.instalmentCmpDetails.instalOption;
                    List<InstalDetailsWrapper> instDetailWrapperLst = new List<InstalDetailsWrapper>();
                    if(instalmentType == 'presetInstal'){
                        caseRec.Type = 'Equal instalments';
                        caseRec.LSC_Number_of_Instalments__c = '4';
                        for(InstalmentsWrapper i: requestMap.presetInstalments){
                        	InstalDetailsWrapper instDetailWrapper = new InstalDetailsWrapper(i.dueDate, null, i.payNo, i.presetInstal, null, null, null);
                            instDetailWrapperLst.add(instDetailWrapper);
                        }
                        caseRec.LSC_InstalmentDetails__c = JSON.serialize(instDetailWrapperLst);
                    } else if(instalmentType == 'variableInstal'){
                        caseRec.Type = 'Staged instalments';
                        for(InstalmentsWrapper i: requestMap.variableInstalments){
                        	InstalDetailsWrapper instDetailWrapper = new InstalDetailsWrapper(i.startDate, i.estimatedCost, i.stage, i.levyAmt, i.totalCost, i.totalLevyAmt, i.showDel);
                            instDetailWrapperLst.add(instDetailWrapper);
                        }
                        caseRec.LSC_InstalmentDetails__c = JSON.serialize(instDetailWrapperLst);
                    }
                    String primContact = requestMap.instalmentCmpDetails.primaryContact;
                    if(primContact == 'no'){
                        levyRec.InstalmentContactFirstName__c = requestMap.instalmentCmpDetails.givenName;
                        levyRec.InstalmentContactLastName__c = requestMap.instalmentCmpDetails.surName;
                        levyRec.LSC_InstalmentContactMobile__c = requestMap.instalmentCmpDetails.phone;
                        levyRec.LSC_InstalmentContactEmail__c = requestMap.instalmentCmpDetails.email;
                    }
                } else {
                    levyRec.LSC_ApplicationStatus__c = 'Ready to be paid';
                    insertTransFlag = true;
                    transRec.RecordTypeId = transLevyRecordTypeId;
                    transRec.LSC_Status__c = 'Pending';
                }
            }
            //Auth Rep details
            if(userJourney == 'Business' || userJourney == 'Individual'){
                String authRep = requestMap.authRepDetails.yourRole;
                if(authRep == 'yourRoleBehalf' || authRep == 'yourRoleBusinessBehalf'){
                    levyRec.LSC_ApplicantFirstName__c = requestMap.authRepDetails.givenName;
                    levyRec.LSC_ApplicantLastName__c = requestMap.authRepDetails.surName;
                    levyRec.LSC_ApplicantMobile__c = requestMap.authRepDetails.phone;
                    levyRec.LSC_ApplicantEmail__c = requestMap.authRepDetails.email;
                    levyRec.LSC_ApplicantMailingAddress__c = requestMap.postalAddress.fullAddress;
                }
            }
            //Declaration
            levyRec.LSC_IsDeclarationAccepted__c = requestMap.declaration;
            Datetime now = Datetime.now();
            levyRec.LSC_DeclarationAcceptedDateTime__c = now;
            insert levyRec;
            Map<String, Object> tempMap = new Map<String, Object>();
            if(insertCaseFlag == true){
                caseRec.LSC_LevyId__c = levyRec.Id;
                caseRec.Description += [Select Id, Name from LSC_Levy__c where Id =: levyRec.Id].Name;
                caseRec.AccountId = currentUserAccountId();
            	insert caseRec;
                tempMap.put('caseNo', [Select CaseNumber from Case where Id=: caseRec.Id].CaseNumber);
                tempMap.put('caseId', caseRec.Id);
            }
            if(insertTransFlag == true){
                transRec.LSC_DueDate__c = requestMap.developmentDetails.startDate;
				transRec.LSC_Amount__c = requestMap.developmentCostsDetails.levyPayable;
                transRec.LSC_LevyId__c = levyRec.Id;
                insert transRec;
                tempMap.put('transRecId', transRec.Id);
            }
            tempMap.put('caseFlag', insertCaseFlag);
            tempMap.put('transactionFlag', insertTransFlag);
            
            //Attach Files to the Case from Contact
            if(requestMap.uploadedFiles != null) {
                List<Id> docIds = new List<Id>();
                for(fileUploadWrapper files: requestMap.uploadedFiles){
                    docIds.add(files.id);
                }
                if(docIds != null && docIds.size() > 0) {
                    List<ContentDocumentLink> newCdls = new List<ContentDocumentLink>();
                    for(String docId : docIds) {
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = docId;
                        cdl.LinkedEntityId = caseRec.Id;
                        cdl.ShareType = 'I';
                        newCdls.add(cdl);
                    }                
                    insert newCdls;
            	}
            }
            outputMap.put('result', 'success');
 			outputMap.put('levyId', levyRec.Id);    
            outputMap.putAll(tempMap);
            return outputMap;
         }catch(exception e){
            LSC_LogHandler.logException('LSC_LevyPaymentUtility', 'createLevyPayment', e.getMessage(),e.getLineNumber(),e.getStackTraceString());
            Database.rollback(sp);
           	throw new AuraHandledException('Exception occured: ' + e.getMessage());      
        }
    }
    
    public class LevyPaymentWrapper{
        @AuraEnabled public DevDetailsWrapper developmentDetails;
        @AuraEnabled public DevCostsWrapper developmentCostsDetails;
        @AuraEnabled public LSC_RegistrationUtility.AddressWrapper constructionSiteAddress;
        @AuraEnabled public LSC_RegistrationUtility.AddressWrapper postalAddress;
        @AuraEnabled public OwnerBuilderApiWrapper ownerBuilderDetails;
        @AuraEnabled public DevApprovalWrapper developmentApproval;
        @AuraEnabled public AuthRepDetailsWrapper authRepDetails;
        @AuraEnabled public InstalCmpWrapper instalmentCmpDetails;
        @AuraEnabled public InstalmentsWrapper[] variableInstalments;
        @AuraEnabled public InstalmentsWrapper[] presetInstalments;
        @AuraEnabled public FileUploadWrapper[] uploadedFiles;
        @AuraEnabled public String userJourney;
        @AuraEnabled public Boolean declaration;
    }
    
    public class DevDetailsWrapper{
        @AuraEnabled public String appNumber;
        @AuraEnabled public String planningPortalNumber;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public String appType;
        @AuraEnabled public String govtAuth;
    }
    
   public class DevCostsWrapper{
        @AuraEnabled public Double totalBuildConstCost;
        @AuraEnabled public Double estCostVoluntaryLabor;
        @AuraEnabled public Double levyPayable;
        @AuraEnabled public String levyExemptionOption;
    }
    
    public class DevApprovalWrapper{
        @AuraEnabled public String approvingAuthority;
        @AuraEnabled public String contactName;
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
    }
    
	public class OwnerBuilderApiWrapper{
        @AuraEnabled public String licenceID;
        @AuraEnabled public String licenceNumber;
        @AuraEnabled public String licenceType;
        @AuraEnabled public String licensee;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date expiryDate;
        @AuraEnabled public String status;
    }
    
    public class AuthRepDetailsWrapper{
        @AuraEnabled public String yourRole;
        @AuraEnabled public String givenName;
        @AuraEnabled public String surName;
        @AuraEnabled public String phone;
        @AuraEnabled public String email; 
    }
    
    public class InstalCmpWrapper{
        @AuraEnabled public String payLevyInstal;
        @AuraEnabled public String instalOption;
        @AuraEnabled public String primaryContact;
        @AuraEnabled public String givenName;
        @AuraEnabled public String surName;
        @AuraEnabled public String phone;
        @AuraEnabled public String email; 
    }
    
    public class InstalDetailsWrapper{
        @AuraEnabled public String startDate;
        @AuraEnabled public Double estimatedCost;
        @AuraEnabled public String payNo;
        @AuraEnabled public Double levyAmt;
        @AuraEnabled public Double totalCost;
        @AuraEnabled public Double totalLevyAmt;
        @AuraEnabled public Boolean showDel;
        public InstalDetailsWrapper(String stDate, Double cost, string payNo, Double levyAmt, 
                                    Double totalCost, Double totalLvyAmt, Boolean showDel){
            this.startDate = stDate;
            this.estimatedCost = cost;
            this.payNo = payNo;
            this.levyAmt = levyAmt;
            this.totalCost = totalCost;
            this.totalLevyAmt = totalLvyAmt;
            this.showDel = showDel;
        }
    }
    
    public class FileUploadWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String id;
    }
    
    public class ContactDetailsWrapper{
        @AuraEnabled public String givenName;
        @AuraEnabled public String surName;
        @AuraEnabled public String phone;
        @AuraEnabled public String email; 
    }
    
    public class InstalmentsWrapper{
        @AuraEnabled public String id;
        @AuraEnabled public String stage;
        @AuraEnabled public String startDate;
        @AuraEnabled public Double estimatedCost;
        @AuraEnabled public String payNo;
        @AuraEnabled public Double presetInstal;
        @AuraEnabled public String dueDate;
        @AuraEnabled public Double levyAmt;
        @AuraEnabled public Double totalCost;
        @AuraEnabled public Double totalLevyAmt;
        @AuraEnabled public Boolean showDel;
    }
    
}