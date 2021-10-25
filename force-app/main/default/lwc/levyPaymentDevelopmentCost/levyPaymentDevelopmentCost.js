import { LightningElement, api } from 'lwc';

export default class LevyPaymentDevelopmentCost extends LightningElement {
    @api levyParameters;
    @api ownerBuilderParameters; 
    userJourney="";
    developmentCosts={};
    ownerBuilderDts;
    radioBtnValue;
    nolicencelookup = false;
    levyExempValue;
    licenceLookup = false;
    displayAdditionalFields = false;
    totalCostHelpTxt = 'Enter the total cost of the construction work (inclusive of GST), as determined by your approving authority: i.e. as listed on your approval - DA, CC, CDC or Contract';
    estimatedCostHelpTxt = "Enter the cost of the voluntary labour personally performed by you (inclusive of GST), during the construction. Do not include time spent managing the project in this figure.";
    org_estimatedcosthelptxt = "There MUST be a voluntary component of the work performed by the Non-profit organisation in order to be eligible for the partial exemption. (This figure MUST be inclusive of GST).";
    numberFieldValue;
    exepmtionValue;
    calculatedValue=0;
    canPayLevy = false;
    indvidualapptype = false;
    businessapptype = false;
    organisationapptype = false;
    displayradio = false;
    urlCostParam = 0;

    @api 
    typeoflevyapplication = 'Individual';

    ownerBuilderDetails = {};

    connectedCallback(){
        console.log('In dev costs connected callback');
        let levyParams = JSON.parse(this.levyParameters);
        if(levyParams){
            this.userJourney = levyParams['userJourney'];
            this.numberFieldValue = this.urlCostParam = levyParams['cost']? levyParams['cost'] : '';
            console.log(levyParams['cost']);
            console.log(this.numberFieldValue);
            this.calculatedValue = this.levyPayable;
            if(levyParams['developmentCostsDetails']){
                this.levyExempValue = levyParams['developmentCostsDetails'].levyExemptionOption ? levyParams['developmentCostsDetails'].levyExemptionOption : "";
                if(this.levyExempValue === 'yes'){
                    this.displayAdditionalFields = true;
                    this.exepmtionValue = levyParams['developmentCostsDetails'].estCostVoluntaryLabor;
                    this.numberFieldValue = levyParams['developmentCostsDetails'].totalBuildConstCost;
                    this.calculatedValue = levyParams['developmentCostsDetails'].levyPayable;
                } else if(this.levyExempValue === 'no'){
                    this.nolicencelookup = true;
                    this.numberFieldValue = levyParams['developmentCostsDetails'].totalBuildConstCost;
                    this.calculatedValue = levyParams['developmentCostsDetails'].levyPayable;
                }
                if(this.userJourneyIndividual){
                    if(this.levyExempValue === 'yes'){
                        this.licenceLookup = true;
                        this.ownerBuilderParameters = levyParams['ownerBuilderDetails'] ? levyParams['ownerBuilderDetails'] : {};
                        this.ownerBuilderDts = levyParams['ownerBuilderDetails'] ? levyParams['ownerBuilderDetails'] : {};
                        console.log('I am here');
                    }
                }else if(this.userJourneyBusiness){
                    this.numberFieldValue = levyParams['developmentCostsDetails'].totalBuildConstCost;
                    this.calculatedValue = levyParams['developmentCostsDetails'].levyPayable;
                }
            }
        }
    }

    get estCosthelpText(){
        return (this.userJourney && this.userJourneyOrganisation) ? this.org_estimatedcosthelptxt : this.estimatedCostHelpTxt;
    }

    get userJourneyIndividual(){
        return this.userJourney === 'Individual';
    }

    get userJourneyBusiness(){
        return this.userJourney === 'Business';
    }

    get userJourneyOrganisation(){
        return this.userJourney === 'Organisation';
    }

    get levyExemptionOptLabel(){
        return this.userJourney === 'Individual'? 'Owner Builder partial levy exemption?' : 'non-profit organisation partial exemption?';
    }

    get applyForExemption(){
        return this.userJourney === 'Individual' || this.userJourney === 'Organisation';
    }

    get displayAddFields(){
        return this.displayAdditionalFields === true;
    }

    get ShowNoLicenseLookup(){
        return this.userJourney === 'Business' || this.nolicencelookup === true;
    }

    get showLicenseLookup(){
        return this.licenceLookup === true;
    }

    get options() {
        return [
            { label: 'Yes', value: 'yes' },
            { label: 'No', value: 'no' },
        ];
    }

    get isTotalCostNEqToCostParam(){
        return this.numberFieldValue != this.urlCostParam;
    }
    
    handleNumberChange (event){
        this.numberFieldValue = event.target.value;
        this.setInputValidity(event.target,"");
        this.validateVoluntaryLabCost();
        //Check if TotalCost is less than 25000 dollars
        if(this.numberFieldValue >= 25000){
            this.calculateLevyPayable();
        }
    }

    handleBlur(event){
        //Check if TotalCost is less than 25000 dollars
        if(this.numberFieldValue && this.numberFieldValue < 25000){
            console.log('valid...');
            this.setInputValidity(event.target, "No levy is payable on work costing less than $25,000");
        }
    }

    get levyPayable(){
        return this.numberFieldValue && this.numberFieldValue >= 25000? parseFloat(Math.floor(this.numberFieldValue * 0.0035)): 0;
    }

    handleExemptionChange (event){
        this.exepmtionValue = event.target.value;
        if(this.validateVoluntaryLabCost()){
            if(this.numberFieldValue && this.numberFieldValue >= 25000)
                this.calculateLevyPayable();
        }
    }

    calculateLevyPayable(){
        let exempVal = 0;
        let calcValue;
        if(this.exepmtionValue)
            exempVal = this.exepmtionValue;
        calcValue = parseFloat(Math.floor((this.numberFieldValue * 0.0035)) - (Math.round(exempVal * 0.0035)));
        this.calculatedValue = ((this.userJourneyIndividual || this.userJourneyOrganisation) && this.radioBtnValue === 'yes' && calcValue < 50) ? 50 : calcValue;         
        this.canPayLevy = true;
    }

    validateVoluntaryLabCost(){
        let input = this.template.querySelector('[data-id="voluntaryLabor"]');
        if(input && input.value){
            if(input.value <= 0){
                this.setInputValidity(input, "The amount should be greater than $0.00. Else select option 'No' to continue.");
            }
            else if ((this.userJourneyIndividual || this.userJourneyOrganisation) && this.exepmtionValue && this.numberFieldValue && (this.exepmtionValue > (0.5 * this.numberFieldValue))) {
                this.setInputValidity(input, "The voluntary labour amount is capped at 50% of the total cost of building and construction work amount. Please update the voluntary labour amount");
                return false;
            }else {
                this.setInputValidity(input, "");
                return true;
            }
        }
    }

    setInputValidity(input, message){
        input.setCustomValidity(message);
        input.reportValidity();       
    }

    handleChange(event) {
        this.radioBtnValue = event.detail.value;
        this.canPayLevy = false;

        if (this.radioBtnValue == 'yes'){
            this.nolicencelookup = false; 
            if(this.isTotalCostNEqToCostParam){
                if(this.numberFieldValue) this.numberFieldValue = 0.0;
                if(this.calculatedValue) this.calculatedValue  = 0.0;
            }
            if(this.exepmtionValue) this.exepmtionValue = 0.0;
            if (this.userJourneyIndividual){
                this.licenceLookup = true;
                //Reset the owner builder inputs and let User enter it afresh
                this.ownerBuilderParameters = {};
            }
            this.displayAdditionalFields = false;
            if (this.userJourneyOrganisation){
                this.displayAdditionalFields = true;
            }    
        }
        if (this.radioBtnValue == 'no'){       
            this.licenceLookup = false;
            this.nolicencelookup = true;
            this.displayAdditionalFields = false;
            if(this.isTotalCostNEqToCostParam){
                if(this.numberFieldValue) this.numberFieldValue = 0.0;
                if(this.calculatedValue) this.calculatedValue  = 0.0;
            }
            if(this.exepmtionValue) this.exepmtionValue = 0.0;
        }
        console.log('Option selected with value: ' + this.radioBtnValue);
    }  
    
    handleChildEvent (event){
        this.ownerBuilderDts = event.detail.ownerBuilderDetails;
        console.log('handleChildEvent -----> add fields-->' + event.detail.showAdditionalInputs); 
        this.displayAdditionalFields = event.detail.showAdditionalInputs; 
    }

    handleEmptyOwnerTextBox (event){
        console.log('handleEmptyOwnerTextBox' + event.detail);  
        if ( event.detail)   {
            this.displayAdditionalFields = event.detail.showAdditionalInputs;     
        }   
    }    

    @api
    validateAllFields(){
        console.log('In dev costs validate fields');
        let clearParams = '';
        // Development costs inputs
        this.template.querySelectorAll('lightning-input').forEach(element => {
            if(element.value && element.checkValidity()){
                this.developmentCosts[element.name] = element.value;
                if(element.name == 'totalBuildConstCost' && element.value < 25000){
                    console.log('valid...');
                    this.setInputValidity(element, "No levy is payable on work costing less than $25,000");
                }
            }
        });
        console.log('In validate fields');
        this.template.querySelectorAll('lightning-radio-group').forEach(element => {
            if(element.value && element.checkValidity()){
                this.developmentCosts[element.name] = element.value;
            } 
        })
        console.log('In validate fields');
        //validate Address Search Input
        let ownerBuildValid = true;
        let ownerBuildCmp = this.template.querySelector('c-owner-builder-licence-lookup');
        if(ownerBuildCmp){
            ownerBuildValid &= ownerBuildCmp.validateAllFields();
        }
        else{
            clearParams = 'ownerBuilderDetails';
        }
        console.log('In validate fields');
        //Check for valid inputs in all the components
        let finalResult = ownerBuildValid && this.checkInputValidty();
        if(finalResult){
            const developmentCostsEvent = new CustomEvent('updatedevelopmentcostsparameters', {  detail : {ownerBuilderDetails : this.ownerBuilderDts,
                                                                                                developmentCostsDetails : this.developmentCosts,
                                                                                                clearParams : clearParams }});
            // Dispatches the event.
            this.dispatchEvent(developmentCostsEvent); 
        }
        return finalResult;
    }

    checkInputValidty(){
        let result = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        let radioButtonResult = true;
        radioButtonResult = [...this.template.querySelectorAll('lightning-radio-group')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        console.log(result & radioButtonResult);
        return result & radioButtonResult;
    }

}