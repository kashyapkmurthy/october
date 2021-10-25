import { LightningElement, api } from 'lwc';
import fetchAddressList from '@salesforce/apexContinuation/LSC_FetchAddressService.startContinuation';
import fetchAddressDetails from '@salesforce/apexContinuation/LSC_FetchAddressDetailService.startAddressContinuation';

const UP_KEY = 38;
const DWN_KEY = 40;
const ENTR_KEY = 13;

export default class AddressSearch extends LightningElement {
    @api addressLabel = "";
    @api addressParameters = "";
    @api addressType;
    streetAddress="";
    suburb="";
    postcode="";
    state="";
    initialized = false;
    showLookupAddress = false;
    autocompleteAddress = true;
    buttonLabel = 'Manually enter address';
    value = ''; 
    minLength = 4;
    @api addressDetails="";
    addressList = [];
    allInputs = {};
    postcode ="";
    addrIdMap = [];
    focusIndex = -1;
    error="";
    showResults = false;
    fetchingDetails = false;

    connectedCallback(){
        console.log('In address search connected callback');
        
        if(this.addressParameters){
            if(this.addressParameters.autoAddress){
                this.autocompleteAddress = true;
                this.value = this.addressParameters.fullAddress;
            }
            else{
                this.streetAddress = this.addressParameters.street;
                this.suburb = this.addressParameters.suburb;
                this.postcode = this.addressParameters.postcode;
                this.autocompleteAddress = false;
                this.state = this.addressParameters.state;
            }
            this.buttonLabel = this.autocompleteAddress? 'Manually enter address': 'Use auto address lookup';
        } 
    }

    onBlur(event){
        const id = this.getId(event.target.id);
        let value = event.target.value;
        let errMess = "";
        switch(id){
            case 'addressSearch':
                if(!value){
                    errMess = "Please enter "+this.addressLabel.replace(/ .*/, '').toLowerCase()+" address";
                }
                break;
            case 'saStreetAddr':
                const streetValid = /^[a-zA-Z0-9-/,& -]*$/g;
                if(!streetValid.test(value))
                    errMess = "Please enter valid street name";
                break;
            case 'saPostcode':
                this.postcode = value;
                break;
            case 'saSuburb':
                const suburbValid = /^[a-zA-Z-/,& -]*$/g;
                if(!suburbValid.test(value))
                    errMess = "Please enter valid suburb name";
                break;
            case 'saState':
                this.state = value;
                break;
        }
        this.setInputValidity(event.target, errMess);
    }


    get statePicklist(){
        return [
            {label: 'NSW', value: 'NSW'},
            {label: 'VIC', value: 'VIC'},
            {label: 'QLD', value: 'QLD'},
            {label: 'SA', value: 'SA'},
            {label: 'WA', value: 'WA'},
            {label: 'NT', value: 'NT'},
            {label: 'TAS', value: 'TAS'}
        ];
    }

    handleClick(){
        console.log('In handle click...'+this.autocompleteAddress);
        //this.showLookupAddress = !this.showLookupAddress;
        this.autocompleteAddress = !this.autocompleteAddress;
        this.buttonLabel = this.autocompleteAddress? 'Manually enter address': 'Use auto address lookup';
    }

    onKeyUp(e){
        console.log( 'onkeyup event which-->'+e.which);
        console.log( 'onkeyup event keyCode-->'+e.keyCode);         
        console.log( 'onkeyup event key-->'+e.key); 
        if(e.key == 'ArrowDown'){
            console.log('In arrow donw');
            if(this.focusIndex === -1 || this.focusIndex === 4){
                console.log(this.focusIndex);
                this.focusIndex = 0;
                this.value = this.addressList[this.focusIndex].address;
            }
            else {
                this.focusIndex++;
                this.value = this.addressList[this.focusIndex].address;
            }
        } else if(e.key == 'ArrowUp'){
            console.log('In arrow up');
            if(this.focusIndex === -1 || this.focusIndex === 0){
                console.log(this.focusIndex);
                this.focusIndex = 4;
                this.value = this.addressList[this.focusIndex].address;
            }
            else {
                this.focusIndex--;
                this.value = this.addressList[this.focusIndex].address;
            }
        }else if(e.key == 'Enter'){
            //clear the error flag as the addressList is available for selection
            this.error = "";
            this.value = this.addressList[this.focusIndex].address;
            this.showResults = false;
            this.focusIndex = -1;
            this.fetchAddressDetails();
        }
        this.setClasstotheSelectedElement();
    }

    setClasstotheSelectedElement(){
        let focusIndex = this.focusIndex;
        this.template.querySelectorAll('a[data-id="addressList"]').forEach(function(element){
            if(parseInt(focusIndex) === parseInt(element.dataset.index)){
                console.log('I am seeting class ');
                element.className = "item-focus";
            }
            else{
                console.log('I am removing class ');
                element.className = "";
            }
        })
    }

    onChange(event){
        console.log('In onchange event');
        let inputLabel = this.addressLabel.toLowerCase();
        //Clear previous errors & values on input change
        this.clearPreviousErrors(event.target);
        // set the search value
        let searchValue = event.target.value;
        // Get the type of address
        let addressType = "all";
        // For construction site address set addressState param to 'NSW'
        let addrState = inputLabel.includes('construction')? 'NSW' : '';

        addressType = ((this.addressType === "Business" && inputLabel.includes('street')) || inputLabel.includes('construction')) ? 'physical' : (this.addressType === "Business" && inputLabel.includes('postal')) ? 'mailing' :  'all';

        if (searchValue && searchValue.length >= 4) { // validate search
            fetchAddressList({addressText : searchValue.trim(), addressType : addressType, addressState : addrState})
            .then(result => {
            if (result) {
                this.addressList = [];
                this.addrIdMap = [];
                for (let i=0; i<result.addresses.length; i++) {
                    this.addressList.push(result.addresses[i]);
                    this.addrIdMap[result.addresses[i].address] = result.addresses[i].id;
                }
                this.showResults = true;
            }})
            .catch(error => {
                console.log('address length...'+this.addressList.length);
                this.error = error;
                console.log('in exception...'+JSON.stringify(error))});
        }
    }

    clearPreviousErrors(input){
        //Reset focus index
        this.focusIndex = -1;
        if(!input.checkValidity()){
            this.setInputValidity(input, "");
        }
        if(this.error) 
            this.error="";
        //Reset values
        if(this.addressList) this.addressList = [];
        this.showResults = false;
        this.value="";
    }

    handleSelection(event) {
        //clear the error flag as the addressList is available for selection
        this.error="";
        const index = event.currentTarget.dataset.index;
        this.value = this.addressList[index].address;
        this.showResults = false;
        this.fetchingDetails = true;
        this.fetchAddressDetails();
    }

    fetchAddressDetails(){
        fetchAddressDetails({addressId : this.addrIdMap[this.value]})
        .then(result => {
            let respResult = JSON.parse(JSON.stringify(result));
            respResult.addressDetails.autoAddress = true;

            this.addressDetails = respResult.addressDetails;
            const addressDetails = new CustomEvent('updateaddrsparameters', {  detail : this.addressDetails});
            // Dispatches the event.
            this.dispatchEvent(addressDetails);   
            this.fetchingDetails = false; 
        });
    }

    get showNoResults() {
        return (this.showResults && this.addressList.length === 0) || this.error;
    }
    
    get showAddrResults() {
        return this.showResults && this.addressList.length > 0;
    }

    getId(id){
        const finalId = (id || "").split("-");
        finalId.pop();
        return finalId.join("-");
    }      
    
    @api
    validateAllFields(){
        console.log('In new add search validate all');
        let result = true;
        this.template.querySelectorAll('lightning-input').forEach(element => {
            this.setInputValidity(element,'');
            if(element.name === "address" && !this.value && !this.showNoResults)
                this.setInputValidity(element, 'Please enter '+this.addressLabel.replace(/ .*/, '').toLowerCase()+' address');
            else if(element.name === "postcode" && element.checkValidity()){
                let numberVal = parseInt(element.value);
                console.log('postocde...'+element.value.length);
                if(element.value.length < 4){
                    this.setInputValidity(element, 'Please enter 4 digits');
                }else if(numberVal < 200 || (numberVal > 299 && numberVal < 800) ||
                        (numberVal > 6797 && numberVal < 6800)){
                    this.setInputValidity(element, 'Please enter valid postcode');
                }

            }
            result &= element.checkValidity();
        });
        //check if no matched address
        result &= !this.showNoResults;
        let statePickInput = this.template.querySelector('lightning-combobox');
        if(statePickInput){
            result &= statePickInput.reportValidity();
            console.log('statPickResult...'+statePickInput.reportValidity());
        }
        //Check if address details are being fetched
        result &= !this.fetchingDetails;
        if(result && !this.autocompleteAddress){
            this.fireManualAddressEvent();
        }
        return result;
    }    

    handleChange(event){
        console.log('handlechange');
        const id = this.getId(event.target.id);
        let value = event.target.value;
        switch(id){
            case 'saStreetAddr':
                this.streetAddress = value;
                break;
            case 'saPostcode':
                this.postcode = value;
                break;
            case 'saSuburb':
                this.suburb = value;
                break;
            case 'saState':
                this.state = value;
                break;
        }
    }

    fireManualAddressEvent(){
        const addressDetails = new CustomEvent('updateaddrsparameters', {  detail : {autoAddress : false, 
            addressId: "",
            city: this.suburb,
            fullAddress: this.streetAddress+', '+this.suburb+' '+this.state+' '+this.postcode,
            suburb: this.suburb,
            postcode: this.postcode,
            state: this.state,
            street: this.streetAddress,
            country:"AU"}});
        // Dispatches the event.
        this.dispatchEvent(addressDetails);  
    }
     
    handlePicklistChange(event){
        this.state = event.target.value;
    }

    setInputValidity(input, message){
        input.setCustomValidity(message);
        input.reportValidity();       
    }    
}