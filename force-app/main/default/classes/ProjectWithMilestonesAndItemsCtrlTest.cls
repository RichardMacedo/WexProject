@isTest
public class ProjectWithMilestonesAndItemsCtrlTest {

    @isTest
    public static void saveRecordsTest(){
        String projectJson = '{"sobjectType":"Project__c","Name":"project test","Status__c":"Not Started"}';
        String milestoneJson = '[{"Name":"milestone 1","Status":"Not Started","key":0,"listItems":[{"sobjectType":"TodoItem__c","Name":"item 11","Status__c":"Not Started","parentIndex":"0","key":0},{"sobjectType":"TodoItem__c","Name":"item 12","Status__c":"Not Started","parentIndex":"0","key":1}]},{"Name":"milestone 2","Status":"Not Started","key":1,"listItems":[{"sobjectType":"TodoItem__c","Name":"21","Status__c":"Not Started","parentIndex":"1","key":0},{"sobjectType":"TodoItem__c","Name":"22","Status__c":"Not Started","parentIndex":"1","key":1}]}]';
        
        Project__c project = (Project__c) JSON.deserialize(projectJson, Project__c.class);
        List<ProjectWithMilestonesAndItemsController.Milestone> listMilestones = (List<ProjectWithMilestonesAndItemsController.Milestone>) JSON.deserialize(milestoneJson, List<ProjectWithMilestonesAndItemsController.Milestone>.class);
        
        Test.startTest();
        ProjectWithMilestonesAndItemsController.saveRecords(project, listMilestones);
        
        Project__c proj = [SELECT Id, Status__c FROM Project__c];
        Assert.areEqual(project.Id, proj.Id, 'Check if the Project record was created');
        
        List<Milestone__c> listMilestonesCreated = [SELECT Id FROM Milestone__c];
        Assert.areEqual(listMilestonesCreated.size(), 2, 'Check if 2 Milestones were created');
        
        List<TodoItem__c> listItemsCreated = [SELECT Id FROM TodoItem__c];
        Assert.areEqual(listItemsCreated.size(), 4, 'Check if 4 TodoItems were created');
        Test.stopTest();
    }
    
}