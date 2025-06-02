@isTest
public class MilestoneTriggerTest {
    
    @TestSetup
    public static void createRecords(){
        Milestone__c miles;
        List<Milestone__c> listMilestones = new List<Milestone__c>();
        
        Project__c proj = DataFactory.createProject();
        insert proj;
        
        for(Integer i = 0; i <= 3; i++){
            miles = DataFactory.createMilestone(proj.Id);
            listMilestones.add(miles);
        }
        insert listMilestones;
    }
    
    @isTest
    private static void updateMilestoneStatusTest(){
        Project__c proj = [SELECT Id, Status__c FROM Project__c];
        List<Milestone__c> listMilestones = [SELECT Id, Status__c FROM Milestone__c WHERE Project__c = :proj.Id];
        
        Test.startTest();
        //Scenario 1, starts with "Not Started"
        Assert.areEqual('Not Started', proj.Status__c, 'After the creation of the records, the Project Status should be equals to "Not Started", because all Milestones have the Status equals to "Not Started"');
        
        Milestone__c milestone = listMilestones[0];
        milestone.Status__c = 'In Progress';
        
        update milestone;
        proj = [SELECT Id, Status__c FROM Project__c WHERE Id = :proj.Id];
        
        //Scenario 2, with at least 1 Milestone with the Status equals to "In Progress"
        Assert.areEqual('In Progress', proj.Status__c, 'After the status change of 1 Milestone to "In Progress", the Project Status should be equals to "In Progress"');
        
        delete milestone;
        proj = [SELECT Id, Status__c FROM Project__c WHERE Id = :proj.Id];
        
        //Scenario 3, after the deletion of the 1 Milestone with the Status equals to "In Progress"
        Assert.areEqual('Not Started', proj.Status__c, 'After the deletion of the "In Progress" record, the Project Status should be equals to "Not Started" again');
        
        undelete milestone;
        proj = [SELECT Id, Status__c FROM Project__c WHERE Id = :proj.Id];
        
        //Scenario 4, after the restoration of the 1 Milestone with the Status equals to "In Progress"
        Assert.areEqual('In Progress', proj.Status__c, 'After the restauration of the 1 Milestone with status equals to "In Progress", the Project Status should be back to "In Progress"');
        
        for(Milestone__c listMilestone : listMilestones){
            listMilestone.Status__c = 'Complete';
        }
        
        update listMilestones;
        proj = [SELECT Id, Status__c FROM Project__c WHERE Id = :proj.Id];
        
        //Scenario 5, after all Milestones have its Status changed to "Complete"
        Assert.areEqual('Complete', proj.Status__c, 'After all Milestones have its Status changed to "Complete", the Project Status should have the Status equals to "Complete"');
        
        Test.stopTest();
    }
    
    
}