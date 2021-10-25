/**
 * @description       : 
 * @author            : Surya Reddy
 * @group             : 
 * @last modified on  : 04-14-2021
 * @last modified by  : Surya Reddy
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   04-12-2021   Surya Reddy   Initial Version
**/
public without sharing class LSC_BusinessDetailsController {

    @AuraEnabled
    public static string addNewBusinessContact(String recBusinessDetailsContact)
    {
        if (LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId())) {
            throw LSC_Utility.createAuraException(System.label.BCI_Session_Expiry_Error);
        }
        Contact recContact;
        try
        {   
            List<AccountContactRelation> lstACR;
            AccountContactRelation acr;
            LSC_AccountController.BusinessDetailsContactWrapper recBDCWrapper = (LSC_AccountController.BusinessDetailsContactWrapper) JSON.deserialize(recBusinessDetailsContact, LSC_AccountController.BusinessDetailsContactWrapper.class);
            if(recBDCWrapper.recContact != null  && String.isBlank(recBDCWrapper.recContact.Id)){  // Create New Contact and Update ACR
                recContact = recBDCWrapper.recContact;
                Id contactOwnerId = [Select MasterLabel, Owner_Id__c from LSC_DefaultOwner__mdt where DeveloperName = 'Account' Limit 1].Owner_Id__c;
                recContact.OwnerId = contactOwnerId;
                insert recContact;

                //update Account Contact Releation
                upsertACR(recContact.AccountId,recContact.Id,recBDCWrapper.roles);
               
            }else if(recBDCWrapper.recContact != null  && String.isNotBlank(recBDCWrapper.recContact.Id)){  
                if (recBDCWrapper.inviteUser){ // Send Invite
                    //Check if Invite was already present for the given contact and account, if yes, resend the same invite with new verification code.
                    LSC_AccountInvite__c accInvite;
                    String randomNumString = String.valueof(Math.abs(Crypto.getRandomLong())).substring(0,6);
                    List<LSC_AccountInvite__c> lstAccountInvite = [SELECT Id,LSC_AccountId__c, LSC_Consent_Provided__c,LSC_Email__c, LSC_Roles__c,LSC_Secret_Id__c FROM LSC_AccountInvite__c WHERE LSC_AccountId__c =: recBDCWrapper.recContact.AccountId and LSC_ContactId__c =: recBDCWrapper.recContact.Id ];
                    if (lstAccountInvite != null && lstAccountInvite.size() == 1){
                        accInvite = lstAccountInvite[0];
                        accInvite.LSC_Consent_Provided__c = false;
                        accInvite.LSC_Roles__c = recBDCWrapper.roles;
                        accInvite.LSC_Secret_Id__c = randomNumString;
                    } else {
                        accInvite = new LSC_AccountInvite__c();
                        accInvite.LSC_AccountId__c = recBDCWrapper.recContact.AccountId;
                        accInvite.LSC_ContactId__c = recBDCWrapper.recContact.Id;
                        accInvite.LSC_Email__c = recBDCWrapper.recContact.Email;
                        accInvite.LSC_Roles__c = recBDCWrapper.roles;
                        accInvite.LSC_Secret_Id__c = randomNumString;
                    }
                    upsert accInvite;
                }
                else{
                    //Check if an Inactive ACR exists for the given contact and Account. If exists then make it active.
                     upsertACR(recBDCWrapper.recContact.AccountId,recBDCWrapper.recContact.Id,recBDCWrapper.roles);
                }
               
            }
            
            if (recBDCWrapper.activateUser){//Activate the community User
                //Publish platform Event to activate the Community User
                LSC_NewCommunityUser__e  userPlatformEvent = new LSC_NewCommunityUser__e ();
                userPlatformEvent.LSC_Contact_Id__c = recBDCWrapper.recContact.id;
                userPlatformEvent.LSC_User_Id__c = recBDCWrapper.acrUserId;
                userPlatformEvent.LSC_activateUser__c = true;
                EventBus.publish(new List<LSC_NewCommunityUser__e >{userPlatformEvent});
            }else if(recBDCWrapper.isUser){ //Create LSC Community User for the given contact.
                String username = LSC_Utility.constructUsername(recContact.Email);
                List<User> existingUsers = [SELECT Id, Username FROM User WHERE Username =: username];
                if (!existingUsers.isEmpty()) {
                    throw LSC_Utility.createAuraException(System.Label.Username_Already_Exists_Error);
                }
                createCommunityUser(new list<contact>{recContact});
            }
           return 'Success';  
        }Catch(Exception ex){
            LSC_LogHandler.logException('LSC_BusinessDetailsController', 'addNewBusinessContact', ex.getMessage(),ex.getLineNumber(),ex.getStackTraceString());
            throw LSC_PaymentController.createAuraException('Error while adding Business Contact');
        }         
    }


    public static void upsertACR(String accountId, String contactId, String roles){
        AccountContactRelation acr;
        List<AccountContactRelation> lstACR = [SELECT id,EndDate,IsActive from AccountContactRelation WHERE ContactId = :contactId and AccountId = :accountId];
        if(lstACR != null && lstACR.size() == 1){
            acr = new  AccountContactRelation();
            acr.Id= lstACR[0].Id;
            acr.StartDate = date.today();
            acr.Roles=roles;
            acr.LSC_IsLevyPayer__c = true; 
            acr.LSC_Schemes__c = 'BCI';
            if(!lstACR[0].isActive){
                acr.EndDate=null;
                acr.isActive=true;
            }
        }else {
                //Create New ACR
                acr = new  AccountContactRelation();
                acr.AccountId = accountId;
                acr.ContactId = contactId;
                acr.StartDate = date.today();
                acr.Roles = roles;
                acr.LSC_IsLevyPayer__c = true; 
                acr.LSC_Schemes__c = 'BCI';
        }
        upsert acr;
    }
    @AuraEnabled
    public static string processBusinessDetailsContacts(String accountId,String lstBusinessDetailsContacts)
    {
        if (LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId())) {
            throw LSC_Utility.createAuraException(System.label.BCI_Session_Expiry_Error);
        }
        try
        {   
            List<LSC_AccountController.BusinessDetailsContactWrapper> lstBusinessDetailsContactsWrapper = (List<LSC_AccountController.BusinessDetailsContactWrapper>) JSON.deserialize(lstBusinessDetailsContacts, List<LSC_AccountController.BusinessDetailsContactWrapper>.class);
            List<Contact> lstContacts=new List<Contact>();
            Map<Id,String> mapIdContactRole = new Map<Id,String>();
            Map<String,LSC_AccountController.BusinessDetailsContactWrapper> mapBusinessDetailsContacts = new Map<String,LSC_AccountController.BusinessDetailsContactWrapper>();
            
            for(LSC_AccountController.BusinessDetailsContactWrapper recBDCWrapper: lstBusinessDetailsContactsWrapper)
            {
                mapBusinessDetailsContacts.put(recBDCWrapper.key,recBDCWrapper); 
                lstContacts.add(recBDCWrapper.recContact);
            }
           
            if(!lstContacts.isEmpty())
            {
                Database.SaveResult[] srList = Database.update(lstContacts);
                for (Database.SaveResult  sr : srList) {
                    if (!sr.isSuccess()) {
                        LSC_LogHandler.logException('LSC_BusinessDetailsController', 'processBusinessDetailsContacts', sr.getErrors().toString(),124,'');
                    }
                }
            }
            
            for(LSC_AccountController.BusinessDetailsContactWrapper acb: mapBusinessDetailsContacts.values()){
                if(acb.isAdmin && acb.isDirector){
                    mapIdContactRole.put(acb.recContact.Id,'Admin;Director');
                }else if(acb.isAdmin){
                    mapIdContactRole.put(acb.recContact.Id,'Admin');
                }else if(acb.isDirector){
                    mapIdContactRole.put(acb.recContact.Id,'Director');
                }else{
                    mapIdContactRole.put(acb.recContact.Id,'');
                }
            }

            if( mapIdContactRole.size() >0){
                updateACRRoles(accountId,mapIdContactRole);
            }
         
            return 'Contacts processed Successfully';
        
        }Catch(Exception ex){
            LSC_LogHandler.logException('LSC_BusinessDetailsController', 'processBusinessDetailsContacts', ex.getMessage(),ex.getLineNumber(),ex.getStackTraceString());
        }         
        return null;
    }


    @AuraEnabled
    public static void deactivateBusinessContact(String accountId, String recBusinessDetailsContact)
    {
        if (LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId())) {
            throw LSC_Utility.createAuraException(System.label.BCI_Session_Expiry_Error);
        }
        List<AccountContactRelation> lstACR=new List<AccountContactRelation>();
        try
        {   
            LSC_AccountController.BusinessDetailsContactWrapper recBDCWrapper = (LSC_AccountController.BusinessDetailsContactWrapper) JSON.deserialize(recBusinessDetailsContact, LSC_AccountController.BusinessDetailsContactWrapper.class);
             //Deactivate ACR
            if(recBDCWrapper != null && recBDCWrapper.id !=null && recBDCWrapper.recContact.id !=null ){
                AccountContactRelation recACR = new AccountContactRelation();
                recACR.Id = recBDCWrapper.id;
                recACR.EndDate=System.today();
                recACR.isActive=false;
                update recACR;

                //Deactivate the user if there is only one ACR for the given contact
                lstACR = [SELECT id,AccountId,EndDate,IsActive from AccountContactRelation WHERE  ContactId = : recBDCWrapper.recContact.id];
                if(lstACR != null && lstACR.size() == 1 && String.isNotBlank(recBDCWrapper.acrUserId)){
                    Contact recContact = new Contact(id=recBDCWrapper.recContact.id, LSC_SelectedAccountId__c = null); // Remove the Selected ABN details on the contact only if that contact has one ACR.
                    update recContact;
                    
                    //Publish platform Event to deactive the Community User
                    LSC_NewCommunityUser__e  userPlatformEvent = new LSC_NewCommunityUser__e ();
                    userPlatformEvent.LSC_Contact_Id__c = recBDCWrapper.recContact.id;
                    userPlatformEvent.LSC_User_Id__c = recBDCWrapper.acrUserId;
                    EventBus.publish(new List<LSC_NewCommunityUser__e >{userPlatformEvent});
                }
            }
        }Catch(Exception ex){
            LSC_LogHandler.logException('LSC_BusinessDetailsController', 'deactivateBusinessContact', ex.getMessage(),ex.getLineNumber(),ex.getStackTraceString());
        } 
    }

    public static void updateACRRoles(Id accountId, Map<Id,String> mapIdContactRole){
        Map<Id,AccountContactRelation> mapACRsForUpdate = new Map<Id,AccountContactRelation>();
        for(AccountContactRelation recACR: [Select Id, LSC_IsLevyPayer__c, Roles, LSC_Schemes__c, StartDate,contactId,IsDirect from AccountContactRelation where AccountId =: accountId and ContactId in : mapIdContactRole.keySet() and IsActive = true]){
            if (mapIdContactRole.containsKey(recACR.contactId)){ //Update ACR for existing contacts 
                 Boolean isAdminCheked        =  mapIdContactRole.get(recACR.contactId) != null && ( mapIdContactRole.get(recACR.contactId).split(';').contains('Admin')) ? true : false;
                 Boolean isDirectorCheked     =  mapIdContactRole.get(recACR.contactId) != null && ( mapIdContactRole.get(recACR.contactId).split(';').contains('Director')) ? true : false;
                 Boolean isACRContainsAdminRole    = recACR.roles != null && recACR.roles.split(';').contains('Admin') ? true : false;
                 Boolean isACRContainsDirectorRole = recACR.roles != null && recACR.roles.split(';').contains('Director') ? true : false;
                if(isACRContainsAdminRole && !isAdminCheked){// Remove Admin role if the user unchecks Admin on UI.
                    //remove Admin role
                    recACR = removeRole(recACR,'Admin');
                    mapACRsForUpdate.put(recACR.Id,recACR);
                }else if (!isACRContainsAdminRole && isAdminCheked){//Add Admin role if user checks Admin on UI
                    recACR.Roles= String.isNotBlank(recACR.roles)? recACR.roles+';'+ 'Admin': 'Admin';
                    mapACRsForUpdate.put(recACR.Id,recACR);
                }

                if(isACRContainsDirectorRole && !isDirectorCheked){// Remove Director role if the user unchecks Director on UI.
                    //remove Admin role
                    recACR = removeRole(recACR,'Director');
                    mapACRsForUpdate.put(recACR.Id,recACR);
                }else if (!isACRContainsDirectorRole && isDirectorCheked){//Add Director role if user checks Dirctor on UI
                    recACR.Roles= String.isNotBlank(recACR.roles)? recACR.roles+';'+ 'Director': 'Director';
                    mapACRsForUpdate.put(recACR.Id,recACR);
                }
            }
        }
        
        if(mapACRsForUpdate.size()>0){
            update mapACRsForUpdate.values();
        }
    }

    private static AccountContactRelation removeRole(AccountContactRelation recACR, String role){
        if(recACR != null  && recACR.roles != null && role != null){
            List<String> lstRoles= recACR.roles.split(';');
            lstRoles.remove(lstRoles.indexOf(role));
            recACR.roles=String.join(lstRoles,';');
        }  
        return recACR;
    }
    
    public static void createCommunityUser(List<Contact> lstContacts){

        List<User> lstNewUsers = new List<User>();
        
        //Get the Community Profile ID's        
        Id profileId= [SELECT Id FROM Profile WHERE Name = 'LSC Customer Community Login User'  LIMIT 1].Id;
        List<LSC_NewCommunityUser__e > events = new List<LSC_NewCommunityUser__e >();
            
        for(Contact recContact : lstContacts){
            //create a random community nickname
            String hashString = recContact.LastName + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
            Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
            String hexDigest = EncodingUtil.convertToHex(hash);
            String username = LSC_Utility.constructUsername(recContact.Email);
           //create User
            User newUser = new User(Email = recContact.email, 
                                    UserName = username, FirstName = recContact.FirstName,
                                    LastName = recContact.LastName, communityNickname = hexDigest, ProfileId = profileId, ContactId = recContact.Id);

            //Publish platform Event for Community Users
            LSC_NewCommunityUser__e  userPlatformEvent = new LSC_NewCommunityUser__e ();
            userPlatformEvent.LSC_Is_Create__c  = true;
            userPlatformEvent.LSC_Contact_Id__c = recContact.Id;
            userPlatformEvent.LSC_First_Name__c = recContact.FirstName;
            userPlatformEvent.LSC_Last_Name__c  = recContact.LastName;
            userPlatformEvent.LSC_Email__c      = recContact.Email;
            userPlatformEvent.LSC_Username__c   = username;
            userPlatformEvent.LSC_profile_Id__c = profileId;
            userPlatformEvent.LSC_Alias__c      = hexDigest.substring(0,7);
            userPlatformEvent.LSC_Community_Nick_Name__c = hexDigest;
            userPlatformEvent.LSC_Email_Confirmation_Expiry__c = Datetime.now().addHours(1);
            userPlatformEvent.LSC_Email_Confirmation_Link__c = LSC_EmailConfirmationUtility.generateEmailId();
            
            events.add(userPlatformEvent); 
         
        }

        if(events.size() > 0) {
            EventBus.publish(events);
        }
       
    }

    //Check if the user exists, if yes then determine this user belongs to same ABN or not.
    @AuraEnabled
    public static UserDetailsWrapper verifyUserLinkWithABN(String email, String abn, String accountId){
        if (LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId())) {
            throw LSC_Utility.createAuraException(System.label.BCI_Session_Expiry_Error);
        }
        UserDetailsWrapper userDetailsWrapper;
        try {
            userDetailsWrapper = new UserDetailsWrapper();
            Boolean userPartofSameABN = false;
            Boolean userPartOfSameOtherABN = false;
            Boolean sendInvite = false;
            List<AccountContactRelation> lstACR;
            AccountContactRelation acr;
          
            if(email == UserInfo.getUserEmail()){ // trying to use the logged in user email, so return
                userDetailsWrapper.isUserExist = true;
                userDetailsWrapper.isUserActive = true;
                userDetailsWrapper.isUserPartOfSameABN = true;
                return userDetailsWrapper;
            }
            if(String.isNotBlank(email) && email != UserInfo.getUserEmail()  && String.isNotBlank(abn)){
                String username = LSC_Utility.constructUsername(email);
                List<User> userList = [Select Id,Username, Email, isActive, contact.Id, AccountId,Account.RecordType.Name,contact.FirstName,contact.lastName,contact.Phone,contact.Email from User where Username =: username];
                
                if(userList != null && userList.Size() > 0){//User exists?
                    userDetailsWrapper.userId     = userList[0].Id;
                    userDetailsWrapper.firstName  = userList[0].contact.FirstName;
                    userDetailsWrapper.lastName   = userList[0].contact.LastName;
                    userDetailsWrapper.phone      = userList[0].contact.Phone;
                    userDetailsWrapper.email      = userList[0].email;
                    userDetailsWrapper.isUserExist  = true;
                    userDetailsWrapper.isUserActive = userList[0].isActive;
                    userDetailsWrapper.contactId      = userList[0].contact.Id;
    
                    set<String> setEmails = new Set<String>{email,UserInfo.getUserEmail()};

                    //Check if the user is related to an Individual Account
                    if(userList[0].Account.Recordtype.Name == LSC_GlobalConstants.LSC_ACCOUNT_RECORDTYPENAME_INDIVIDUAL){
                        userDetailsWrapper.isIndividualAccountUser = true;
                        return userDetailsWrapper;
                    }
                    
                    // Check if the user is inactive and acount is same as account related to that user
                    if(accountId == userList[0].AccountId){
                        lstACR = [SELECT id,EndDate,IsActive,Account.RecordType.Name from AccountContactRelation WHERE contactId = :userList[0].contact.Id and AccountId = :userList[0].AccountId];
                        if(lstACR != null && lstACR.size() == 1 && !lstACR[0].isActive ){
                             if (!userDetailsWrapper.isUserActive){
                                userDetailsWrapper.activateUser= true;
                             }else{
                                userDetailsWrapper.isUserPartOfSameOtherABN = true; // active User, already part of the ABN but inactive ACR.
                             }
                            return userDetailsWrapper; 
                        }
                    }

                    for( AggregateResult ar : [select COUNT(account.Id) totalCount, account.LSC_ABN__c  from AccountContactRelation where contact.email in :setEmails and isActive=true GROUP by account.LSC_ABN__c ]){
                        if(ar.get('LSC_ABN__c') == abn && ar.get('totalCount') <> 1){ // Both Users are part of the Same ABN
                            userPartofSameABN = true;
                        }else if(ar.get('LSC_ABN__c') != abn && ar.get('totalCount') <> 1){ // Both Users are part of the another ABN
                            userPartOfSameOtherABN = true;
                        }else if (ar.get('totalCount') == 1){
                            sendInvite = true;
                        }
                    }

                    if(userPartofSameABN){
                        userDetailsWrapper.isUserPartOfSameABN = true;
                    }else if(userPartOfSameOtherABN){
                        userDetailsWrapper.isUserPartOfSameOtherABN = true;
                    }else if(sendInvite){
                        userDetailsWrapper.isSendInvite = true;
                    }
                }
            }
        } catch (Exception ex) {
            LSC_LogHandler.logException('LSC_BusinessDetailsController', 'verifyUserLinkWithABN', ex.getMessage(),ex.getLineNumber(),ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
        return userDetailsWrapper;   
    }

    @AuraEnabled(cacheable=true)
    public static AccountInviteWrapper getAccountInviteDetails(String accountInviteId) {
        AccountInviteWrapper accInviteWrapper;
        List<LSC_AccountInvite__c> lstAccountInvites = [SELECT Id,LSC_AccountId__c, LSC_AccountId__r.Name, LSC_Consent_Date_time__c, LSC_Consent_Provided__c,LSC_Email__c, LSC_Roles__c,LSC_Secret_Id__c FROM LSC_AccountInvite__c WHERE Id =: accountInviteId  and LSC_Consent_Provided__c = false and LSC_Email__c =: UserInfo.getUserEmail()];
       
        if (lstAccountInvites != null && lstAccountInvites.size() ==1){
            accInviteWrapper = new AccountInviteWrapper(lstAccountInvites[0]);
        }
         return accInviteWrapper;
    }

    @AuraEnabled
    public static Boolean acceptInvite(String accInviteId, String verificationCode){
        Boolean inviteAccepted = false;
        try{
            List<LSC_AccountInvite__c> lstAccountInvites = [SELECT Id,LSC_Secret_Id__c, LSC_AccountId__c, LSC_ContactId__c, LSC_Roles__c FROM LSC_AccountInvite__c WHERE Id =: accInviteId and LSC_Secret_Id__c =: verificationCode ];
            if (lstAccountInvites != null && lstAccountInvites.size() == 1){
                //Insert ACR 
                upsertACR(lstAccountInvites[0].LSC_AccountId__c,lstAccountInvites[0].LSC_ContactId__c,lstAccountInvites[0].LSC_Roles__c);
                
                //Update Account Invite
                LSC_AccountInvite__c accountInvite = new LSC_AccountInvite__c();
                accountInvite.id = lstAccountInvites[0].Id;
                accountInvite.LSC_Consent_Provided__c = true;
                accountInvite.LSC_Consent_Date_time__c = System.today();
                update accountInvite;
                inviteAccepted = true;
            }
        }catch(Exception ex){
            LSC_LogHandler.logException('LSC_BusinessDetailsController', 'verifyUserLinkWithABN', ex.getMessage(),ex.getLineNumber(),ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
        
        return inviteAccepted;
    }


   

    
    public class UserDetailsWrapper {
        @AuraEnabled public String userId {get;set;}
        @AuraEnabled public String contactId {get;set;}
        @AuraEnabled public String firstName {get;set;}
        @AuraEnabled public String lastName {get;set;}
        @AuraEnabled public String phone {get;set;} 
        @AuraEnabled public String email {get;set;} 
        @AuraEnabled public Boolean isUserExist {get;set;}
        @AuraEnabled public Boolean isUserActive {get;set;}
        @AuraEnabled public Boolean isUserPartOfSameABN {get;set;}
        @AuraEnabled public Boolean isUserPartOfSameOtherABN {get;set;}
        @AuraEnabled public Boolean isSendInvite {get;set;}
        @AuraEnabled public Boolean activateUser {get;set;}
        @AuraEnabled public Boolean isIndividualAccountUser {get;set;}
    } 

    public class AccountInviteWrapper {
        @AuraEnabled public String Id {get;set;}
        @AuraEnabled public String accountId {get;set;}
        @AuraEnabled public String accountName {get;set;}
        @AuraEnabled public String email {get;set;}
        @AuraEnabled public String contactId {get;set;}
        @AuraEnabled public String selectedRoles {get;set;}
        @AuraEnabled public Boolean consentProvided {get;set;} 
        @AuraEnabled public Datetime consentProvidedDateTime {get;set;}

        public AccountInviteWrapper(LSC_AccountInvite__c accInvite){
            this.Id = accInvite.Id;
            this.accountId = accInvite.LSC_AccountId__c;
            this.accountName = accInvite.LSC_AccountId__r.Name;
            this.selectedRoles = accInvite.LSC_Roles__c;
            this.email = accInvite.LSC_Email__c;
            this.consentProvided = accInvite.LSC_Consent_Provided__c;
        }
    }
}