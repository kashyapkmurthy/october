import { LightningElement, api } from 'lwc';

export default class RegistrationTypeChoice extends LightningElement {
    @api registrationParameters;    
    value = '';

    get options() {
        return [
            { label: 'Select', value: '' },
            { label: 'BCI Levy Payer', value: 'bcilevy' },
            { label: 'BCI Employer', value: 'bciemployer' },
            { label: 'BCI Worker', value: 'bciworker' },
            { label: 'BCI Tax Agent', value: 'bcitax' },
            { label: 'CCI Employer', value: 'cciemployer' },
            { label: 'CCI Worker', value: 'cciworker' },
        ];
    }

    @api
    validateAllFields(){
        console.log('in type choice validate all fieds');
        //Add conditions
        return true;
    }

}