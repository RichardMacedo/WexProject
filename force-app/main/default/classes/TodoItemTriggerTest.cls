@isTest
public class TodoItemTriggerTest { 
    
    @TestSetup
    public static void createRecords(){
        TodoItem__c item;
        List<TodoItem__c> listItems = new List<TodoItem__c>();
        
        Project__c proj = DataFactory.createProject();
        insert proj;
        
        Milestone__c miles = DataFactory.createMilestone(proj.Id);
        insert miles;
        
        for(Integer i = 0; i <= 3; i++){
            item = DataFactory.createItem(miles.Id);
            listItems.add(item);
        }
        insert listItems;
    }
    
    @isTest
    private static void updateMilestoneStatusTest(){
        Project__c proj = [SELECT Id, Status__c FROM Project__c];
        Milestone__c miles = [SELECT Id, Status__c FROM Milestone__c WHERE Project__c = :proj.Id];
        List<TodoItem__c> listItems = [SELECT Id, Status__c FROM TodoItem__c WHERE Milestone__c = :miles.Id];
        
        Test.startTest();
        //Scenario 1, starts with "Not Started"
        Assert.areEqual('Not Started', miles.Status__c, 'After the creation of the records, the Milestone Status should be equals to "Not Started", because all Items have the Status equals to "Not Started"');
        
        TodoItem__c item = listItems[0];
        item.Status__c = 'In Progress';
        
        update item;
        miles = [SELECT Id, Status__c FROM Milestone__c WHERE Id = :miles.Id];
        
        //Scenario 2, with at least 1 item with the Status equals to "In Progress"
        Assert.areEqual('In Progress', miles.Status__c, 'After the status change of 1 item to "In Progress", the Milestone Status should be equals to "In Progress"');
        
        delete item;
        miles = [SELECT Id, Status__c FROM Milestone__c WHERE Id = :miles.Id];
        
        //Scenario 3, after the deletion of the 1 item with the Status equals to "In Progress"
        Assert.areEqual('Not Started', miles.Status__c, 'After the deletion of the "In Progress" record, the Milestone Status should be equals to "Not Started" again');
        
        undelete item;
        miles = [SELECT Id, Status__c FROM Milestone__c WHERE Id = :miles.Id];
        
        //Scenario 4, after the restoration of the 1 item with the Status equals to "In Progress"
        Assert.areEqual('In Progress', miles.Status__c, 'After the restauration of the 1 item with status equals to "In Progress", the Milestone Status should be back to "In Progress"');
        
        for(TodoItem__c listItem : listItems){
            listItem.Status__c = 'Complete';
        }
        
        update listItems;
        miles = [SELECT Id, Status__c FROM Milestone__c WHERE Id = :miles.Id];
        
        //Scenario 5, after all items have its Status changed to "Complete"
        Assert.areEqual('Complete', miles.Status__c, 'After all items have its Status changed to "Complete", the Milestone Status should have the Status equals to "Complete"');
        
        Test.stopTest();
    }
    
}