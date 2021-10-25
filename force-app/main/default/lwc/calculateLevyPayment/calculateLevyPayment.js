import { LightningElement } from "lwc";
import { NavigationMixin } from 'lightning/navigation';

export default class CalculateLevyPayment extends NavigationMixin(LightningElement) {
    numberFieldValue;
    calculatedValue = 0;
    canPayLevy = false;
    showResetBtn = false;
    helptext = 'Enter the total cost of building and construction work (including GST), as determined by your approving authority: \n i.e., as listed on your approval DA, CC, CDC or Contract';

    handleNumberChange(event) {
        this.numberFieldValue = event.target.value;
        this.showResetBtn = true;
        this.calculatedValue = 0;
        if (this.numberFieldValue >= 25000) {        
            this.calculatedValue = Math.floor(this.numberFieldValue * 0.0035);
            this.canPayLevy = true;
        }
        if (this.numberFieldValue < 25000) {        
            this.canPayLevy = false;
        }
    }

    resetButton(event) {
        this.numberFieldValue = null;
        this.calculatedValue = 0;
        this.showResetBtn = false;
        this.canPayLevy = false;
    }

    handleClick(event) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'new-levy'
            },
            state: {
                cost: this.numberFieldValue
            }
     });
  }

  get showLevyPay(){
      let input = this.template.querySelector(".totalCost");
      return this.canPayLevy && input.checkValidity();
  }

}