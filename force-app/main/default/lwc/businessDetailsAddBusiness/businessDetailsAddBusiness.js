import { LightningElement, api } from 'lwc';
import addBusiness from '@salesforce/apex/LSC_AccountController.addBusiness';
import { newErrorToast, handleError } from 'c/utils';

export default class BusinessDetailsAddBusinessComponent extends LightningElement {
    @api showButton = false;
    businessDetails;
    submitDisabled = false;
    isLoading = false;

    handleBusinessDetails(event){
        console.log('event business details received');
        console.log(event.detail);
        this.businessDetails = event.detail;
        console.log(JSON.stringify(this.businessDetails.abnDetails));
        console.log(JSON.stringify(this.businessDetails.businessPageDetails));
        console.log(JSON.stringify(this.businessDetails.postalAddress));
        console.log(JSON.stringify(this.businessDetails.streetAddress));
    }

    handleABNValidation(event){
        console.log('event abn received');
        console.log(event.detail);
        this.showButton = event.detail;
    }

    handleClick(event){
        let currentPage = this.template.querySelector('c-registration-business-details');
        console.log('inside checkpage...'+ currentPage);
        let result;
        if(currentPage.validateAllFields()){
            console.log('validated true');
            this.submitDisabled = true;
            this.isLoading = true;
            addBusiness({abnDetails: JSON.stringify(this.businessDetails.abnDetails), businessDetails : JSON.stringify(this.businessDetails.businessPageDetails),
                postalAddressDetails : JSON.stringify(this.businessDetails.postalAddress), streetAddressDetails : JSON.stringify(this.businessDetails.streetAddress)}).then((response) => {
                    if(response){
                        console.log("accoutn successfully created");
                        result = 'success';
                    } else{
                        console.log("accoutn creation failed");
                        result = 'failed';
                    }
                    const addBusinessEvent = new CustomEvent('updateaddbusinessstatus', {  detail : result});
                    // Dispatches the event.
                    this.dispatchEvent(addBusinessEvent); 
            }).catch((error) => {
                this.submitDisabled = false;
                this.isLoading = false;
                const errorMessage = handleError(error);
                this.dispatchEvent(newErrorToast({ message: errorMessage }));
            });
        } else{
            this.submitDisabled = false;
            this.isLoading = false;
            console.log('validated false');
        }
    }

    get showAddBusinessButton(){
        return this.showButton === true;
    }
}