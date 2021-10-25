import { LightningElement, api, wire} from 'lwc';

export default class RegistrationSummary extends LightningElement {
    @api registrationParameters;
    regTypeBusiness = false;
    name = "";
    phone="";
    email="";
    postalAddress="";
    abn="";
    entity="";
    businessEmail="";
    businessPhone="";
    billingAddress="";
    
    connectedCallback(){
        let regParams = JSON.parse(this.registrationParameters);
        if(regParams){
            let regTypeValue = regParams['registrationType'];
            this.regTypeBusiness = regTypeValue && regTypeValue === "Business"? true : false;

            let contPageDetails = regParams['contactPageDetails'];
            if(contPageDetails){
                this.name = contPageDetails.givenName +' '+contPageDetails.surName;
                this.phone = contPageDetails.phone;
                this.email = contPageDetails.email;
            }

            let addressStreetDetails = regParams['streetAddress'];
            addressStreetDetails ? this.billingAddress = addressStreetDetails.fullAddress : "";

            let addressPostalDetails = regParams['postalAddress'];
            addressPostalDetails ? this.postalAddress = addressPostalDetails.fullAddress : "";

            let businessDetails = regParams['businessPageDetails'];
            if(businessDetails){
                this.businessPhone = businessDetails.phone;
                this.businessEmail = businessDetails.email;
            }

            let abnDetails = regParams['abnDetails'];
            if(abnDetails){
                this.abn = abnDetails.australianBusinessNumber;
                this.entity = abnDetails.entityName;
            }
        }
    }

    @api
    validateAllFields(){
        let input = this.template.querySelector('lightning-input');
        console.log('in vlaiate all fields summary...'+input.checked);
        if(!input.checked){
            input.setCustomValidity("Please accept the declaration");
            input.reportValidity();
        }
        else{
            input.setCustomValidity("");
            input.reportValidity();
        }
        if(input.checkValidity()){
            const summaryDetailsEvent = new CustomEvent('updatesummarydetailsparameters', {  detail : {declaration : input.checked}});
            // Dispatches the event.
            this.dispatchEvent(summaryDetailsEvent); 
        }
        return input.checkValidity();
    }

    handleClick(event) {
        console.log('in summary handle click...'+event.target.id);
        let clickedButtonId = this.getId(event.target.id);
        if(clickedButtonId){
            const summaryDetails = new CustomEvent('summaryeditevent', {  detail :clickedButtonId});

            // Dispatches the event.
            this.dispatchEvent(summaryDetails); 
        }
    }

    get declarationLabel(){
        return this.regTypeBusiness === true? "I hereby declare that I am authorised to act on behalf of the applicant and the information I have provided is true and correct to the best of my knowledge." : 
        "I hereby declare the information I have provided is true and correct to the best of my knowledge.";
    }

    get businessEmailDeclaration() {
        return this.regTypeBusiness === true ? "My email may be provided to other users who request access to this business account." : "";
    }

    getId(id){
        const finalId = (id || "").split("-");
        finalId.pop();
        return finalId.join("-");
    }   
}