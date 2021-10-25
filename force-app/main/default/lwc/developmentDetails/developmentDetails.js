import { LightningElement, wire, api } from 'lwc';
import { getPicklistValues, getObjectInfo }from 'lightning/uiObjectInfoApi';
import LEVY_OBJECT from '@salesforce/schema/LSC_Levy__c';
import GOVT_AUTH_FIELD from '@salesforce/schema/LSC_Levy__c.LSC_LocalGovtAreaOrGovtAuthority__c';
import APPTYPE_FIELD from '@salesforce/schema/LSC_Levy__c.LSC_ApplicationType__c';

export default class DevelopmentDetails extends LightningElement {
    @api devdetails_addressparameters; 
    @api levyParameters;
    govtAuthOptions;
    govtAuthdData;
    appTypeValue="";
    govtAuthValue ="";
    developmentDetails={};
    constSiteAddressDetails={};
    planningPortalNum="";
    applicationNum="";
    startDate;
    endDate;
    error;
    picklstDataAvailable = false;
    appTypeOptions;
    appNumberHelpText = "If you do not have this number please call your approving authority and obtain the number before proceeding. Your approving authority is your Council, Private Certifier or Government Department. Your application type will be: a DA, CC, CDC or Government Contract. Your application number could look something like the following: 123/2020, D/2020/123, 2020-123";

    @wire(getObjectInfo, { objectApiName: LEVY_OBJECT })
    levyMetadataHandler({data,error}) {
        console.log('In handler...'+data);
        if(data) {
            console.log('In data handler...'+data);
            const rtis = data.recordTypeInfos;
            this.defaultRecordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'BCI')
        }
        if(error) {
            console.log('In err handler...'+error.body.message);
            this.error = error;
        }
    }
    defaultRecordTypeId;
    

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: GOVT_AUTH_FIELD })
    govAuthFieldInfo({ data, error }) {
        if (data) {
            this.govtAuthdData = data;
            this.picklstDataAvailable = true;
        }
        else if (error) console.log('error...'+error);
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: APPTYPE_FIELD })
    appTypeFieldInfo({ data, error }) {
        if (data) {
            this.appTypeOptions = data.values;
        }
        else if (error) console.log('error...'+error);
    }    

    connectedCallback(){
        console.log('In dev details cc');
        let levyParams = JSON.parse(this.levyParameters);
        if(levyParams){
            this.devdetails_addressparameters = levyParams['constructionSiteAddress'];
            this.constSiteAddressDetails = this.devdetails_addressparameters ? this.devdetails_addressparameters : {};

            let devDetails = levyParams['developmentDetails'];
            if(devDetails){
                this.appTypeValue = devDetails.appType;
                this.govtAuthValue = devDetails.govtAuth;
                this.applicationNum = devDetails.appNumber;
                this.planningPortalNum = devDetails.planningPortalNumber;
                this.startDate = devDetails.startDate;
                this.endDate = devDetails.endDate;
            }
        }
    }

    get govtAuthOptionList(){
        if(this.picklstDataAvailable){
            let key = this.govtAuthdData.controllerValues[this.appTypeValue];
            this.govtAuthOptions = this.govtAuthdData.values.filter(opt => opt.validFor.includes(key));
            console.log('govt options...'+JSON.stringify(this.govtAuthOptions));
            return this.govtAuthOptions;
        }
        else return null;
    }

    handleAppTypeChange(event){
        this.template.querySelector('c-searchable-picklist').setSearchInput('');
        this.appTypeValue = event.target.value;
    }

    handleAddressDetails(event){
        console.log('In dev details custom event...'+event.detail);
        const id = this.getId(event.target.id);
        this.constSiteAddressDetails = event.detail;
    } 

    getId(id){
        const finalId = (id || "").split("-");
        finalId.pop();
        return finalId.join("-");
    }      

    handleStartDate(event){
        let input = event.target;
        this.startDate = input.value;
        this.verifyDates();
    }

    handleEndDate(event){
        let input = event.target;
        this.endDate = input.value;
        this.verifyDates();
    }

    verifyDates(){
        let input = this.template.querySelector('[data-id="endDate"]');
        if(this.startDate && this.endDate){
            if(moment(this.endDate).isBefore(this.startDate)){
                input.setCustomValidity("Construction End date cannot be before Construction Start date");
            } else{
                input.setCustomValidity("");
            }
            input.reportValidity();
        }
    }

    handleSelected(event){
        this.govtAuthValue = event.detail;
    }

    onFocus(event){
    }

    @api
    validateAllFields(){
        console.log('developmenet details validateAll fields...');

        // Development Details inputs
        this.template.querySelectorAll('lightning-input').forEach(element => {
            if(element.reportValidity() && element.value && element.checkValidity()){
                this.developmentDetails[element.name] = element.value;
            }
        });

        this.template.querySelectorAll('lightning-combobox').forEach(element => {
            if(element.reportValidity() && element.value && element.checkValidity()){
                this.developmentDetails[element.name] = element.value;
            }
        });

        //Searchable picklist validation
        let pickLstValid = true;
        let searchPicklistCmp = this.template.querySelector('c-searchable-picklist');
        if(searchPicklistCmp){
            pickLstValid &= searchPicklistCmp.validateAllFields();
        }
        if(pickLstValid)
            this.developmentDetails['govtAuth'] = this.govtAuthValue;

        //validate Address Search Input
        let addressSearchValid = true;
        let addrSearchCmp = this.template.querySelector('c-new-address-search');
        if(addrSearchCmp){
            addressSearchValid &= addrSearchCmp.validateAllFields();
        }

        //Check for valid inputs in all the components
        let finalResult = this.checkInputValidty() && addressSearchValid && pickLstValid;
        console.log('Development Details Page params...'+ this.developmentDetails);
        //Trigger a custom event if all inputs are valid
        if(finalResult){
            const developmentDetailsEvent = new CustomEvent('updatedevelopmentdetailsparameters', {  detail : {developmentDetails : this.developmentDetails,
                                                                                                    constructionSiteAddress : this.constSiteAddressDetails}});
            // Dispatches the event.
            this.dispatchEvent(developmentDetailsEvent); 
        }
        return finalResult;
    }

    checkInputValidty(){
        let result = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        console.log('validte all...'+result);
        return result;
    }

}