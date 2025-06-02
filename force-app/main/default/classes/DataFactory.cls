@isTest
public class DataFactory {

    public static Project__c createProject(){	
        Project__c proj = new Project__c();
        proj.Name = 'teste';
        proj.Status__c = 'Not Started';
        
        return proj;
    }
    
    public static Milestone__c createMilestone(String projectId){	
        Milestone__c miles = new Milestone__c();
        miles.Name = 'teste';
        miles.Status__c = 'Not Started';
        miles.Project__C = projectId;
        
        return miles;
    }
    
    public static TodoItem__c createItem(String milestoneId){	
        TodoItem__c item = new TodoItem__c();
        item.Name = 'teste';
        item.Status__c = 'Not Started';
        item.Milestone__c = milestoneId;
        
        return item;
    }
    
}