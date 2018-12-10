public with sharing class PartnerTierCommunityController {
    
    @AuraEnabled
    public static List<ChannelProgramMember> getPartnerMembers() {
        String userId = UserInfo.getUserId();
        User user = [SELECT AccountId FROM User WHERE Id =: userId];
        List<ChannelProgramMember> partnerProgramMembers = new List<ChannelProgramMember>();
        
        if (user.AccountId != null) {
            List<string> fields = new List<string> {
                'Id',
                'LevelId',
                'PartnerId',
                'ProgramId',
                'Points_To_Next_Level__c',
                'Total_Partner_Points__c'
                };
                        
            boolean isAccessible = FLSCheck.checkFLS(ChannelProgramMember.sObjectType.getDescribe(), fields, 'Read');
            if (isAccessible) {
                partnerProgramMembers = 
                    [SELECT Id,
                     LevelId,
                     PartnerId,
                     ProgramId,
                     Points_To_Next_Level__c,
                     Total_Partner_Points__c,
                     Program.Name,
                     Level.Name,
                     Level.Icon_URL__c,
                     Level.Benefits__c,
                     Level.Next_Level__r.Name,
                     Level.Next_Level__r.Benefits__c,
                     Level.Next_Level__r.Minimum_Points__c
                     FROM ChannelProgramMember
                     WHERE PartnerId =: user.AccountId
                     ORDER BY Program.Name];
            }
            return partnerProgramMembers;
        }
        else {
            return null;
        }
    }
    
    @AuraEnabled
    public static List<Partner_Level_Requirement__c> getLevelRequirements(String levelId) {
        List<Partner_Level_Requirement__c> results = new List<Partner_Level_Requirement__c>();
        
        List<string> fields = new List<string> {'Id',
                								'Name',
                                                'Partner_Activity_Type__c',
                                                'Minimum_Point_Requirement__c'};
            
        boolean isAccessible = FLSCheck.checkFLS(Partner_Level_Requirement__c.sObjectType.getDescribe(), fields, 'Read');
        if (isAccessible) {
            results = [SELECT Id,
                       Name,
                       Partner_Activity_Type__c,
                       Partner_Activity_Type__r.Name,
                       Minimum_Point_Requirement__c
                       FROM Partner_Level_Requirement__c
                       WHERE Channel_Program_Level__c = :levelId
                      ];
        }
        return results;
    }
    
    @AuraEnabled
    public static Map<Id, Integer> getMemberPointsByType (String memberId) {
        List<string> fields = new List<string> {'PartnerId',
            									'ProgramId'};
                
        boolean isAccessible = FLSCheck.checkFLS(ChannelProgramMember.sObjectType.getDescribe(), fields, 'Read');
        system.debug(isAccessible);
        if (isAccessible) {
            ChannelProgramMember member = [SELECT PartnerId, ProgramId FROM ChannelProgramMember WHERE Id =: memberId];
            return PartnerProgramLevelCalculation.getPointTypeMap(member.PartnerId, member.ProgramId);
        }
        else {
            return null;
        }
    }
    
    @AuraEnabled
    public static List<Program_Level_Activity_Point_Association__c> getFeaturedActivityTypes(String levelId) {
        List<Program_Level_Activity_Point_Association__c> results = new List<Program_Level_Activity_Point_Association__c>();
        
        List<string> fields = new List<string> {'Id',
                								'Points__c',
                                                'Partner_Activity_Type__c'};
            
        boolean isAccessible = FLSCheck.checkFLS(Program_Level_Activity_Point_Association__c.sObjectType.getDescribe(), fields, 'Read');
        if (isAccessible) {
        results = [SELECT Id,
                   Points__c,
                   Partner_Activity_Type__r.Name,
                   Partner_Activity_Type__r.Category__c,
                   Partner_Activity_Type__r.Category_Icon_URL__c
                   FROM Program_Level_Activity_Point_Association__c
                   WHERE Channel_Program_Level__c = :levelId
                   AND Featured__c = true];
        }
        return results;
    }
    
    @AuraEnabled
    public static List<Partner_Activity__c> getActivities(String memberId) {
        List<Partner_Activity__c> results = new List<Partner_Activity__c>();
        
        List<string> fields = new List<string> {'PartnerId',
            									'ProgramId'};
                
        boolean isAccessible = FLSCheck.checkFLS(ChannelProgramMember.sObjectType.getDescribe(), fields, 'Read');
        if (isAccessible) {
        ChannelProgramMember member = [SELECT PartnerId, ProgramId FROM ChannelProgramMember WHERE Id =: memberId];
        results = PartnerProgramLevelCalculation.getActivities(member.PartnerId, member.ProgramId);
        }
        return results;
    }
}