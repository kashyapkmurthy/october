public without sharing class LSC_LoginController {
    @AuraEnabled
    public static ResultWrapper communityLogin(String username, String password, String startUrl) {
        // front end pass email to back end, need to add suffix
        if (LSC_Utility.isSandbox() && !Test.isRunningTest() && !LSC_Utility.isEmailAddressInWhiteList(username)) {
            return new ResultWrapper(null, System.Label.Email_Address_Not_Allowed_In_Sandbox);  
        }

        String url = '';
        if(username != null) {
            username = username.toLowerCase();
            username = LSC_Utility.constructUsername(username);
        }
        List<User> users = [SELECT Id, Contact.LSC_IsEmailConfirmed__c, Contact.LSC_StartUrl__c, ContactId FROM User WHERE Username = :username];
        if(users != null && users.size() > 0 && users[0].ContactId != null) {
            if(!users[0].Contact.LSC_IsEmailConfirmed__c) {
                return new ResultWrapper(null, 'Email has not been verified');
            }
            else {
                if(users[0].ContactId != null && users[0].Contact.LSC_StartUrl__c != null) {
                    url = users[0].Contact.LSC_StartUrl__c;
                }
                else {
                    url = startUrl;
                }
            }
        }
        else {
            return new ResultWrapper(null, 'User with the provided details was not found');
        }
        ApexPages.PageReference pageRef = Site.login(username, password, url);
        if(pageRef == null) {
            return new ResultWrapper(null, 'User with the provided details was not found');
        }
        else {
            if(users[0].Contact.LSC_StartUrl__c != null) {
                Contact c = new Contact(Id = users[0].ContactId);
                c.LSC_StartUrl__c = null;
                update c;
            }
            return new ResultWrapper(pageRef.getUrl(), null);   
        }
    }

    @AuraEnabled
    public static ResultWrapper emailVerification(String username) {
        // front end pass email to back end, need to add suffix
        if(username != null) {
            username = username.toLowerCase();
            username = LSC_Utility.constructUsername(username);
        }
        List<User> users = [SELECT Id, ContactId FROM User WHERE Username = :username];
        if(users != null && users.size() > 0 && users[0].ContactId != null) {
            //Generate new code
            Contact c = new Contact();
            c.Id = users[0].ContactId;
            c.LSC_EmailConfirmationExpiry__c = Datetime.now().addHours(1);
            c.LSC_EmailConfirmationLink__c = LSC_EmailConfirmationUtility.generateEmailId();
            update c;
            return new ResultWrapper('Success', null);
        }
        else {
            return new ResultWrapper(null, 'User with the provided details was not found');
        }
    }    

    @AuraEnabled
    public static VerificationWrapper checkVerification(String code) {
        if(code == null) {
            return new VerificationWrapper(null, false, false, true);
        }
        List<Contact> contacts = [SELECT Id, Email, LSC_EmailConfirmationLink__c, LSC_EmailConfirmationExpiry__c, LSC_IsEmailConfirmed__c FROM Contact WHERE LSC_EmailConfirmationLink__c = :code];
        if(contacts != null && contacts.size() == 1) {
            if(contacts[0].LSC_IsEmailConfirmed__c) {
                return new VerificationWrapper(contacts[0].Email, true, false, false);
            }
            else if(contacts[0].LSC_EmailConfirmationExpiry__c != null && contacts[0].LSC_EmailConfirmationExpiry__c > Datetime.now()) {
                contacts[0].LSC_IsEmailConfirmed__c = true;
                update contacts[0];
                return new VerificationWrapper(contacts[0].Email, false, false, false);
            }
            else {
                return new VerificationWrapper(contacts[0].Email, false, true, false);
            }
        }
        else {
            return new VerificationWrapper(null, false, false, true);
        }
    }
    
    @AuraEnabled
    public static Boolean checkIfGuestUser(){
        return LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId());
    }

    public class ResultWrapper {
        @AuraEnabled
        public String url {get; set;}      
        
        @AuraEnabled
        public String error {get; set;}   
        
        public ResultWrapper(String url, String error) {
            this.url = url;
            this.error = error;
        }
    }        

    public class VerificationWrapper {
        @AuraEnabled
        public String email {get; set;}      

        @AuraEnabled
        public Boolean isVerified {get; set;}           
        
        @AuraEnabled
        public Boolean isExpired {get; set;}   

        @AuraEnabled
        public Boolean isError {get; set;}          
        
        public VerificationWrapper(String email, Boolean isVerified, Boolean isExpired, Boolean isError) {
            this.email = email;
            this.isExpired = isExpired;
            this.isVerified = isVerified;
            this.isError = isError;
        }
    }        
}