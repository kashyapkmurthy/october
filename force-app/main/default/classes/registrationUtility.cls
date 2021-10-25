public without sharing class registrationUtility {
	@AuraEnabled(cacheable=true)
    public static Boolean checkABNonAccounts(String abn) {
        //Id accBusinessRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Business').getRecordTypeId();
        system.debug('I hit class');
        //system.debug(accBusinessRecordTypeId);
        List<Account> accLst = [Select Id from Account where LSC_ABN__c =: abn];// and RecordTypeId =: accBusinessRecordTypeId];
        system.debug('I hit class-->'+accLst);
        if(!accLst.isEmpty() && accLst.Size()>0)
        	return true;
        else
            return false;
    }
    
	@AuraEnabled(cacheable=true)
    public static Boolean validateUsername(String username) {
        system.debug('I hit method validateUsername');
        List<User> userList = [Select Id from User where Username =: username];
        system.debug('I hit class-->'+userList);
        if(!userList.isEmpty() && userList.Size()>0)
        	return true;
        else
            return false;
    }  
    
	@AuraEnabled
    public static Boolean assignPermissionSet(String userId) {
        Id permissionSetId = [Select Id from PermissionSet where Name='LSC_BCILevyUser'].Id;
        system.debug('I hit method assignPermissionSet');
        try{
            system.debug('I hit assignPermissionSet class-->'+userId);
            if(userId != null){
                //user userRec = [Select Id, accountId from User where Id =: userId];
                //Id userRoleId = [SELECT Id FROM UserRole where PortalAccountId =: userRec.accountId and PortalRole = 'Manager'].Id;
                //userRec.UserRoleId = userRoleId;
                //update userRec;
                //Assign Permission set to the user created
                PermissionSetAssignment pmSetAssign = new PermissionSetAssignment(AssigneeId=userId, PermissionSetId= permissionSetId);
                insert pmSetAssign;
            }
            return true;
        }
        catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            return false;
        }
    }      
    
	@AuraEnabled
    public static Map<string, Object> createAccountContact(String requestDetails) {
        Id profileId;
        Savepoint sp = Database.setSavepoint();
        try{
            system.debug('I am in create acc..'+requestDetails);
            registrationWrapper requestMap = (registrationWrapper)JSON.deserialize(requestDetails, registrationWrapper.class);
            system.debug('I am in create acc..'+requestMap);
            Boolean regTypeBusiness = (requestMap.registrationType != null &&  requestMap.registrationType == 'Business')? true : false;
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
            acc.Name = regTypeBusiness? requestMap.abnDetails.EntityName : (requestMap.contactPageDetails.givenName+' '+requestMap.contactPageDetails.surName) ;
            acc.Phone = regTypeBusiness?  requestMap.businessPageDetails.phone : requestMap.contactPageDetails.phone;
            acc.LSC_Email__c = regTypeBusiness? requestMap.businessPageDetails.email : requestMap.contactPageDetails.email;
            acc.LSC_AccountStatus__c = 'Active';
            acc.LSC_Schemes__c = 'BCI';
            acc.ShippingStreet = requestMap.postalAddress.street;
            acc.ShippingCity = requestMap.postalAddress.city;
            acc.ShippingState = requestMap.postalAddress.state;
            acc.ShippingCountry = requestMap.postalAddress.country;
            acc.ShippingPostalCode = requestMap.postalAddress.postcode;
            acc.ShippingLatitude = requestMap.postalAddress.latitude;
            acc.ShippingLongitude = requestMap.postalAddress.longitude;
            acc.LSC_ShippingAddressId__c = requestMap.postalAddress.addressId;
            if(regTypeBusiness){
            	acc.LSC_ABN__c = requestMap.abnDetails.Abn;
            	acc.LSC_ACN__c = requestMap.abnDetails.Abn.substring(2, 11);
                acc.LSC_EntityStatus__c = requestMap.abnDetails.AbnStatus;
                acc.LSC_EntityTypeCode__c = requestMap.abnDetails.EntityTypeCode;
                acc.LSC_EntityTypeName__c = requestMap.abnDetails.EntityTypeName;
                acc.LSC_CharityTypeName__c = requestMap.abnDetails.CharityTypeName;
                acc.LSC_ABNEffectiveFrom__c = requestMap.abnDetails.EffectiveFrom;
                acc.LSC_ABNEffectiveTo__c = requestMap.abnDetails.EffectiveTo;
                acc.BillingStreet =  requestMap.streetAddress.street;
                acc.BillingCity = requestMap.streetAddress.city;
                acc.BillingState = requestMap.streetAddress.state;
                acc.BillingCountry = requestMap.streetAddress.country;
                acc.BillingPostalCode = requestMap.streetAddress.postcode;
                acc.BillingLatitude = requestMap.streetAddress.latitude;
                acc.BillingLongitude = requestMap.streetAddress.longitude; 
                acc.LSC_BillingAddressId__c = requestMap.streetAddress.addressId;
                acc.Type = requestMap.abnDetails.CharityTypeName == null? 'Commercial' : 'Not For Profit';
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
            Integer offset = UserInfo.getTimezone().getOffset(now);
            acc.LSC_IsDeclarationAccepted__c = requestMap.declaration;
            acc.LSC_DeclarationAcceptedDateTime__c = now.addSeconds(offset/1000);
            insert acc;
            system.debug('Account Id is ...'+acc);
            
            //create Contact
            Contact con = new Contact();
            con.FirstName = requestMap.contactPageDetails.givenName;
            con.LastName = requestMap.contactPageDetails.surName;
            con.Phone = requestMap.contactPageDetails.phone;
            con.Email = requestMap.contactPageDetails.email;
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
            con.LSC_DeclarationAcceptedDateTime__c = now.addSeconds(offset/1000);
            
            con.AccountId = acc.Id;
            insert con;
            system.debug('Contact Id is ...'+con);
            
            //Create ACR record
            AccountContactRelation acrRec = [Select Id, LSC_IsLevyPayer__c, Roles, LSC_Schemes__c, StartDate from AccountContactRelation where AccountId =: acc.Id and ContactId =: con.Id and IsDirect = true and IsActive = true];
            acrRec.StartDate = date.today();
            acrRec.Roles='Manager';
            acrRec.LSC_IsLevyPayer__c = true;
            acrRec.LSC_Schemes__c = 'BCI';
            update acrRec;

            //create a random community nickname
            String hashString = requestMap.contactPageDetails.surName + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
			Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
			String hexDigest = EncodingUtil.convertToHex(hash);
            //create User
            User newUser = new User(Email = requestMap.contactPageDetails.email, LSC_StartURL__c = requestMap.startURLParameter,
                                   UserName = requestMap.contactPageDetails.email, FirstName = requestMap.contactPageDetails.givenName,
                                   LastName = requestMap.contactPageDetails.surName, communityNickname = hexDigest, ProfileId = profileId, ContactId = con.Id);
            Id userId = Site.createExternalUser(newUser, acc.Id, requestMap.password, false);
            //Email verification email
            con.LSC_EmailConfirmationExpiry__c = Datetime.now().addHours(1);
            con.LSC_EmailConfirmationLink__c = LSC_EmailConfirmationUtility.generateEmailId();
            update con;

            system.debug('user Id is ...'+userId);
			return new Map<string, Object>{'result' => true, 'userId' => userId};
        }catch(DmlException e) {
            System.debug('The following dml exception has occurred: ' + e.getMessage());
            Database.rollback(sp);
            return new Map<string, Object>{'result' => false, 'errorMess'=> e.getMessage()};
        }catch(exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
            return new Map<string, Object>{'result' => false, 'errorMess'=> e.getMessage()};        
        }
    }     
    
    public class registrationWrapper{
        @AuraEnabled public contactDetailsWrapper contactPageDetails;
        @AuraEnabled public businessDetailsWrapper businessPageDetails;
        @AuraEnabled public addressWrapper postalAddress;
        @AuraEnabled public addressWrapper streetAddress;
        @AuraEnabled public abnWrapper abnDetails;
        @AuraEnabled public String registrationType;
        @AuraEnabled public String startURLParameter;
        @AuraEnabled public Boolean declaration;
        @AuraEnabled public String password;
        @AuraEnabled public Boolean emailValidated;
        @AuraEnabled public String cost;
    }
    
    public class contactDetailsWrapper{
        @AuraEnabled public String givenName;
        @AuraEnabled public String surName;
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
    }
    
    public class businessDetailsWrapper{
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
        @AuraEnabled public String abnEntityName;
    }    
    
    public class addressWrapper {
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;        
        @AuraEnabled public String country;
        @AuraEnabled public String postcode;
        @AuraEnabled public String fullAddress;
        @AuraEnabled public Double latitude;
        @AuraEnabled public Double longitude;
        @AuraEnabled public String addressId;
    }
    
    public class abnWrapper {
        @AuraEnabled public String Abn;
        @AuraEnabled public String AbnStatus;
        @AuraEnabled public String Acn;
        @AuraEnabled public String EntityName;
        @AuraEnabled public String CharityTypeName;
        @AuraEnabled public String EntityTypeCode;
        @AuraEnabled public String EntityTypeName;
        @AuraEnabled public Date EffectiveFrom;
        @AuraEnabled public Date EffectiveTo;
    }    
}