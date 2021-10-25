/**
 * An apex page controller that exposes the change password functionality
 */
public with sharing class ChangePasswordController {
    public String newPassword {get; set {newPassword = value == null ? value : value.trim();}}
    public String oldpassword {get; set;}
    public String verifyNewPassword {get; set {verifyNewPassword = value == null ? value : value.trim();}}        
    public Boolean renderDeclaration { get; set; }
    public User userRec {get;set;}

    public PageReference changePassword() {
        PageReference pageRef;
        pageRef =  Site.changePassword(newPassword, verifyNewPassword, oldpassword);
        if(!this.userRec.PasswordSet__c){
            this.userRec.PasswordSet__c = true;
            update this.userRec;
        }
        return pageRef;  
    }     
    
    public ChangePasswordController() {
        this.userRec = [Select Id, PasswordSet__c from User where Id =: UserInfo.getUserId() Limit 1];
        if(this.userRec.PasswordSet__c == false){
            this.renderDeclaration = true;
        }else{
            this.renderDeclaration = false;
        }
    }
}