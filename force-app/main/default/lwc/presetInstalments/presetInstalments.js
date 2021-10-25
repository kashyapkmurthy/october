import { LightningElement,api, track} from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import presetInstalmentsStyles from '@salesforce/resourceUrl/presetInstalmentsStyles';
import formFactorPropertyName from '@salesforce/client/formFactor';
const quarterlyVal = 4;
const divFactor = [1, 1/4, 1/2, 3/4];
export default class PresetInstalments extends LightningElement {
    @api
    isInternal = false;
    @api developCostsData;
    @track instalmentData = [];
    levyPayable;

    connectedCallback(){
        if (this.isInternal) {
            loadStyle(this, presetInstalmentsStyles);
        }
        this.calculatePresetParams();
    }

    get mobilePadding() {
        return formFactorPropertyName !== 'Large' ? 'slds-var-p-horizontal_medium slds-var-p-top_medium' : 'slds-var-p-horizontal_medium';
    }

    get smallMediumDevView() {
        console.log('device.....'+formFactorPropertyName);
        return formFactorPropertyName !== 'Large' ? true : false;
    }    

    calculatePresetParams(){
        this.levyPayable = parseFloat(this.developCostsData.levyPayable);
        let presetInstal = parseFloat(Math.floor(this.developCostsData.levyPayable/quarterlyVal));

        let firstInstalment = presetInstal + (this.levyPayable - (presetInstal*4));
        let tempArray = [];
        for(let i = 0; i < quarterlyVal; i++){
            let tempParams = {};
            tempParams.bckgrndColor = (this.smallMediumDevView && (i & 1))? 'layout-backgrnd-color': '';
            tempParams.id = i;
            tempParams.payNo = i+1;
            let newStartDate = moment(this.developCostsData.startDate); 
            let newEndDate = moment(this.developCostsData.endDate); 
            if(i == 0) {
                tempParams.presetInstal = firstInstalment;
                tempParams.dueDate = moment(newStartDate).format("DD-MM-YYYY"); 
            }else {
                tempParams.presetInstal = presetInstal;
                tempParams.dueDate = moment(moment(newStartDate).add(Math.round(newEndDate.diff(newStartDate, 'days')*divFactor[i]),'d')).format("DD-MM-YYYY");
            }
            tempArray.push(tempParams);
            console.log(JSON.stringify(tempArray));
        }
        this.instalmentData = tempArray;

        //fire custom event
        const presetInstalEvent = new CustomEvent('updatepresetinstalments', {  detail : this.instalmentData});
        // Dispatches the event.
        this.dispatchEvent(presetInstalEvent); 
    }
}