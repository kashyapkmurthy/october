import { LightningElement, api } from 'lwc';

export default class DatalistCompnent extends LightningElement {
    @api label="";
    @api listInput;
    @api errorMessage = "";
    displayList;
    @api searchInput="";
    showList = false;
    showError = false;

    connectedCallback(){
        console.log('In spicklist connected callback');
    }

    renderedCallback(){
        console.log('In spicklist rendered callback');
    }

    handleInput(e){
        this.searchInput = e.target.value;
        let filteredArray = this.listInput.filter(element => {
            return(
            element.value.toLowerCase().includes(this.searchInput.toLowerCase())
            );
        });
        console.log('in handle change..filtered array.'+JSON.stringify(filteredArray));
        this.displayList = filteredArray;
    }

    @api setSearchInput(value){
        this.searchInput = value;
        this.showList = false;
    }

    handleSelected(e){
        this.searchInput = e.target.innerText;
        this.showList = false;
    }

    onFocus(e){
        console.log('In focus');
        this.displayList = this.listInput;
    }

    onClick(){
        console.log('In click');
        if(this.showList === false){
            this.showList = true;
        } else{
            this.showList = false;
        }
    }
    onBlur(e){
        console.log('In blur');
        if(this.blankInput){
            this.showError = true;
        }
        else        
            this.showError = false;
    }
  
    get retList(){
        return this.displayList;
    }

    get showList(){
        return this.showList;
    }

    get showError(){
        return this.showError;
    }

    get blankInput(){
        return !this.searchInput ? true : false;
    }

    @api
    validateAllFields(){
        if(this.blankInput){
            this.showError = true;
        }else{
            this.showError = false;
            const selectedPicklistEvent = new CustomEvent('updateselectedpicklist', {  detail : this.searchInput});
            // Dispatches the event.
            this.dispatchEvent(selectedPicklistEvent); 
        }
        return !this.showError;
    }

    
}