import { LightningElement, api } from 'lwc';

export default class RegistrationLevyChoice extends LightningElement {
    @api registrationParameters='{}';    
    value = '';
    
    connectedCallback(){
        console.log('In levy choice connected callback');
        let regTypeValue = JSON.parse(this.registrationParameters)['registrationType'];
        console.log(regTypeValue);
        this.value = regTypeValue? regTypeValue : '';
    }

    get options() {
        return [
            { label: 'Individual', value: 'Individual' },
            { label: 'Company/Organisation', value: 'Business' },
        ];
    }

    @api
    validateAllFields(){
        console.log('in levy choice validate all fieds');
        let input  = this.template.querySelector('lightning-radio-group');
        let result = input.value ? true : false;
        let clearParams = [];
        console.log('Input value...'+input.value);
        // Update registration Parameters
        if(result){
            console.log('result true...');
            if(input.value === 'Individual'){
                clearParams.push('businessPageDetails');
                clearParams.push('streetAddress');
                clearParams.push('postalAddress');
                clearParams.push('abnDetails');
            } else if(input.value === 'Business'){
                clearParams.push('postalAddress');
            }
            const regType = new CustomEvent('updateregparameters', {  detail : {registrationType: input.value, clearParams : clearParams}});
            // Dispatches the event.
            this.dispatchEvent(regType);   
        }
        else{
            console.log('result false...');
            input.setCustomValidity('Please select registration type');
            input.reportValidity();
        }
        return result;
    }

}