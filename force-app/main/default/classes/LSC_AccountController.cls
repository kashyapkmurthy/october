/**
 * @description       : 
 * @author            : Surya Reddy
 * @group             : 
 * @last modified on  : 04-14-2021
 * @last modified by  : Surya Reddy
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   04-14-2021   Surya Reddy   Initial Version
**/
public without sharing class LSC_AccountController {
    
    @AuraEnabled(cacheable=true)
    public static BusinessDetailsWrapper getBusinessDetailsById(Id accountId) {

        BusinessDetailsWrapper businessDetailsWrapper = null;
        try {
            
            String query = 'SELECT id,Name,LSC_ABN__c,LSC_Email__c,Phone,LSC_Mobile__c,billingAddress,LSC_BillingAddressId__c,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry,';
                   query = query + 'ShippingAddress,LSC_ShippingAddressId__c,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,ShippingCountry FROM Account WHERE id = :accountId';
            //query the database
            List<Account> accounts = Database.query(query);
            
            if (accounts != null && accounts.size() == 1) {
                Account account = accounts.get(0);
                businessDetailsWrapper = new BusinessDetailsWrapper(account);
                 //Query Account Contact Releation to check whether logged in user is Admin or not.
                for (AccountContactRelation acr:[SELECT id,Roles FROM AccountContactRelation WHERE contactid in (SELECT ContactId from user WHERE id = :UserInfo.getUserId()) and accountid = :accountId LIMIT 1]){
                    list<String> lstRoles=acr.Roles.split(';');
                    if (lstRoles.contains('Admin')){
                        businessDetailsWrapper.isAdmin = true; //Logged in User is a Admin
                    }
                }
            }
        } catch (Exception ex) {
            LSC_LogHandler.logException('LSC_AccountController', 'getBusinessDetailsById', ex.getMessage(),ex.getLineNumber(),ex.getStackTraceString());
        }
            
        return businessDetailsWrapper;  
    }


@AuraEnabled(cacheable=true)
public static List<BusinessDetailsContactWrapper> getRelatedContactsById(Id accountId) {

    List<BusinessDetailsContactWrapper> lstBusinessDetailsContactWrapper= null;
    Map<Id,User> mapContactIdUser = new Map<Id,User>();
        
    try {
        //Query User to get registered portal users using Account ID
        for (User user: [SELECT Id, IsActive,UserType,ContactId FROM User WHERE contactId in (SELECT ContactId FROM AccountContactRelation WHERE AccountId = :accountID) and UserType IN ('CSPLitePortal','PowerCustomerSuccess') ]){
            if(!mapContactIdUser.containsKey(user.contactID)){
                mapContactIdUser.put(user.contactID,User);
        	}
        }

        //query ACR to get related contacts using Account ID
        String acrQuery = 'SELECT id,contact.id,contact.FirstName, contact.LastName, contact.Phone, contact.MobilePhone, contact.Email, contact.AccountId, Roles,AccountId,account.LSC_ABN__c  FROM AccountContactRelation WHERE account.id = :accountId and isActive = true  ORDER BY createddate ASC';
        lstBusinessDetailsContactWrapper= new List<BusinessDetailsContactWrapper>();
        for (AccountContactRelation acr:Database.query(acrQuery)){
                lstBusinessDetailsContactWrapper.add(new BusinessDetailsContactWrapper(acr,mapContactIdUser));
        }

    } catch (Exception ex) {
        LSC_LogHandler.logException('LSC_AccountController', 'getRelatedContactsById', ex.getMessage(),ex.getLineNumber(),ex.getStackTraceString());
    }
        
    return lstBusinessDetailsContactWrapper;  
}

@AuraEnabled
public static Boolean addBusiness(String abnDetails, String businessDetails, String postalAddressDetails, String streetAddressDetails)
{
    if (LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId())) {
        throw LSC_Utility.createAuraException(System.label.BCI_Session_Expiry_Error);
    }
    try{
        LSC_RegistrationUtility.AbnWrapper abnDetailsWrapper = (LSC_RegistrationUtility.AbnWrapper)JSON.deserialize(abnDetails, LSC_RegistrationUtility.AbnWrapper.class);
        LSC_RegistrationUtility.BusinessDetailsWrapper businessDetailsWrapper = (LSC_RegistrationUtility.BusinessDetailsWrapper)JSON.deserialize(businessDetails, LSC_RegistrationUtility.BusinessDetailsWrapper.class);
        LSC_RegistrationUtility.AddressWrapper postalAddressDetailsWrapper = (LSC_RegistrationUtility.AddressWrapper)JSON.deserialize(postalAddressDetails, LSC_RegistrationUtility.AddressWrapper.class);
        LSC_RegistrationUtility.AddressWrapper streetAddressDetailsWrapper = (LSC_RegistrationUtility.AddressWrapper)JSON.deserialize(streetAddressDetails, LSC_RegistrationUtility.AddressWrapper.class);
        Id accountOwnerId = [Select MasterLabel, Owner_Id__c from LSC_DefaultOwner__mdt where DeveloperName = 'Account' Limit 1].Owner_Id__c;
        Account newAccount = new Account();
        newAccount.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('LSC_Business').getRecordTypeId();
        newAccount.Name = abnDetailsWrapper.entityName;
        newAccount.LSC_ABN__c = abnDetailsWrapper.australianBusinessNumber;
        newAccount.LSC_ACN__c = abnDetailsWrapper.australianBusinessNumber.substring(2, 11);
        newAccount.LSC_EntityStatus__c = abnDetailsWrapper.australianBusinessNumberStatus;
        newAccount.LSC_EntityTypeCode__c = abnDetailsWrapper.entityTypeCode;
        newAccount.LSC_EntityTypeName__c = abnDetailsWrapper.entityTypeName;
        newAccount.LSC_CharityTypeName__c = abnDetailsWrapper.charityTypeName;
        if(abnDetailsWrapper.effectiveFrom != null){
        	newAccount.LSC_ABNEffectiveFrom__c = date.valueOf(abnDetailsWrapper.effectiveFrom);
        }
        if(abnDetailsWrapper.effectiveTo != null){
        	newAccount.LSC_ABNEffectiveTo__c = date.valueOf(abnDetailsWrapper.effectiveTo);
        }
        newAccount.Phone = businessDetailsWrapper.phone;
        newAccount.LSC_Email__c = businessDetailsWrapper.email;
        newAccount.LSC_AccountStatus__c = 'Active';
        newAccount.ownerId = accountOwnerId;
        newAccount.LSC_Schemes__c = 'BCI';
        newAccount.ShippingStreet = postalAddressDetailsWrapper.street;
        newAccount.ShippingCity = postalAddressDetailsWrapper.city;
        newAccount.ShippingState = postalAddressDetailsWrapper.state;
        newAccount.ShippingCountry = postalAddressDetailsWrapper.country;
        newAccount.ShippingPostalCode = postalAddressDetailsWrapper.postcode;
        newAccount.LSC_ShippingAddressId__c = postalAddressDetailsWrapper.addressId;
        newAccount.BillingStreet =  streetAddressDetailsWrapper.street;
        newAccount.BillingCity = streetAddressDetailsWrapper.city;
        newAccount.BillingState = streetAddressDetailsWrapper.state;
        newAccount.BillingCountry = streetAddressDetailsWrapper.country;
        newAccount.BillingPostalCode = streetAddressDetailsWrapper.postcode;
        newAccount.LSC_BillingAddressId__c = streetAddressDetailsWrapper.addressId;
        newAccount.Type = abnDetailsWrapper.charityTypeName == null? 'Commercial' : 'Not For Profit';
        insert newAccount;
        //Link the current user contact to the created account
        	Id contactId = [Select contactId from User where Id =: UserInfo.getUserId() Limit 1].contactId;
            insert new AccountContactRelation(AccountId = newAccount.Id, ContactId = contactId, Roles = 'Admin',
                                             StartDate = date.today(), LSC_IsLevyPayer__c = true, LSC_Schemes__c = 'BCI');
	        Contact c = new Contact(Id = contactId, LSC_SelectedAccountId__c = newAccount.Id);
	        update c;
            return true;
        }catch(DmlException ex) { 
            LSC_LogHandler.logException('LSC_AccountController', 'addBusiness', ex.getMessage(),ex.getLineNumber(),ex.getStackTraceString());
        }catch(exception ex){
            LSC_LogHandler.logException('LSC_AccountController', 'addBusiness', ex.getMessage(),ex.getLineNumber(),ex.getStackTraceString());
        }

        return false;
    }

@AuraEnabled
public static string processBusinessDetails(String strBusinessDetails)
{
    if (LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId())) {
        throw LSC_Utility.createAuraException(System.label.BCI_Session_Expiry_Error);
    }
    try
    {   
        BusinessDetailsWrapper businessDetailsWrapper = (BusinessDetailsWrapper) JSON.deserialize(strBusinessDetails, BusinessDetailsWrapper.class);
        Account accountRec = new Account();
        accountRec.Id = businessDetailsWrapper.id;
        accountRec.LSC_Email__c = businessDetailsWrapper.email;
        accountRec.Phone = businessDetailsWrapper.phone;
        accountRec.BillingStreet = businessDetailsWrapper.postalAddress.street;
        accountRec.BillingCity = businessDetailsWrapper.postalAddress.city;
        accountRec.BillingState = businessDetailsWrapper.postalAddress.state;
        accountRec.BillingPostalCode = businessDetailsWrapper.postalAddress.postcode;
        accountRec.LSC_BillingAddressId__c = businessDetailsWrapper.postalAddress.addressId;
        accountRec.ShippingStreet = businessDetailsWrapper.streetAddress.street;
        accountRec.ShippingCity = businessDetailsWrapper.streetAddress.city;
        accountRec.ShippingState = businessDetailsWrapper.streetAddress.state;
        accountRec.ShippingPostalCode = businessDetailsWrapper.streetAddress.postcode;
        accountRec.LSC_ShippingAddressId__c = businessDetailsWrapper.streetAddress.addressId;

        update accountRec;

        return 'Business details updated Successfully';
    
    }Catch(Exception ex){
            LSC_LogHandler.logException('LSC_AccountController', 'processBusinessDetails', ex.getMessage(),ex.getLineNumber(),ex.getStackTraceString());
            throw LSC_PaymentController.createAuraException('Error updating Business Details');
    }         
}

    @InvocableMethod(label = 'Assign Permission Set' description = 'Assigns the permissionset for the user linked to the given contacts')
    public static void assignPermissionSet(List<Id> lstContactId){
            if(!System.isFuture()) {
                assignPermissionSets(new Set<Id>(lstContactId));
            }
    }

    @future
    public static void assignPermissionSets(Set<Id> setContactId){
            try{
                List<PermissionSetAssignment> lstPermissionSetAssigned = new List<PermissionSetAssignment>();
                //Get the Permission Set ID    
                Id permissionSetId = [Select Id from PermissionSet where Name='LSC_BCILevyUser'].Id;
            
                for(User userRec : [SELECT Id, IsActive, IsPortalEnabled FROM User  WHERE contactId in :setContactId and IsActive = true]){
                        PermissionSetAssignment pmSetAssign = new PermissionSetAssignment(AssigneeId=userRec.Id, PermissionSetId= permissionSetId);
                        lstPermissionSetAssigned.add(pmSetAssign);
                }
                if (lstPermissionSetAssigned != null && lstPermissionSetAssigned.size() > 0){
                    insert lstPermissionSetAssigned;
                }
            }
            catch(DmlException ex) {
                LSC_LogHandler.logException('LSC_AccountController', 'assignPermissionSets', ex.getMessage(),ex.getLineNumber(),ex.getStackTraceString());
            }
    }

    public class BusinessDetailsWrapper {
        
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String abn {get;set;}
        @AuraEnabled public String entityName {get;set;}
        @AuraEnabled public String phone {get;set;} 
        @AuraEnabled public String mobile {get;set;} 
        @AuraEnabled public String email {get;set;}
        @AuraEnabled public Boolean isAdmin {get;set;}
        @AuraEnabled public LSC_RegistrationUtility.AddressWrapper streetAddress {get;set;}
        @AuraEnabled public LSC_RegistrationUtility.AddressWrapper postalAddress {get;set;}       
        
        public BusinessDetailsWrapper(Account account) {
            this.id          = account.id;
            this.abn         = account.LSC_ABN__c;
            this.entityName  = account.Name;
            this.phone       = account.Phone;
            this.email       = account.LSC_Email__c;
            this.isAdmin     = false;
            this.mobile      = account.LSC_Mobile__c;
            this.postalAddress = new LSC_RegistrationUtility.AddressWrapper ();
            this.postalAddress.autoAddress = String.isNotBlank(account.LSC_BillingAddressId__c) ? true : false;
            this.postalAddress.addressId = account.LSC_BillingAddressId__c;
            this.postalAddress.street = account.BillingStreet;
            this.postalAddress.city = account.BillingCity;
            this.postalAddress.suburb = account.BillingCity;
            this.postalAddress.state = account.BillingState;
            this.postalAddress.postcode = account.BillingPostalCode;
            this.postalAddress.fullAddress = account.BillingStreet+', '+account.BillingCity+', '+account.BillingState+', '+account.BillingPostalCode;
            this.postalAddress.country = account.BillingCountry;    
            this.streetAddress = new LSC_RegistrationUtility.AddressWrapper ();
            this.streetAddress.autoAddress = String.isNotBlank(account.LSC_ShippingAddressId__c) ? true : false;
            this.streetAddress.addressId = account.LSC_ShippingAddressId__c;
            this.streetAddress.street = account.ShippingStreet;
            this.streetAddress.city = account.ShippingCity;
            this.streetAddress.suburb = account.ShippingCity;
            this.streetAddress.state = account.ShippingState;
            this.streetAddress.postcode = account.ShippingPostalCode;
            this.streetAddress.fullAddress = account.ShippingStreet+', '+account.ShippingCity+', '+account.ShippingState+', '+account.ShippingPostalCode;
            this.streetAddress.country = account.ShippingCountry;    
        }
    }

    public class BusinessDetailsContactWrapper {
        @AuraEnabled public String key {get;set;}
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public Contact recContact {get;set;}
        @AuraEnabled public String roles {get;set;}
        @AuraEnabled public Boolean isUser {get;set;}
        @AuraEnabled public Boolean isDirector {get;set;}
        @AuraEnabled public Boolean isAdmin {get;set;}
        @AuraEnabled public String acrUserId {get;set;}
        @AuraEnabled public Boolean isLoggedInUser {get;set;}
        @AuraEnabled public String abn {get;set;}
        @AuraEnabled public Boolean hasUser {get;set;}
        @AuraEnabled public Boolean activateUser {get;set;}
        @AuraEnabled public Boolean inviteUser {get;set;}


        public BusinessDetailsContactWrapper(AccountContactRelation acr,Map<Id,User> mapContactIdUser) {
            this.key = String.valueof(Math.abs(Crypto.getRandomLong())).substring(0,4);
            this.id = acr.id;
            this.recContact = acr.contact;
            this.roles = acr.roles;
            this.isUser = mapContactIdUser.containsKey(acr.contact.id) ? mapContactIdUser.get(acr.contact.id).isActive : false;
            this.isDirector = (acr.roles != null && acr.roles.split(';').contains('Director')) ? true : false;
            this.isAdmin =  (acr.roles != null && acr.roles.split(';').contains('Admin')) ? true : false;
            this.acrUserId = mapContactIdUser.containsKey(acr.contact.id) ? mapContactIdUser.get(acr.contact.id).Id : null;
            this.isLoggedInUser = UserInfo.getUserId().equals(this.acrUserId) ? true : false;
            this.abn = acr.account.LSC_ABN__c;
            this.hasUser = mapContactIdUser.containsKey(acr.contact.id)  ? true : false;
            this.activateUser = false;
        }
    }


}