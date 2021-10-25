import { LightningElement, track, api, wire } from 'lwc';
import getReport from '@salesforce/apex/LSC_CouncilImportController.getReport';
import { getRecord } from 'lightning/uiRecordApi';

const fields = [
    'Account.LSC_EntityTypeName__c',
    'Account.Name'
];

const rowHeaderMap = {'type' : 'Application Type', 'no' : 'Application Number', 'cost': 'Cost Of Works',  
                      'payable' : 'Levy Payable', 'paid' : 'Paid Amount', 
                      'comment' : 'Comment', 'reason' : 'Reason'};

const rowHeaderOrder = ['Application Type', 'Application Number', 'Cost Of Works', 'Levy Payable','Paid Amount', 'Comment', 'Reason'];                      

export default class CouncilReport extends LightningElement {
    @api recordId;
    type;
    year;
    month;
    name;
    data = [];

    handleChange(event){
        this[event.target.name] = event.target.value;
    } 

    get hasData() {
        return this.data.length > 0;
    }

    get period() {
        if(this.month < 10) {
            return '0' + this.month.toString() + '.' + this.year.toString();
        }
        else {
            return this.month.toString() + '.' + this.year.toString();
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: fields })
    wireAccount({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.type = data.fields.LSC_EntityTypeName__c.value;
            this.name = data.fields.Name.value;
        }
    }

    get isRendered() {
        if(this.type === 'Council') return true;
        return false;
    }

    get monthOptions() {
        return [
            { label: 'January', value: '1' },
            { label: 'February', value: '2' },
            { label: 'March', value: '3' },
            { label: 'April', value: '4' },
            { label: 'May', value: '5' },
            { label: 'June', value: '6' },
            { label: 'July', value: '7' },
            { label: 'August', value: '8' },
            { label: 'September', value: '9' },
            { label: 'October', value: '10' },
            { label: 'November', value: '11' },
            { label: 'December', value: '12' },                  
        ]
    }

    get yearOptions() {
        let curYear = new Date().getFullYear();
        return [
            { label: (curYear-4).toString(), value: (curYear-4).toString() },             
            { label: (curYear-3).toString(), value: (curYear-3).toString() }, 
            { label: (curYear-2).toString(), value: (curYear-2).toString() }, 
            { label: (curYear-1).toString(), value: (curYear-1).toString() },            
            { label: curYear.toString(), value: curYear.toString() }                            
        ]
    }    
    
    // this method validates the data and creates the csv file to download
    downloadCSVFile() {   
        let rowEnd = '\n';
        let csvString = '';
        // this set elminates the duplicates if have any duplicate keys
        let rowData = new Set();
        let rowHeader = new Set();

        // getting keys from data
        this.data.forEach(function (record) {
            Object.keys(record).forEach(function (key) {
                // exclude id column
                if(key != 'id') {
                    rowData.add(key);
                    rowHeader.add(rowHeaderMap[key]); //for display purposes
                }
            });
        });

        // Array.from() method returns an Array object from any object with a length property or an iterable object.
        rowData = Array.from(rowData);
        rowHeader = Array.from(rowHeader);
        //Sort the columns in table
        rowData.sort(function (a,b){
            return rowHeaderOrder.indexOf(rowHeaderMap[a]) - rowHeaderOrder.indexOf(rowHeaderMap[b]);
        });
        rowHeader.sort(function (a,b){
            return rowHeaderOrder.indexOf(a) - rowHeaderOrder.indexOf(b);
        });        
        
        // splitting using ','
        csvString += rowHeader.join(',');
        csvString += rowEnd;

        // main for loop to get the data based on key value
        for(let i=0; i < this.data.length; i++){
            let colValue = 0;
            // validating keys in data
            for(let key in rowData) {
                if(rowData.hasOwnProperty(key)) {
                    // Key value 
                    // Ex: Id, Name
                    let rowKey = rowData[key];
                    // add , after every value except the first.
                    if(colValue > 0){
                        csvString += ',';
                    }
                    // If the column is undefined, it as blank in the CSV file.
                    let value = this.data[i][rowKey] === undefined ? '' : this.data[i][rowKey];
                    if(rowKey === 'cost' || rowKey === 'payable' || rowKey === 'paid'){
                        value = '$'+parseFloat(value).toFixed(2)
                    }
                    csvString += '"'+ value +'"';
                    colValue++;
                }
            }
            csvString += rowEnd;
        }

        // Creating anchor element to download
        let downloadElement = document.createElement('a');

        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        // CSV File Name
        downloadElement.download = this.name+' Report '+this.period+'.csv'//'Account Data.csv';
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click(); 
    }

    handleGet(){
        const allValid = [...this.template.querySelectorAll('lightning-combobox, lightning-input, lightning-textarea')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {
            getReport({recordId : this.recordId, year : this.year, month: this.month})
            .then(result => {
                console.log(result);
                this.data = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title : 'Error',
                        message : error,
                        variant : 'error',
                    })
                )
            })
        }
    }
 
}