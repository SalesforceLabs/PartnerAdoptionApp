trigger DeleteOrRecalculatePartnerActivity on Partner_Activity__c (before delete, after update) {
    // Trigger used to update the members' total points, added as the total points isn't a roll-up summary anymore
    List<ChannelProgramMember> membersToUpdate = new List<ChannelProgramMember>();
    Set<Id> accIds = new Set<Id>();
    Set<Id> programIds = new Set<Id>();
    
    // When a record is deleted, minus the points before being deleted
    if(Trigger.isDelete) {
        for(Partner_Activity__c pa : Trigger.old) {
         	accIds.add(pa.Partner_Account__c);
            programIds.add(pa.Channel_Program__c);
        }
        
        List<Id> memberIds = new List<Id>();
        List<ChannelProgramMember> members = [SELECT Id, Total_Partner_Points__c, ProgramId, PartnerId
                                              FROM ChannelProgramMember
                                              WHERE PartnerId IN :accIds
                                              AND ProgramId IN :programIds];
        
        for(Partner_Activity__c pa : Trigger.old) {
            for(ChannelProgramMember member : members) {
                if(member != null && 
                   member.ProgramId == pa.Channel_Program__c && 
                   member.PartnerId == pa.Partner_Account__c) {
                       member.Total_Partner_Points__c -= pa.Points_Awarded__c;
                       membersToUpdate.add(member);
                       memberIds.add(member.Id);
                       break;
                   }
            }
        }
        update membersToUpdate;
    }

    // When a record is updated, remove the existing points and add the new points
    if(Trigger.isUpdate) {
        for(Partner_Activity__c pa : Trigger.new) {
         	accIds.add(pa.Partner_Account__c);
            programIds.add(pa.Channel_Program__c);
        }
        
        List<Id> memberIds = new List<Id>();
        List<ChannelProgramMember> members = [SELECT Id, Total_Partner_Points__c, ProgramId, PartnerId
                                              FROM ChannelProgramMember
                                              WHERE PartnerId IN :accIds
                                              AND ProgramId IN :programIds];
        
        for(Partner_Activity__c pa : Trigger.new) {
            if (pa.New_Activity__c == false) {
                for(ChannelProgramMember member : members) {
                    Partner_Activity__c oldActivity = Trigger.oldMap.get(pa.Id);
                    if(member != null && 
                       member.ProgramId == pa.Channel_Program__c && 
                       member.PartnerId == pa.Partner_Account__c &&
                       oldActivity.Points_Awarded__c != pa.Points_Awarded__c &&
                       oldActivity.New_Activity__c == pa.New_Activity__c) {
                           member.Total_Partner_Points__c += pa.Points_Awarded__c; // Add new amount of points
                           member.Total_Partner_Points__c -= oldActivity.Points_Awarded__c; // Remove old amount of points
                           membersToUpdate.add(member);
                           memberIds.add(member.Id);
                           break;
                       }
                }
            }
        }
        update membersToUpdate;
    }
}