public with sharing class ProjectWithMilestonesAndItemsController {
    
    @AuraEnabled
    public static String saveRecords(Project__c project, List<Milestone> listMilestones){
        Savepoint sp = Database.setSavepoint();

        try {
            System.debug('project:'+project);
            INSERT as USER project;

            Integer index = 0;
            Map<Integer,List<TodoItem__c>> mapItemsByMilestoneIndex = new Map<Integer,List<TodoItem__c>>();
            List<Milestone__c> listNewMilestones = new List<Milestone__c>();
            List<TodoItem__c> listNewItems = new List<TodoItem__c>();

            for(Milestone miles : listMilestones){
                listNewMilestones.add(new Milestone__c(Status__c = miles.Status, Name = miles.Name, Project__c = project.Id));
                mapItemsByMilestoneIndex.put(index,miles.listItems);
                index ++;
            }

            INSERT as USER listNewMilestones;

            for(integer milestoneIndex : mapItemsByMilestoneIndex.keySet()){
                if(mapItemsByMilestoneIndex.get(milestoneIndex) == null) continue;
                 
                for(TodoItem__c item : mapItemsByMilestoneIndex.get(milestoneIndex)){
                    item.Milestone__c = listNewMilestones[milestoneIndex].Id;
                    listNewItems.add(item);
                }
            }

            INSERT as USER listNewItems;

            return project.Id;
        } catch (Exception e) {
            System.debug('Error: '+e.getMessage() + ' Cause: '+e.getCause() + 'ST: '+e.getStackTraceString());
            Database.rollback(sp); 
            throw new AuraHandledException(e.getMessage());
        }
    }

    @TestVisible
    private class Milestone{
        @AuraEnabled public String Name {get;set;}
        @AuraEnabled public String Status {get;set;}
        @AuraEnabled public List<TodoItem__c> listItems {get;set;}
    }

}