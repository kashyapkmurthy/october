import { LightningElement, api } from 'lwc';

export default class ThankYouPage extends LightningElement {
    @api registrationParameters;
    @api isExistingUser = false;    
    regTypeBusiness = false;
    email="";
    
    connectedCallback(){
        let regParams = JSON.parse(this.registrationParameters);
        if(regParams){
            let regTypeValue = regParams['registrationType'];
            this.regTypeBusiness = regTypeValue && regTypeValue === "Business"? true : false;

            let contPageDetails = regParams['contactPageDetails'];
            if(contPageDetails){
                this.email = contPageDetails.email;
            }
        }
    }
}