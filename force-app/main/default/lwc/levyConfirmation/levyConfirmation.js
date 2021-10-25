import { LightningElement, api } from 'lwc';
import formFactorPropertyName from '@salesforce/client/formFactor';

export default class Confirmation extends LightningElement {
    declarationText = "Providing false or misleading information may result in prosecution and a penalty of up to $5,500 under Section 58A of the Building and Construction Industry Long Service Payments Act 1986."
    checkboxLabel = "I hereby declare that I am authorised to act on behalf of the applicant, and the information I have provided is true and correct to the best of my knowledge.";
    @api levyParameters;
    devDetails = {};
    devCostDetails = {};
    devApprovalDetails = {};
    constSiteAddress = {};
    postalAddress = {};
    authRepDetails = {};
    instalCmpDetails = {};
    presetInstalments = [];
    variableInstalments = [];
    startDate;
    endDate;
    tableLabel = "";
    notPrimaryContact = false;
    uploadedFiles=[];
    connectedCallback(){
        let levyParams = JSON.parse(this.levyParameters);
        this.devDetails = levyParams['developmentDetails'];
        this.startDate = moment(this.devDetails.startDate).format("DD-MM-YYYY");
        this.endDate = moment(this.devDetails.endDate).format("DD-MM-YYYY");
        this.devCostDetails = levyParams['developmentCostsDetails'];
        this.devApprovalDetails = levyParams['developmentApproval'];
        this.constSiteAddress = levyParams['constructionSiteAddress'];
        this.instalCmpDetails = levyParams['instalmentCmpDetails'];
        let tempVarInstal = levyParams['variableInstalments'];
        let tempPresetInstal = levyParams['presetInstalments'];
        let userJourney = levyParams['userJourney'];
        let uploadedFiles = levyParams['uploadedFiles'];
        if(uploadedFiles){
            this.uploadedFiles = uploadedFiles;
        }
        if(userJourney === 'Business' || userJourney === 'Individual') {
            this.authRepDetails = levyParams['authRepDetails'];
            this.postalAddress = this.authRepDetails? levyParams['postalAddress'] : null;
        }
        if(userJourney === 'Business' || userJourney === 'Organisation'){
            let payInstal = this.instalCmpDetails && this.instalCmpDetails.payLevyInstal ?this.instalCmpDetails.payLevyInstal:"";
            let selectedInstalOption = this.instalCmpDetails && this.instalCmpDetails.instalOption ?this.instalCmpDetails.instalOption:"";
            if(payInstal == 'yes'){
                let i = 0;
                this.notPrimaryContact = this.instalCmpDetails.primaryContact == 'no' ? true : false;
                if(selectedInstalOption === 'variableInstal'){
                    this.tableLabel = "Proposed payment details";
                    tempVarInstal.pop();
                    tempVarInstal.forEach(element => {
                        element.startDate = moment(element.startDate).format("DD-MM-YYYY");
                        element.levyAmt = parseFloat(element.levyAmt).toFixed(2);
                        element.bckgrndColor = (this.smallMediumDevView && (i & 1))? 'layout-backgrnd-color' : '';
                        i++;
                    });
                    this.variableInstalments = tempVarInstal;
                }  else if(selectedInstalOption === 'presetInstal') {
                    this.tableLabel = "Instalment payment schedule";
                    tempPresetInstal.forEach(element => {
                        element.bckgrndColor = (this.smallMediumDevView && (i & 1))? 'layout-backgrnd-color' : '';
                        i++;
                    });
                    this.presetInstalments = tempPresetInstal;
                }
            }
        }
    }

    get smallMediumDevView() {
        return formFactorPropertyName !== 'Large' ? true : false;
    }

    handleClick(event){
        console.log('in summary handle click...'+event.target.id);
        let clickedButtonId = this.getId(event.target.id);
        if(clickedButtonId){
            const summaryDetails = new CustomEvent('summaryeditevent', {  detail :clickedButtonId});

            // Dispatches the event.
            this.dispatchEvent(summaryDetails); 
        }
    }

    getId(id){
        const finalId = (id || "").split("-");
        finalId.pop();
        return finalId.join("-");
    }   

    get instalmentData(){
        return this.instalCmpDetails.instalOption === 'variableInstal'? this.variableInstalments : this.presetInstalments;
    }

    get isVariableInstalments(){
        return this.instalCmpDetails.instalOption === 'variableInstal';
    }

    get isPresetInstalments(){
        return this.instalCmpDetails.instalOption === 'presetInstal';
    }

    get instalmentSelected(){
        return this.instalCmpDetails && this.instalCmpDetails.instalOption ? true: false;
    }

    get authRepDetailsPresent(){
        return this.authRepDetails && (this.authRepDetails.yourRole === 'yourRoleBehalf' || this.authRepDetails.yourRole === 'yourRoleBusinessBehalf');
    }

    @api
    validateAllFields(){
        let input = this.template.querySelector('lightning-input');
        console.log('in vlaiate all fields summary...'+input.checked);
        if(input.reportValidity() && input.checkValidity()){
            const levyConfrmEvent = new CustomEvent('updatelevyconfirmatinparameters', {  detail : {declaration : input.checked}});
            // Dispatches the event.
            this.dispatchEvent(levyConfrmEvent); 
        }
        return input.checkValidity();
    }

    get hasFiles() {
        return this.uploadedFiles.length > 0;
    }
}