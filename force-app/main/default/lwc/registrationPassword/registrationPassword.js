import { LightningElement, api } from 'lwc';

export default class RegistrationPassword extends LightningElement {
    @api registrationParameters;  
    contactEmail = "";
    passwordValue = "";
    reEnteredPwd = "";
    passwordType = 'password';
    reEnterdPasswordType = 'password';    
    
    connectedCallback(){
        console.log('In your pwd details connected callback');
        let regParams = JSON.parse(this.registrationParameters);
        console.log('before callback...'+this.passwordValue);
        console.log('before callback...'+this.reEnteredPwd);
        if(regParams){
            this.contactEmail = regParams['contactPageDetails'].email;
            console.log(regParams['password']);
            this.passwordValue =  regParams['password']? regParams['password'] : "" ;
            this.reEnteredPwd = this.passwordValue;
            console.log('in callback...'+this.passwordValue);
            console.log('in callback...'+this.reEnteredPwd);
        }
    }

    handleChange(event){
        let input = event.target;
        this.setInputValidity(input, "");
        if(input.value.length >= this.passwordValue.length && input.value != this.passwordValue){
            this.setInputValidity(input, "Passwords don't match");
        }
    }

    handleBlur(event){
        this.passwordValue = event.target.value;
        console.log('In handle blur..'+this.passwordValue);
    }

    handlePaste(event){
        console.log('In handle paste');
        event.preventDefault();
    }    

    handlePwdChange(event){
        //clear errors
        this.setInputValidity(event.target, ""); 
        let validPwd = /(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[!#$%&'\"()_*+,.\\\/:;<=>?@[\]^`{|}~-]){8,}/g;
        let lowerCase = new RegExp("[a-z]");
        let upperCase = new RegExp("[A-Z]");
        let numberInpt = new RegExp("[0-9]");
        let symbolInpt = /[-._!"`'#%&,:;<>=@{}~\$\(\)\*\+\/\\\?\[\]\^\|]+/g;
        let pwdInput = event.target.value;
        console.log('In pwd change..'+pwdInput);
        console.log(lowerCase.test(pwdInput));
        if(!validPwd.test(pwdInput)){
            this.setInputValidity(event.target, "Please enter a valid password"); 
        }
        let lCaseInput = this.template.querySelector('[data-id="lowercase"]');
        if(lowerCase.test(pwdInput)){
            lCaseInput.className += " txt-color-green";
        }else{
            lCaseInput.className += "";
        }
        let uCaseInput = this.template.querySelector('[data-id="uppercase"]');
        if(upperCase.test(pwdInput)){
            console.log('upper case cllass');
            uCaseInput.className += " txt-color-green";
        }else{console.log('upper case no cllass');
            uCaseInput.className += "";
        }
        let numInput = this.template.querySelector('[data-id="numberval"]');
        if(numberInpt.test(pwdInput)){console.log('number input cllass');
            numInput.className += " txt-color-green";
        }else{console.log('numb input no cllass');
            numInput.className += "";
        }
        let symInput = this.template.querySelector('[data-id="symbol"]');
        if(symbolInpt.test(pwdInput)){console.log('symbol cllass');
            symInput.className += " txt-color-green";
        }else{console.log('symbol no cllass');
            symInput.className += "";
        }
        let charLength = this.template.querySelector('[data-id="charlength"]');
        if(pwdInput.length < 8){
            charLength.className += "";
        }else{
            charLength.className += " txt-color-green";
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

    togglereEnteredPassword() {
        if(this.reEnterdPasswordType == 'password') {
            this.reEnterdPasswordType = 'text';
        }
        else {
            this.reEnterdPasswordType = 'password';
        }
    }   

    @api
    validateAllFields(){
        console.log('reg pwd In validate fields');
        let result = true;

        this.template.querySelectorAll("lightning-input").forEach(element => {
            if(element.name === "reenteredpwd"){
                if(element.checkValidity() && element.value != this.passwordValue){
                    this.setInputValidity(element, "Passwords don't match");
                }
            }
        });

        result &= this.checkInputValidty();
        if(result){
            const loginDetailsPage = new CustomEvent('updatelogindetailsparameters', {  detail : {password : this.passwordValue}});

            // Dispatches the event.
            this.dispatchEvent(loginDetailsPage); 
        }
        return result;
    }

    setInputValidity(input, message){
        input.setCustomValidity(message);
        input.reportValidity();       
    }

    checkInputValidty(){
        let result = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        return result;
    }     
}