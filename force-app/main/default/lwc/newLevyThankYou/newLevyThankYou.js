import { LightningElement, api, wire } from 'lwc';


export default class NewLevyThankYou extends LightningElement {
    @api levyParameters;
    error;
    caseRecordId;
    userJourney;
    caseUrl;
    caseNumber;

    connectedCallback(){
        console.log('In thank yyou page');
        let tempParams = JSON.parse(this.levyParameters);
        if(tempParams){
            this.caseRecordId = tempParams['caseId'];
            this.caseNumber = tempParams['caseNo'];
            this.caseUrl = '/bci/s/case/' + this.caseRecordId;
            this.userJourney = tempParams['userJourney'];
        }
    }

    get isBusiness(){
        return this.userJourney === "Business";
    }

    get isIndividual(){
        return this.userJourney === "Individual";
    }

    get isOrganisation(){
        return this.userJourney === "Organisation";
    }    
}