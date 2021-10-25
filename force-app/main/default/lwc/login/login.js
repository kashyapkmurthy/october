import { LightningElement, wire, track, api } from 'lwc';
import communityLogin from '@salesforce/apex/LSC_LoginController.communityLogin';
import emailVerification from '@salesforce/apex/LSC_LoginController.emailVerification';
import checkVerification from '@salesforce/apex/LSC_LoginController.checkVerification';
import checkIfGuestUser from '@salesforce/apex/LSC_LoginController.checkIfGuestUser';
import BCICommunityLink from '@salesforce/label/c.BCI_Community_Link';
import Email_Address_Not_Allowed_In_Sandbox from '@salesforce/label/c.Email_Address_Not_Allowed_In_Sandbox';
import { CurrentPageReference } from 'lightning/navigation';

export default class Login extends LightningElement {
    username;
    password;
    startUrl;
    cost;
    verification;
    passwordType = 'password';
    currentPageReference;
    isVerificationError = false;
    isVerificationCompleted = false;
    isVerificationFailed = false;
    isVerificationExpired = false;
    isEmailSent = false;
    isEmailNotAllowedInSandbox = false;
    emailNotAllowedErrorMessage = Email_Address_Not_Allowed_In_Sandbox;


    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            this.setParametersBasedOnUrl();
       }
    }  
    
    setParametersBasedOnUrl() {
        this.startUrl = this.urlStateParameters.startURL || null;
        this.verification = this.urlStateParameters.verification || null;
        if(this.startUrl && this.startUrl.includes('cost=')) {
            this.cost = this.startUrl.split('cost=').pop();
        }
        if(this.verification) {
            checkVerification({code: this.verification})
            .then(result => {
                if(result && result.email) {
                    this.username = result.email;
                    if(result.isVerified) {
                        
                    }
                    else if(result.isExpired) {
                        this.isVerificationExpired = true;
                    }
                    else {
                        this.isVerificationCompleted = true;
                    }
                } 
                else if(result && result.isError) {
                    this.isVerificationFailed = true;               
                }
            })
            .catch(error =>{
                console.log('Error')
            }) 
        }
    }       

    handleChange(event){
        this[event.target.name] = event.target.value;
    } 
    
    handleEmailChange(event){
        const typedValue = event.target.value;
        const trimmedValue = typedValue.trim(); 
        if (typedValue !== trimmedValue) {
            event.target.value = trimmedValue;
        }
        this.username = trimmedValue;
    }  

    handleSNSWLogin() {
        location.href = BCICommunityLink+'/services/auth/sso/myservicensw';
    }

    async checkIfUserIsGuestUser() {
        let isGuestUser = true;
        try {
            isGuestUser = await checkIfGuestUser();
        } catch (error) {
            
        }
        return isGuestUser;
    }
    async handleRegistration() {
        const isGuestUser = await this.checkIfUserIsGuestUser();
        if (!isGuestUser) {
            location.href = '/bci/s';
        } else {
            if(this.cost) {
                location.href = '/bci/s/login/SelfRegister?cost=' + this.cost;
            }
            else {
                location.href = '/bci/s/login/SelfRegister';
            }
        }
        
    }

    togglePassword() {
        if(this.passwordType == 'password') {
            this.passwordType = 'text';
        }
        else {
            this.passwordType = 'password';
        }
    }

    handleEmailVerification() {
        let passwordField = this.template.querySelector("[data-field='username']");
        passwordField.setCustomValidity('');
        passwordField.reportValidity();           
        if (this.username) {
            emailVerification({ username: this.username })
            .then((result) => {
                console.log(result);
                if(result.url) {
                    this.isVerificationError = false;
                    this.isVerificationExpired = false; 
                    this.isEmailSent = true;
                }
                else if(result.error){
                    let passwordField = this.template.querySelector("[data-field='username']");
                    passwordField.setCustomValidity('User with the provided details was not found');
                    passwordField.reportValidity();     
                }
            })
            .catch((error) => {
                let passwordField = this.template.querySelector("[data-field='username']");
                passwordField.setCustomValidity('User with the provided details was not found');
                passwordField.reportValidity();
            });   
        }
        else {
            let passwordField = this.template.querySelector("[data-field='username']");
            passwordField.setCustomValidity('Please provide an email');
            passwordField.reportValidity();   
        }         
    }

    handleLogin() {
        let passwordField = this.template.querySelector("[data-field='password']");
        passwordField.setCustomValidity('');
        passwordField.reportValidity();        
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
        if (allValid) {
            communityLogin({ username: this.username, password: this.password, startUrl: this.startUrl })
            .then((result) => {
                console.log(result);
                if(result.url) {
                    location.href = result.url;
                }
                else if(result.error){
                    if(result.error === 'Email has not been verified') {
                        this.isVerificationError = true;
                    }
                    else if (result.error === Email_Address_Not_Allowed_In_Sandbox) {
                        this.isEmailNotAllowedInSandbox = true;
                    } else {
                        let passwordField = this.template.querySelector("[data-field='password']");
                        passwordField.setCustomValidity('User with the provided details was not found');
                        passwordField.reportValidity();                        
                    }
                }
            })
            .catch((error) => {
                console.log('Error!')
                let passwordField = this.template.querySelector("[data-field='password']");
                passwordField.setCustomValidity('User with the provided details was not found');
                passwordField.reportValidity();
            });
        } 


    }

}