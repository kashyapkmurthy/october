import { LightningElement, api } from 'lwc';
import USER_ID from "@salesforce/user/Id";

export default class InstalmentsComponent extends LightningElement {
    @api levyParameters;
    devCostsData = {};
    payByInstal="";
    instalOption="";
    primaryContact="";
    instalmentInputs = {};
    variableInstalments = [];
    instcmp_variableinstalmentparmas=[];
    presetInstalments = [];
    uploadedFiles = [];
    givenName="";
    surName="";
    phone="";
    email="";

    connectedCallback(){
        console.log('In instalments cc ');
        let levyParams = JSON.parse(this.levyParameters);
        if(levyParams){
            if(levyParams['developmentCostsDetails']){ 
                this.devCostsData.levyPayable =  levyParams['developmentCostsDetails'].levyPayable;
                this.devCostsData.totalBuildingCost =  levyParams['developmentCostsDetails'].totalBuildConstCost;
            }
            if(levyParams['developmentDetails']){
                this.devCostsData.startDate = levyParams['developmentDetails'].startDate; 
                this.devCostsData.endDate = levyParams['developmentDetails'].endDate;
                this.devCostsData.appNumber = levyParams['developmentDetails'].appNumber;
            } 
            let instalmentCmpDetails = levyParams['instalmentCmpDetails'];
            if(instalmentCmpDetails){
                this.payByInstal = instalmentCmpDetails.payLevyInstal;
                this.instalOption = instalmentCmpDetails.instalOption? instalmentCmpDetails.instalOption : "";
                if(this.instalOption && this.instalOption === 'variableInstal'){
                    this.instcmp_variableinstalmentparmas = levyParams['variableInstalments'];
                }
                this.primaryContact = instalmentCmpDetails.primaryContact? instalmentCmpDetails.primaryContact : "";
                if(this.primaryContact && this.primaryContact === "no"){
                    this.givenName = instalmentCmpDetails.givenName;
                    this.surName = instalmentCmpDetails.surName;
                    this.phone = instalmentCmpDetails.phone;
                    this.email = instalmentCmpDetails.email;
                }
            }
            let uploadedFiles = levyParams['uploadedFiles'];
            if(uploadedFiles){
                this.uploadedFiles = uploadedFiles;
            }
        }
    }

   


    get payLevyInstal(){
        return [{label: 'Yes', value: 'yes'},
        {label: 'No', value: 'no'}];
    }

    get primaryContactOptions(){
        return [{label: 'Yes', value: 'yes'},
        {label: 'No', value: 'no'}];
    }

    get instalmentOptions(){
        return [{label: 'Pay the levy in preset equal instalments', value: 'presetInstal'},
        {label: 'Provide your proposed scheduling of the stages of work', value: 'variableInstal'}];
    }

    handleChange(event){
        const id = this.getId(event.target.id);
        let value = event.target.value;
        console.log('id...'+id);
        switch(id){
            case 'paybyInstal':
                this.payByInstal = value;
                const customevt = new CustomEvent('payinstallment', {  detail : {instalments : value}});
                this.dispatchEvent(customevt); 
                console.log('payByInstal...'+this.payByInstal);
                break;
            case 'instalOption':
                this.instalOption = value;
                break;
            case 'primContact':
                this.primaryContact = value;
                break;
        }
    }

    handleEmailChange(event){
       const typedValue = event.target.value;
        const trimmedValue = typedValue.trim(); 
        if (typedValue !== trimmedValue) {
            event.target.value = trimmedValue;
       }
        this.email = trimmedValue;
    }

    getId(id){
        const finalId = (id || "").split("-");
        finalId.pop();
        return finalId.join("-");
    }  

    setInputValidity(input, message){
        input.setCustomValidity(message);
        input.reportValidity();       
    }

    get isPayByInstal(){
        console.log('gtter...'+this.payByInstal);
        return this.payByInstal === 'yes';
    }

    get instalOptionPreset(){
        return this.instalOption === 'presetInstal' && this.payByInstal === 'yes';
    }

    get instalOptionVariable(){
        return this.instalOption === 'variableInstal' && this.payByInstal === 'yes';
    }

    get instalOptionSelected(){
        return this.instalOption && this.payByInstal === 'yes'? true : false;
    }

    get notPrimaryContact(){
        return this.primaryContact === 'no';
    }

    get currentUserId(){
        return USER_ID;
    }

    handleVariableInstal(event){
        this.variableInstalments = event.detail;
    }

    handlePresetInstal(event){
        console.log('in preset handle')
        this.presetInstalments = event.detail;
        console.log(this.presetInstalments);
    }

    handleFileUpload(event){
        this.uploadedFiles = event.detail;
    }

    @api
    validateAllFields(){
        console.log('instalments validateAll fields...');
        // Instalments component inputs
        this.template.querySelectorAll('lightning-input').forEach(element => {
            if(element.value && element.checkValidity()){
                this.instalmentInputs[element.name] = element.value.trim();
            }
        });

        this.template.querySelectorAll('lightning-radio-group').forEach(element => {
            if(element.value && element.checkValidity()){
                this.instalmentInputs[element.name] = element.value;
            }
        });

        //Variable Instal inputs validation
        let variableInstalValid = true;
        let variableInstalCmp = this.template.querySelector('c-variable-instalments');
        if(variableInstalCmp){
            variableInstalValid &= variableInstalCmp.validateAllFields();
        }

        let fileUploadValid = true;
        let fileUploadCmp = this.template.querySelector('c-file-upload');
        if(fileUploadCmp){
            fileUploadValid &= fileUploadCmp.validateAllFields();
        }

        let finalResult = this.checkInputValidty() && variableInstalValid && fileUploadValid;

        if(finalResult){
            const instalmentCmpEvent = new CustomEvent('updateinstalmentparameters', {  detail : {instalmentCmpDetails : this.instalmentInputs,
                variableInstalments : this.variableInstalments, presetInstalments : this.presetInstalments, uploadedFiles : this.uploadedFiles}});
            // Dispatches the event.
            this.dispatchEvent(instalmentCmpEvent); 
        }
  
        return finalResult;
    }

    checkInputValidty(){
        let result = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);

        let radioGrpResult = [...this.template.querySelectorAll('lightning-radio-group')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        return result && radioGrpResult;
    }  
}