public with sharing class LSC_UserController {

    @AuraEnabled(cacheable=true)
    public static UserDataWrapper getUserProfileData() {

        UserDataWrapper userDataWrapper = null;
        try {
            
                //Query User Record.
                for (User userRec:[SELECT Id,Email, Phone, MobilePhone, FirstName, LastName, Name, ContactId, Contact.Phone, Contact.MailingStreet, Contact.MailingCity, Contact.MailingState, Contact.MailingCountry, Contact.MailingPostalCode, Contact.LSC_MailingAddressId__c, AccountId, Account.RecordType.Name from User WHERE Id =: UserInfo.getUserId() Limit 1]){
                    userDataWrapper = new UserDataWrapper(userRec);
                }

                if(userDataWrapper!= null){
                    // Verify whether the logged in User is linked to MyserviceNSW or not
                    for (ThirdPartyAccountLink  tpAccLink:[SELECT Id,Provider,SsoProviderName , SsoProvider.DeveloperName from ThirdPartyAccountLink where userId =: UserInfo.getUserId() and SsoProviderName= 'MyServiceNSW' Limit 1]){
                        userDataWrapper.isServiceNSWLinked = true;
                    }
                }

        } catch (Exception ex) {
            //log the exception to Applicaiton Log.
            System.debug('Exception**'+ex);
        }
            
        return userDataWrapper;  
    }

    /**
    * @description Aura method to make a callout service nsw logout api to end service nsw session 
    * @author Emily Jiang | 07/09/2021 
    **/
    @AuraEnabled
    public static void logoutSNSWUser() {
        List<User> users = [SELECT Id, LSC_Registration_Type__c FROM User WHERE Id =: UserInfo.getUserId()];
        if (!users.isEmpty() && users[0].LSC_Registration_Type__c == 'SNSW' && !LSC_Utility.checkIfLoginPortalViaServiceCloud()) {
            LSC_SNSWCallouts.ResultWrapper result = LSC_SNSWCallouts.logoutSNSWUser();
            if (!result.success) {
                throw LSC_Utility.createAuraException(result.errorMessage);
            }
        }
    }


@AuraEnabled
public static string updateUserProfile(String strUserData)
{
    try
    {   
        UserDataWrapper userData = (UserDataWrapper) JSON.deserialize(strUserData, UserDataWrapper.class);
        User userRec = new User();
        userRec.Id = userData.id;
        userRec.Phone = userData.phone;
        userRec.FirstName = userData.firstName;
        userRec.LastName  = userData.lastName;
            
        Contact contactRec = new Contact();
        contactRec.id = userData.contactId;
        contactRec.phone = userData.phone;
        contactRec.FirstName = userData.firstName;
        contactRec.LastName = userData.lastName;

        if (userData.isIndividual){
            contactRec.MailingStreet = userData.mailingAddress.street;
            contactRec.MailingCity = userData.mailingAddress.city;
            contactRec.MailingState = userData.mailingAddress.state;
            contactRec.MailingPostalCode = userData.mailingAddress.postcode;
            contactRec.LSC_MailingAddressId__c = userData.mailingAddress.addressId;
            
            Account accountRec = new Account();
            accountRec.Id = userData.accountId;
            accountRec.ShippingStreet = userData.mailingAddress.street;
            accountRec.ShippingCity = userData.mailingAddress.city;
            accountRec.ShippingState = userData.mailingAddress.state;
            accountRec.ShippingPostalCode = userData.mailingAddress.postcode;
            accountRec.LSC_ShippingAddressId__c = userData.mailingAddress.addressId;
            accountRec.BillingStreet = userData.mailingAddress.street;
            accountRec.BillingCity = userData.mailingAddress.city;
            accountRec.BillingState = userData.mailingAddress.state;
            accountRec.BillingPostalCode = userData.mailingAddress.postcode;
            accountRec.LSC_BillingAddressId__c = userData.mailingAddress.addressId;
            accountRec.phone = userData.phone;
            accountRec.LSC_IndividualFirstName__c = userData.firstName;
            accountRec.LSC_IndividualLastName__c = userData.lastName;
            // Update User and Contact and Account Records.
            Database.SaveResult[] results = Database.update(new SObject[] {userRec, accountRec, contactRec });
        }else{
            // Update User and Contact Records.
            Database.SaveResult[] results = Database.update(new SObject[] {userRec, contactRec });
            return 'User details updated Successfully';
        }
    
    }Catch(Exception ex){
            System.debug('Exception while updating user data:::'+ ex);
    }         
        return null;
}


    public class UserDataWrapper {
        
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String email {get;set;}
        @AuraEnabled public String phone {get;set;} 
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String firstName {get;set;}
        @AuraEnabled public String lastName {get;set;}
        @AuraEnabled public String contactId {get;set;}
        @AuraEnabled public LSC_RegistrationUtility.AddressWrapper mailingAddress {get;set;}
        @AuraEnabled public Boolean isServiceNSWLinked {get;set;}
        @AuraEnabled public String accountId {get;set;}
        @AuraEnabled public Boolean isIndividual {get;set;}

        public UserDataWrapper(User user) {
            this.id          = user.id;
            this.email       = user.Email;
            this.firstName   = user.FirstName;
            this.lastName    = user.LastName;
            this.phone       = String.isNotBlank(user.Phone) ? user.Phone : user.Contact.Phone;
            this.contactId   = user.ContactId;
            this.mailingAddress = new LSC_RegistrationUtility.AddressWrapper ();
            this.mailingAddress.autoAddress = String.isNotBlank(user.Contact.LSC_MailingAddressId__c) ? true : false;
            this.mailingAddress.addressId   = user.Contact.LSC_MailingAddressId__c;
            this.mailingAddress.street      = String.isNotBlank(user.Contact.MailingStreet) ? user.Contact.MailingStreet: '';
            this.mailingAddress.city        = String.isNotBlank(user.Contact.MailingCity) ? user.Contact.MailingCity: '';
            this.mailingAddress.suburb      = String.isNotBlank(user.Contact.MailingCity) ? user.Contact.MailingCity: '';
            this.mailingAddress.state       = String.isNotBlank(user.Contact.MailingState) ? user.Contact.MailingState: '';
            this.mailingAddress.postcode    = String.isNotBlank(user.Contact.MailingPostalCode) ? user.Contact.MailingPostalCode: '';
            this.mailingAddress.fullAddress = this.mailingAddress.street+', '+ this.mailingAddress.city+', '+ this.mailingAddress.state+', '+ this.mailingAddress.postcode;
            this.mailingAddress.fullAddress = String.isNotBlank(this.mailingAddress.fullAddress.replaceAll(',', '')) ? this.mailingAddress.fullAddress : '';
            this.mailingAddress.country     = user.Contact.MailingCountry;  
            this.isServiceNSWLinked         = false;  
            this.accountId                  = user.AccountId;
            this.isIndividual               = (user.Account.RecordType.Name == LSC_GlobalConstants.LSC_ACCOUNT_RECORDTYPENAME_INDIVIDUAL) ? true : false;
        }
    }



}