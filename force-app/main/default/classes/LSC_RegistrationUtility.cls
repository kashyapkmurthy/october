public without sharing class LSC_RegistrationUtility {
	@AuraEnabled(cacheable=true)
    //Check if User entered ABN is already exising on Accounts
    public static Map<String, String> checkABNonAccounts(String abn) {
        Map<String, String> result = new Map<String, String>();
        result.put('matched', 'no');
        List<Account> accLst = [Select Id from Account where LSC_ABN__c =: abn];
        if (!accLst.isEmpty() && accLst.Size()>0) {
            String portalAdminEmailAddress = LSC_AccountContactRelationshipService.getPortalAdminEmailAddress(accLst[0].Id);
            result.put('matched', 'yes');
            result.put('portalAdminEmailAddress', portalAdminEmailAddress);
        }
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    //Check if incomplete registration flag is set on the Contact
    public static Boolean checkForRegistrationStatus() {
        return [Select contact.LSC_InCompleteRegistration__c from User where Id =: UserInfo.getUserId()].contact.LSC_InCompleteRegistration__c;
    }    
    
	@AuraEnabled(cacheable=true)
    //Validate User entered email against all usernames on the User records
    public static Boolean validateUsername(String username) {
        // front end pass email to back end, need to add suffix
        if(username != null) {
            username = username.toLowerCase();
            username = LSC_Utility.constructUsername(username);
        }
        List<User> userList = [Select Id from User where Username =: username];
        if(!userList.isEmpty() && userList.Size()>0)
        	return true;
        else
            return false;
    } 
    
    @AuraEnabled(cacheable=true)
    //Get contact details of currently logged in User
    public static Map<String, Object> getContactDetails() {
        try{
            user u = [Select Id, contact.Email from User where Id=: UserInfo.getUserId()];
            return new Map<String, Object>{'result' => 'success', 'email' => u.contact.Email};
        }
        catch(exception e) {
            LSC_LogHandler.logException('LSC_RegistrationUtility', 'getContactDetails', e.getMessage(),e.getLineNumber(),e.getStackTraceString());
            return new Map<String, Object>{'result' => 'fail'};
        }
    } 
    
	@AuraEnabled
    //Once Guest User is successfully registered assign LSC_BCILevyUser to the User record
    public static Boolean assignPermissionSet(String userId) {
        Id permissionSetId = [Select Id from PermissionSet where Name='LSC_BCILevyUser'].Id;
        system.debug('I hit method assignPermissionSet');
        try{
            system.debug('I hit assignPermissionSet class-->'+userId);
            if(userId != null){
                PermissionSetAssignment pmSetAssign = new PermissionSetAssignment(AssigneeId=userId, PermissionSetId= permissionSetId);
                insert pmSetAssign;
            }
            return true;
        }
        catch(DmlException e) {
            LSC_LogHandler.logException('LSC_RegistrationUtility', 'assignPermissionSet', e.getMessage(),e.getLineNumber(),e.getStackTraceString());
            return false;
        }
    }
    
    
    /**
    * @ For user registered via Service NSW, need to remove .incompleted suffix after they complete registration 
    * @author Emily Jiang | 26/08/2021 
    * @param userId 
    * @return Boolean 
    **/
    @AuraEnabled
    public static Boolean updateUsername(String userId) {
        Savepoint sp = Database.setSavepoint();
        List<User> users = [SELECT Id, Username, Email, IsActive FROM User WHERE Id =: userId];
        try {
            if(userId != null && !users.isEmpty()){
                String newUsername = LSC_Utility.constructUsername(users[0].email);
                if (users[0].Username != newUsername) {
                    users[0].Username = newUsername;
                    users[0].IsActive = false;
                    update users;
                    users[0].IsActive = true;
                    update users;
                }
            }
            return true;
        } catch (Exception e) {
            Database.rollback(sp);
            return false;
        }
    }
    
	@AuraEnabled
    //Create Account, Contact for the Guest User registration (or) create Account and update Contact for SNSW User
    public static Map<string, Object> createAccountContact(String requestDetails) {
        Id profileId;
        Id nswAccountId;
        Savepoint sp = Database.setSavepoint();
        
        if (!Auth.CommunitiesUtil.isGuestUser()) {
            String newUsername = LSC_Utility.constructUsername(UserInfo.getUserEmail());
            List<User> existingUsers = [SELECT Id, Username, Email FROM User WHERE Username =: newUsername];
            if (!existingUsers.isEmpty()) {
                return new Map<string, Object>{'result' => false, 'errorMess'=> System.Label.Username_Already_Exists_Error};  
            }
        }
        try{
            registrationWrapper requestMap = (registrationWrapper)JSON.deserialize(requestDetails, registrationWrapper.class);
            if (LSC_Utility.isSandbox() && !Test.isRunningTest() && !LSC_Utility.isEmailAddressInWhiteList(requestMap.contactPageDetails.email)) {
                return new Map<string, Object>{'result' => false, 'errorMess'=> System.Label.Email_Address_Not_Allowed_In_Sandbox};  
            }
            Boolean regTypeBusiness = (requestMap.registrationType != null &&  requestMap.registrationType == 'Business')? true : false;
            List<Account> accList = [SELECT Id FROM account WHERE Name = 'MyServiceNSW Registration' Limit 1];
            if(accList.Size() > 0 ){
                nswAccountId = accList[0].id;
            }
            Id accountOwnerId = [Select MasterLabel, Owner_Id__c from LSC_DefaultOwner__mdt where DeveloperName = 'Account' Limit 1].Owner_Id__c;
            //create Account
            Account acc = new Account();
            List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'LSC Customer Community Login User' LIMIT 1];
            if(profiles != null && profiles.size() > 0) {
                profileId = profiles[0].Id;
            }
            else {
                throw new DmlException('Profile for this user was not found');
            }
            acc.RecordTypeId = regTypeBusiness ? Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Business').getRecordTypeId() 
                                               : Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Individual').getRecordTypeId(); 
            acc.Name = regTypeBusiness? requestMap.abnDetails.entityName : (requestMap.contactPageDetails.givenName+' '+requestMap.contactPageDetails.surName) ;
            acc.Phone = regTypeBusiness?  requestMap.businessPageDetails.phone : requestMap.contactPageDetails.phone;
            acc.LSC_Email__c = regTypeBusiness? requestMap.businessPageDetails.email : requestMap.contactPageDetails.email;
            acc.LSC_AccountStatus__c = 'Active';
            acc.LSC_Schemes__c = 'BCI';
            acc.ownerId = accountOwnerId;
            acc.ShippingStreet = requestMap.postalAddress.street;
            acc.ShippingCity = requestMap.postalAddress.city;
            acc.ShippingState = requestMap.postalAddress.state;
            acc.ShippingCountry = requestMap.postalAddress.country;
            acc.ShippingPostalCode = requestMap.postalAddress.postcode;
            acc.ShippingLatitude = requestMap.postalAddress.latitude;
            acc.ShippingLongitude = requestMap.postalAddress.longitude;
            acc.LSC_ShippingAddressId__c = requestMap.postalAddress.addressId;
            if(regTypeBusiness){
            	acc.LSC_ABN__c = requestMap.abnDetails.australianBusinessNumber;
            	acc.LSC_ACN__c = requestMap.abnDetails.australianBusinessNumber.substring(2, 11);
                acc.LSC_EntityStatus__c = requestMap.abnDetails.australianBusinessNumberStatus;
                acc.LSC_EntityTypeCode__c = requestMap.abnDetails.entityTypeCode;
                acc.LSC_EntityTypeName__c = requestMap.abnDetails.entityTypeName;
                acc.LSC_CharityTypeName__c = requestMap.abnDetails.charityTypeName;
                if(requestMap.abnDetails.effectiveFrom != null){
                	acc.LSC_ABNEffectiveFrom__c = date.valueOf(requestMap.abnDetails.effectiveFrom);
                }
                if(requestMap.abnDetails.effectiveTo != null){
                	acc.LSC_ABNEffectiveTo__c = date.valueOf(requestMap.abnDetails.effectiveTo);
                }
                acc.BillingStreet =  requestMap.streetAddress.street;
                acc.BillingCity = requestMap.streetAddress.city;
                acc.BillingState = requestMap.streetAddress.state;
                acc.BillingCountry = requestMap.streetAddress.country;
                acc.BillingPostalCode = requestMap.streetAddress.postcode;
                acc.BillingLatitude = requestMap.streetAddress.latitude;
                acc.BillingLongitude = requestMap.streetAddress.longitude; 
                acc.LSC_BillingAddressId__c = requestMap.streetAddress.addressId;
                acc.Type = requestMap.abnDetails.charityTypeName == null? 'Commercial' : 'Not For Profit';
            }else{
                acc.LSC_IndividualFirstName__c = requestMap.contactPageDetails.givenName;
                acc.LSC_IndividualLastName__c = requestMap.contactPageDetails.surName;
                acc.BillingStreet = requestMap.postalAddress.street;
                acc.BillingCity = requestMap.postalAddress.city;
                acc.BillingState = requestMap.postalAddress.state;
                acc.BillingCountry = requestMap.postalAddress.country;
                acc.BillingPostalCode = requestMap.postalAddress.postcode;
                acc.BillingLatitude = requestMap.postalAddress.latitude;
                acc.BillingLongitude = requestMap.postalAddress.longitude;
            }
            Datetime now = Datetime.now();
            acc.LSC_DeclarationAcceptedDateTime__c = now;
            acc.LSC_IsDeclarationAccepted__c = requestMap.declaration;
            
            insert acc;
            system.debug('Account Id is ...'+acc);
            
            //create or update Contact
            Contact con = new Contact();
            con.FirstName = requestMap.contactPageDetails.givenName;
            con.LastName = requestMap.contactPageDetails.surName;
            con.Phone = requestMap.contactPageDetails.phone;
            if(!regTypeBusiness){
                con.MailingStreet = requestMap.postalAddress.street;
                con.MailingCity = requestMap.postalAddress.city;
                con.MailingState = requestMap.postalAddress.state;
                con.MailingCountry = requestMap.postalAddress.country;
                con.MailingPostalCode = requestMap.postalAddress.postcode;
                con.MailingLatitude = requestMap.postalAddress.latitude;
                con.MailingLongitude = requestMap.postalAddress.longitude;
                con.LSC_MailingAddressId__c = requestMap.postalAddress.addressId;
            }
            if(requestMap.cost != null){
                con.LSC_StartUrl__c = '/bci/s/new-levy?cost=' + String.valueOf(requestMap.cost);
            }
            con.LSC_IsDeclarationAccepted__c = requestMap.declaration;
            con.LSC_DeclarationAcceptedDateTime__c = now;
            con.AccountId = acc.Id;
            con.LSC_InCompleteRegistration__c = false;
            //If User is a guest User insert new contact else update existing contact
            if(Auth.CommunitiesUtil.isGuestUser()){
                con.Email = requestMap.contactPageDetails.email;
            	insert con;
            } else{
				Id contId = [Select contactId from User where Id =: UserInfo.getUserId()].contactId;
				con.Id = contId;
                update con;
            }
            //Delete ACR associated with MyServiceNSW Registration account
            if(!Auth.CommunitiesUtil.isGuestUser()){
                AccountContactRelation oldAcrRec = [Select Id from AccountContactRelation where AccountId =: nswAccountId and ContactId =: con.Id and IsActive = true Limit 1];
                if(oldAcrRec != null){
                    delete oldAcrRec;
                }
        	}
            
            //Create ACR record
            AccountContactRelation acrRec = [Select Id, LSC_IsLevyPayer__c, Roles, LSC_Schemes__c, StartDate from AccountContactRelation where AccountId =: acc.Id and ContactId =: con.Id and IsDirect = true and IsActive = true];
            acrRec.StartDate = date.today();
            if(regTypeBusiness){
            	acrRec.Roles= 'Admin';
            }
            acrRec.LSC_IsLevyPayer__c = true;
            acrRec.LSC_Schemes__c = 'BCI';
            update acrRec;

            //create a random community nickname
            String hashString = requestMap.contactPageDetails.surName + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
			Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
			String hexDigest = EncodingUtil.convertToHex(hash);
            //create or update User
			Id userId;
            User newUser = new User(LSC_StartURL__c = requestMap.startURLParameter, FirstName = requestMap.contactPageDetails.givenName,
                                   LastName = requestMap.contactPageDetails.surName, ContactId = con.Id);
            //If User is a guest User insert new user else update existing user
            if(Auth.CommunitiesUtil.isGuestUser()){
                newUser.Email = requestMap.contactPageDetails.email;
                newUser.UserName = LSC_Utility.constructUsername(requestMap.contactPageDetails.email);
                newUser.communityNickname = hexDigest;
                newUser.ProfileId = profileId;
                newUser.LSC_Registration_Type__c  = 'SelfRegister';
                newUser.PasswordSet__c  = true;
            	userId = Site.createExternalUser(newUser, acc.Id, requestMap.password, false);
            } else{
                newUser.Id = userId = UserInfo.getUserId();
                // causing Mixed DML issue
                // newUser.Username = LSC_Utility.constructUsername(UserInfo.getUserEmail());
                update newUser;
            }
            //Trigger verification email
            if(Auth.CommunitiesUtil.isGuestUser()){
                con.LSC_EmailConfirmationExpiry__c = Datetime.now().addHours(1);
                con.LSC_EmailConfirmationLink__c = LSC_EmailConfirmationUtility.generateEmailId();
                update con;
            }
            //return user Id on success
			return new Map<string, Object>{'result' => true, 'userId' => userId};
        }catch(exception e){
            LSC_LogHandler.logException('LSC_RegistrationUtility', 'createAccountContact', e.getMessage(),e.getLineNumber(),e.getStackTraceString());
            Database.rollback(sp);
            return new Map<string, Object>{'result' => false, 'errorMess'=> e.getMessage()};        
        }
    }     
    
    public class RegistrationWrapper{
        @AuraEnabled public ContactDetailsWrapper contactPageDetails;
        @AuraEnabled public BusinessDetailsWrapper businessPageDetails;
        @AuraEnabled public AddressWrapper postalAddress;
        @AuraEnabled public AddressWrapper streetAddress;
        @AuraEnabled public AbnWrapper abnDetails;
        @AuraEnabled public String registrationType;
        @AuraEnabled public String startURLParameter;
        @AuraEnabled public Boolean declaration;
        @AuraEnabled public String password;
        @AuraEnabled public Boolean emailValidated;
        @AuraEnabled public String cost;
    }
    
    public class ContactDetailsWrapper{
        @AuraEnabled public String givenName;
        @AuraEnabled public String surName;
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
    }
    
    public class BusinessDetailsWrapper{
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
    }    
    
    public class AddressWrapper {
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;        
        @AuraEnabled public String country;
        @AuraEnabled public String postcode;
        @AuraEnabled public String fullAddress;
        @AuraEnabled public Double latitude;
        @AuraEnabled public Double longitude;
        @AuraEnabled public String addressId;
        @AuraEnabled public Boolean autoAddress;
        @AuraEnabled public String  suburb;
    }
    
    public class AbnWrapper {
        @AuraEnabled public String australianBusinessNumber;
        @AuraEnabled public String australianBusinessNumberStatus;
        @AuraEnabled public String australianCompanyName;
        @AuraEnabled public String effectiveFrom;
        @AuraEnabled public String effectiveTo;
        @AuraEnabled public List<String> businessName;
        @AuraEnabled public String entityName;
        @AuraEnabled public String entityTypeCode;
        @AuraEnabled public String entityTypeName;
        @AuraEnabled public String charityTypeName;
        @AuraEnabled public String acncRegistrationStatus;
    }    
}