import { LightningElement, wire, track } from 'lwc';
import { reduceErrors, showToast } from 'c/utility'; 
import { loadStyle, loadScript} from "lightning/platformResourceLoader";
import { EnclosingTabId, setTabLabel, setTabIcon } from 'lightning/platformWorkspaceApi';
import LightningConfirm from 'lightning/confirm';
import overrideClass from '@salesforce/resourceUrl/OverrideClass'
import sheetJS from '@salesforce/resourceUrl/SheetJS' 
import saveRecords from '@salesforce/apex/ProjectWithMilestonesAndItemsController.saveRecords';

const deleteAction = { label: 'Delete', name: 'delete' };

const milestonesColumns = [
    {label: 'Name', fieldName: 'Name', type: 'text', sortable: true}, 
    {label: 'Status', fieldName: 'Status', type: 'text',},
    {type: 'action', typeAttributes: {rowActions: [deleteAction]}}
];

const itemsColumns = [
    {label: 'Name', fieldName: 'Name', type: 'text'}, 
    {label: 'Status', fieldName: 'Status__c', type: 'text'},
    {type: 'action', typeAttributes: {rowActions: [deleteAction]}}
];

const filter = {criteria:[{fieldPath:'IsActive',operator:'eq',value:true}]};

export default class NewProjectWithMilestonesAndItems extends LightningElement {
    milestonesColumns = milestonesColumns;
    itemsColumns = itemsColumns;
    filter = filter;
    sheetJS;
    spinner = false;
    openModalItems = false;
    @track listMilestones = new Array();
    project = {sobjectType : 'Project__c', Name : null, Status__c : 'Not Started'};
    milestone = {Name : '',Status : 'Not Started'};
    currentStep = 'step1';
    headerText = 'Project Details';
    isStep1 = true;
    isStep2 = false;
    isStep3 = false;
    cantProceed = true;
    cantAddMilestone = true;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;
    
    @wire(EnclosingTabId) enclosingTabId;

    renderedCallback(){
        //Loads a external css class
        loadStyle(this, overrideClass);
    }

    connectedCallback(){
        //Loads a library to work with xlsx files
        loadScript(this,sheetJS)
        .then(() => {
            this.sheetJS = XLSX;
        }).catch(error => {
            showToast('error', reduceErrors(error).join(' / '), this);
        });

        //in case a Console App is being used, so the tab does not stays showing "loading"
        if(this.enclosingTabId) {
            setTabLabel(this.enclosingTabId, 'New Project');
            setTabIcon(this.enclosingTabId, 'custom:custom41');
        }
    }

    get showBack(){
        return !this.isStep1;
    }

    get canReturn(){
        return !this.isStep2 && !this.isStep3;
    }

    get showNext(){
        return !this.isStep3;
    }

    get canSave(){
        return this.isStep3;
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSortMilestones(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.listMilestones];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.listMilestones = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    handleBack(){
        if(this.isStep2){
            this.currentStep = 'step1'; 
            this.headerText = 'Project details'
            this.isStep1 = true;
            this.isStep2 = false;
            this.checkCanProceed();
        }
        else if(this.isStep3){
            this.currentStep = 'step2';
            this.headerText = 'Milestones details'
            this.isStep2 = true;
            this.isStep3 = false;
            this.checkCanProceed();
        }
    }

    handleNext(){
        if(this.isStep1){
            this.currentStep = 'step2'; 
            this.headerText = 'Milestones details'
            this.isStep2 = true;
            this.isStep1 = false;
            this.checkCanProceed();
        }
        else if(this.isStep2){
            this.currentStep = 'step3';
            this.headerText = 'To-do Items details'
            this.isStep3 = true;
            this.isStep2 = false;
            this.checkCanProceed();
        }
    }

    handleUserChange(event){
        this.spinner = true;

        if(event.detail.recordId && event.detail.recordId.length > 0){
            this.project.OwnerId = event.detail.recordId;
        }
        else{
            this.project.OwnerId = null;
        }

        this.checkCanProceed();

        this.spinner = false;
    }

    handleProjectInputChange(event){
        this.spinner = true; 

        const value = event.detail.value || event.detail.checked;
        const fieldName = event.currentTarget.name;
        this.project[fieldName] = value;

        this.checkCanProceed();

        this.spinner = false; 
    }

    handleInputMilestoneChange(event){
        this.spinner = true; 

        const value = event.detail.value || event.detail.checked;
        const fieldName = event.currentTarget.name;
        this.milestone[fieldName] = value;

        this.checkCanProceed();

        if(this.milestone.Name) this.cantAddMilestone = false;
        else this.cantAddMilestone = true;

        this.spinner = false; 
    }

    checkCanProceed(){
        if(this.isStep1){
            if(this.project.Name) this.cantProceed = false;
            else this.cantProceed = true;
        }

        if(this.isStep2){
            if(this.listMilestones && this.listMilestones.length > 0) this.cantProceed = false;
            else this.cantProceed = true;
        }
    }

    handleAddMilestone(){
        this.listMilestones = [...this.listMilestones, this.milestone];
        this.milestone = {Name : '',Status : 'Not Started'};
        this.cantAddMilestone = true;

        this.reorderMilestoneIndexes(this.listMilestones);
        this.checkCanProceed();
    }

    handleAddItem(event){
        const index = event.currentTarget.dataset.index;
        const value = this.template.querySelector('[data-id="'+index+'"]').value;
        let currentMilestonesList = this.listMilestones;
        let currentItemsList = currentMilestonesList[index].listItems || new Array();
        let newItem = {sobjectType : 'TodoItem__c', Name : value, Status__c : 'Not Started', parentIndex : index};

        currentItemsList = [...currentItemsList, newItem];
        this.reorderItemsIndexes(currentItemsList);
        currentMilestonesList[index].listItems = currentItemsList;
        this.listMilestones = currentMilestonesList;
    }

    reorderMilestoneIndexes(listMilestones){
        let index = 0;
        listMilestones.forEach(function(milestone){
            milestone.key = index;
            index++;
        });
    }

    reorderItemsIndexes(listItems){
        let index = 0;
        listItems.forEach(function(item){
            item.key = index;
            index++;
        });
    }

    downloadTemplate(){
        this.spinner = true;
        const sheetName = 'Milestones';
        const ws_data = [['Milestone Name'],['Name Sample']];
    
        try {
            let wb = this.sheetJS.utils.book_new();
            wb.SheetNames.push(sheetName);
            const ws = this.sheetJS.utils.aoa_to_sheet(ws_data);
    
            wb.Sheets[sheetName] = ws;
    
            const u8 = this.sheetJS.write(wb, { type: "array", bookType: "xlsx" });
            const blob = new Blob([u8], {type:"application/octet-stream"});
            const url = URL.createObjectURL(blob);
            let hiddenElement = document.createElement("a");
            hiddenElement.download = "milestoneTemplate.xlsx";
            hiddenElement.href = url;
            hiddenElement.target = '_blank'
            hiddenElement.click();
        } 
        catch(error){
            showToast('error', error.message, this);
        } 
        finally{
            this.spinner = false;
        }
    }

    handleMilestoneFileChange(event){
        this.spinner = true;
        let file = event.target.files[0];
        let reader  = new FileReader();
        let self = this;
        let listImportedMilestones = new Array();

        reader.onload = function(e) {
            let fileContent = e.target.result;
            let base64 = 'base64,';
            let dataStart = fileContent.indexOf(base64) + base64.length;
            fileContent = fileContent.substring(dataStart);

            const wb = self.sheetJS.read(fileContent);
            var first_sheet = wb.Sheets[wb.SheetNames[0]];
            const csvTextContent = self.sheetJS.utils.sheet_to_csv(first_sheet, { FS: ';'});
            let listLines = csvTextContent.split('\n');

            if(listLines[0] != 'Milestone Name'){
                showToast('error', ('The file does not contain the necessary header: "Milestone Name".'), this);
                this.spinner = false;
                return;
            }

            listLines.shift();

            if(listLines.length == 0){
                showToast('error', ('File does not contain data.'), this);
                this.spinner = false;
                return;
            }

            listLines.forEach((line) => {
                if(!line || line.trim().length == 0 || !line.split(';')[0]) return;
                listImportedMilestones.push({Name : line, Status : 'Not Started'});
            });

            self.listMilestones = self.listMilestones.concat(listImportedMilestones);
            self.reorderMilestoneIndexes(self.listMilestones);
            self.checkCanProceed();
            self.spinner = false;
        }
        reader.readAsDataURL(file);
    }

    handleCancel(){
        window.open('/lightning/o/Project__c/list?filterName=__Recent', "_parent");
    }

    async handleSave(){
        let project = this.project;
        let listMilestones = this.listMilestones;
        let listMilestonesWithoutItems = new Array();
        let proceed = false;

        listMilestones.forEach((milestone) => {
            if(!milestone.listItems || milestone.listItems.length == 0){
                listMilestonesWithoutItems.push(milestone.Name);
            }
        });

        if(listMilestonesWithoutItems.length > 0){
            proceed = await LightningConfirm.open({message: "", label: 'The '+(listMilestonesWithoutItems.length == 1 ? 'Milestone' : 'Milestones')+ ' "'+listMilestonesWithoutItems.join(', ')+'" does not contain any items. Do you want to proceed anyway?', theme: "warning"});
        }

        if(proceed || listMilestonesWithoutItems.length == 0){
            this.spinner = true;
            saveRecords({"project" : project, "listMilestones" : listMilestones})
            .then((projectId) => {
                showToast('success', 'Project created successfully!', this);

                window.open('/' + projectId, "_parent");
            })
            .catch(error => {
                showToast('error', reduceErrors(error).join(' / '), this);
                console.error(error);
                this.spinner = false;
            })
        }
    }

    async handleRowActionMilestone(event){
        const result = await LightningConfirm.open({message: "", label: 'Are you sure you want to delete this Milestone?', theme: "warning"});

        if(result){
            this.listMilestones = this.listMilestones.filter(element => element.key != event.detail.row.key);
            
            this.reorderMilestoneIndexes(this.listMilestones);
            this.checkCanProceed();
        }  
    }

    async handleRowActionItem(event){
        const result = await LightningConfirm.open({message: "", label: 'Are you sure you want to delete this Item?', theme: "warning"});
        const row = event.detail.row;
        const index = row.parentIndex;

        if(result){
            this.listMilestones[index].listItems = this.listMilestones[index].listItems.filter(element => element.key != event.detail.row.key);

            this.reorderItemsIndexes(this.listMilestones[index].listItems);
        }  
    }

    get isStep1(){
        return this.currentStep === 'step1';
    }

    get isStep2(){
        return this.currentStep === 'step2';
    }

    get isStep3(){
        return this.currentStep === 'step3';
    }
}