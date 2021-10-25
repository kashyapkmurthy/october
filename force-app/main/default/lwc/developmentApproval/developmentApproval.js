import { LightningElement, api } from 'lwc';

export default class DevelopmentApproval extends LightningElement {
    @api levyParameters;
    @api instalmentsStep;
    developmentApproval={};
    appAuthority="";
    phone="";
    contName="";
    email="";
    appTypeHelpText = "If you are engaging a Private Certifier, please enter their company name and the name of the person you are dealing with (if you have it). If you are dealing directly with a Council or Government Department, please enter the Council/Department name and the name of the person you are dealing with (if you have it).";
    
    connectedCallback(){
        console.log('In dev approval cc');
        let levyParams = JSON.parse(this.levyParameters);
        if(levyParams){
            let devApproval = levyParams['developmentApproval'];
            if(devApproval){
                this.appAuthority = devApproval.approvingAuthority;
                this.contName = devApproval.contactName;
                this.phone = devApproval.phone;
                this.email = devApproval.email;
            }
        }
    }

    setInputValidity(input, message){
        input.setCustomValidity(message);
        input.reportValidity();       
    }
    @api
    validateAllFields(){
        console.log('developmenet approval validateAll fields...');
        // Development Details inputs
        this.template.querySelectorAll('lightning-input').forEach(element => {
            if(element.value && element.checkValidity()){
                this.developmentApproval[element.name] = element.value;
            }
        });
        //Check for valid inputs in all the components
        let finalResult = this.checkInputValidty();
        console.log('Development approval Page params...'+ this.developmentApproval);
        //Trigger a custom event if all inputs are valid
        if(finalResult){
            const developmentApprovalEvent = new CustomEvent('updatedevelopmentapprovalparameters', {  detail : {developmentApproval : this.developmentApproval}});
            // Dispatches the event.
            this.dispatchEvent(developmentApprovalEvent); 
        }
        return finalResult;
    }

    checkInputValidty(){
        let result = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        return result;
    }

    handleChange(event){
        this.phone = event.target.value;
    }
    handleChangeEmail(event){
        const typedValue = event.target.value;
        const trimmedValue = typedValue.trim(); 
        if (typedValue !== trimmedValue) {
            event.target.value = trimmedValue;
        }
        this.email = trimmedValue;
    }

}