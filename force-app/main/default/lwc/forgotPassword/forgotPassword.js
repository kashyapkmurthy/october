import { LightningElement, wire, track, api } from 'lwc';
import forgotPassword from '@salesforce/apex/LSC_ForgotPassword.forgotPassword';
import { NavigationMixin  } from 'lightning/navigation';

export default class ForgotPassword extends LightningElement {
    title = 'Forgot password';
    username;
    startUrl;
    currentPageReference;
    isSubmitted = false;

    handleChange(event){
        const typedValue = event.target.value;
        const trimmedValue = typedValue.trim(); 
        if (typedValue !== trimmedValue) {
            event.target.value = trimmedValue;
        }
        this.username = trimmedValue;
    }

    handleforgotPassword(){
        let passwordField = this.template.querySelector("[data-field='username']");
        passwordField.setCustomValidity('');
        passwordField.reportValidity();        
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
        if (allValid) {
            forgotPassword({ username: this.username})
            .then((result) => {   
                this.isSubmitted = true;               
            })
            .catch((error) => {
            });
        } 

    }

}