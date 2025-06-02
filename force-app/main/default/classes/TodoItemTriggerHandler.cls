public with sharing class TodoItemTriggerHandler {
    
    public static void updateMilestoneStatus(List<TodoItem__c> listItems, Map<Id,TodoItem__c> oldMap){
        List<TodoItem__c> listItemsToCheck = new List<TodoItem__c>();
        List<Milestone__c> listMilestonesToUpdate = new List<Milestone__c>();
        Set<String> setIdsMilestones = new Set<String>();
        Set<String> setIdsItemsDisconsider = new Set<String>();
        Boolean hasCompleted = false;
        Boolean hasStarted = false;
        Boolean hasNotInitiated = false;
        Milestone__c milestoneToUpdate = new Milestone__c();
        
        for(TodoItem__c item : listItems){
            //Check the item only if the status was changed, or the item is new, or the item was deleted or the item was undeleted
            if(oldMap == null || item.Status__c != oldMap.get(item.id).Status__c){
                listItemsToCheck.add(item);
                setIdsMilestones.add(item.Milestone__c);
                if(Trigger.isDelete) setIdsItemsDisconsider.add(item.id);
            }
        }
        
        if(listItemsToCheck.size() > 0){
            for(Milestone__c milestone : [SELECT Id, Status__c, (SELECT Id, Status__c FROM TodoItems__r WHERE Id NOT IN :setIdsItemsDisconsider) FROM Milestone__c WHERE Id IN :setIdsMilestones WITH SECURITY_ENFORCED]){
                hasCompleted = false;
                hasStarted = false;
                hasNotInitiated = false;
                milestoneToUpdate = new Milestone__c(id = milestone.id);
                
                for(TodoItem__c item : milestone.TodoItems__r){
                    if(item.Status__c == 'Complete') hasCompleted = true;
                    else if(item.Status__c == 'In Progress') hasStarted = true;
                    else hasNotInitiated = true;
                }
                
                if(hasCompleted && !hasStarted && !hasNotInitiated) milestoneToUpdate.Status__c = 'Complete';
                else if(hasStarted || hasCompleted) milestoneToUpdate.Status__c = 'In Progress';
                else milestoneToUpdate.Status__c = 'Not Started	';
                                
                //There is no need to update the Milestone if the Status is still correct
                if(milestone.Status__c != milestoneToUpdate.Status__c) listMilestonesToUpdate.add(milestoneToUpdate);
            }
            
            if(listMilestonesToUpdate.size() > 0) UPDATE as USER listMilestonesToUpdate;
        }
    }

}