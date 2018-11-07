@isTest
public class PartnerProgramLevelCalculationTest {

    @TestSetup
    static void setup() {
        User communityUser = new User();
        communityUser.FirstName = 'Test';
        communityUser.LastName = 'Class';

        Id profileId = [select id from profile where name='Partner Community User'].id;

        communityUser.Username = 'testClass@partnertier.dev';
        communityUser.Email = 'test@class.test';
        communityUser.Alias = 'tclass';
        communityUser.CommunityNickname = 'tclass';
        communityUser.TimeZoneSidKey = UserInfo.getTimeZone().getID();
        communityUser.LocaleSidKey = UserInfo.getLocale();
        communityUser.EmailEncodingKey = 'ISO-8859-1';
        communityUser.ProfileId = profileId;
        communityUser.LanguageLocaleKey = UserInfo.getLanguage();

        Account account = new Account();
        account.Name = 'Test Class Account';
        account.OwnerId = UserInfo.getUserId();

        insert account;

        Contact contact = new Contact();
        contact.AccountId = account.Id;
        contact.FirstName = communityUser.FirstName;
        contact.LastName = communityUser.LastName;

        insert contact;

        communityUser.ContactId = contact.Id;
        insert communityUser;
        
        ChannelProgram program = new ChannelProgram();
        program.Name = 'Test Program';
        program.IsActive = true;
        insert program;

        ChannelProgramLevel silver = new ChannelProgramLevel(Name = 'Silver');
        silver.Minimum_Points__c = 50;
        silver.ProgramId = program.Id;
        insert silver;

        ChannelProgramLevel bronze = new ChannelProgramLevel(Name = 'Bronze');
        bronze.Minimum_Points__c = 0;
        bronze.Next_Level__c = silver.Id;
        bronze.ProgramId = program.Id;
        insert bronze;
        
        ChannelProgramMember member = new ChannelProgramMember();
        member.PartnerId = account.Id;
        member.ProgramId = program.Id;
        member.LevelId = bronze.Id;
        member.Total_Partner_Points__c = bronze.Minimum_Points__c;
        insert member;

        Partner_Activity_Type__c type1 = new Partner_Activity_Type__c(Name = 'Type 1');
        type1.Points__c = 20;
        insert type1;

        Partner_Activity_Type__c type2 = new Partner_Activity_Type__c(Name = 'Type 2');
        type2.Points__c = 10;
        insert type2;

        Partner_Level_Requirement__c requirement = new Partner_Level_Requirement__c();
        requirement.Channel_Program_Level__c = silver.Id;
        requirement.Partner_Activity_Type__c = type2.Id;
        requirement.Minimum_Point_Requirement__c = 20;
        insert requirement;
        
        Program_Level_Activity_Point_Association__c activityPointAssoc = new Program_Level_Activity_Point_Association__c();
        activityPointAssoc.Channel_Program_Level__c = bronze.Id;
        activityPointAssoc.Partner_Activity_Type__c = type1.Id;
        activityPointAssoc.Points__c = 5;
        activityPointAssoc.Featured__c = true;
        insert activityPointAssoc;
        
        Partner_Activity__c activity1 = new Partner_Activity__c();
        activity1.Activity_Date__c = Date.today();
        activity1.Partner_Activity_Type__c = type1.Id;
        activity1.Partner_Account__c = account.Id;
        activity1.Channel_Program__c = program.Id;
        insert activity1; // 5 points from the PP Association
        
        Partner_Activity__c activity2 = new Partner_Activity__c();
        activity2.Activity_Date__c = Date.today();
        activity2.Partner_Activity_Type__c = type2.Id;
        activity2.Partner_Account__c = account.Id;
        activity2.Channel_Program__c = program.Id;
        insert activity2; // 10 points by default
        
        Partner_Activity__c activity3 = new Partner_Activity__c();
        activity3.Activity_Date__c = Date.today();
        activity3.Partner_Activity_Type__c = type1.Id;
        activity3.Partner_Account__c = account.Id;
        activity3.Channel_Program__c = program.Id;
        activity3.Points_Awarded__c = 10;
        insert activity3; // 10 points from set points
        
        activity3.Points_Awarded__c = 15;
        update activity3; // 15 points from set points
        System.assertEquals(15, activity3.Points_Awarded__c);
    }

    @isTest
    static void getAllMembersTest() {
        ChannelProgramMember member = [SELECT Id FROM ChannelProgramMember];
        ChannelProgramLevel bronze = [SELECT Id FROM ChannelProgramLevel WHERE Name = 'Bronze'];

        List<ChannelProgramMember> members = PartnerProgramLevelCalculation.getAllMembers(new List<Id> {member.Id});
        System.assertEquals(1, members.size());

        System.assertEquals(30, members[0].Total_Partner_Points__c);
        System.assertEquals(bronze.Id, members[0].levelId);
    }

    @isTest
    static void getAllProgramLevelsTest() {
        ChannelProgram program = [SELECT Id FROM ChannelProgram];
        List<ChannelProgramLevel> levels = PartnerProgramLevelCalculation.getAllProgramLevels(program.Id);
        System.assertEquals(2, levels.size());
    }

    @isTest
    static void getPointTypeMapTest() {
        Account account = [SELECT Id FROM Account];
        ChannelProgram program = [SELECT Id FROM ChannelProgram];
        List<Partner_Activity__c> activities = [SELECT Partner_Activity_Type__c, Points_Awarded__c FROM Partner_Activity__c];
        Partner_Activity_Type__c type1 = [SELECT Id FROM Partner_Activity_Type__c WHERE Name = 'Type 1'];
        Partner_Activity_Type__c type2 = [SELECT Id FROM Partner_Activity_Type__c WHERE Name = 'Type 2'];

        Map<Id,Integer> pointTypeMap = PartnerProgramLevelCalculation.getPointTypeMap(account.Id, program.Id);
        System.assertEquals(2, pointTypeMap.size());
        System.assertEquals(20, pointTypeMap.get(type1.Id));
        System.assertEquals(10, pointTypeMap.get(type2.Id));
    }

    @isTest
    static void UpdatePartnerTierLevelTest() {
        Account account = [SELECT Id FROM Account];
        ChannelProgram program = [SELECT Id FROM ChannelProgram];
        ChannelProgramMember member = [SELECT Id, LevelId, Pending_Level__c, Total_Partner_Points__c FROM ChannelProgramMember WHERE PartnerId = :account.Id AND ProgramId = :program.Id];
        Partner_Activity_Type__c type1 = [SELECT Id FROM Partner_Activity_Type__c WHERE Name = 'Type 1'];
        Partner_Activity_Type__c type2 = [SELECT Id FROM Partner_Activity_Type__c WHERE Name = 'Type 2'];
        ChannelProgramLevel bronze = [SELECT Id, Name FROM ChannelProgramLevel WHERE Name = 'Bronze'];
        ChannelProgramLevel silver = [SELECT Id, Name FROM ChannelProgramLevel WHERE Name = 'Silver'];

        System.assertEquals(30, member.Total_Partner_Points__c);
        
        Partner_Activity__c activity = new Partner_Activity__c();
        activity.Activity_Date__c = Date.today();
        activity.Partner_Activity_Type__c = type1.Id;
        activity.Partner_Account__c = account.Id;
        activity.Channel_Program__c = program.Id;
        insert activity; // 5 points

        //PartnerProgramLevelCalculation.UpdatePartnerProgramLevel(new List<Id> {member.Id});

        //member = [SELECT Id, LevelId, Pending_Level__c FROM ChannelProgramMember];
        System.assertEquals(bronze.Id, member.LevelId);
        System.assert(member.Pending_Level__c == null);

        Partner_Activity__c activity2 = new Partner_Activity__c();
        activity2.Activity_Date__c = Date.today();
        activity2.Partner_Activity_Type__c = type2.Id;
        activity2.Partner_Account__c = account.Id;
        activity2.Channel_Program__c = program.Id;
        insert activity2; // 10 points
        
        Partner_Activity__c activity3 = new Partner_Activity__c();
        activity3.Activity_Date__c = Date.today();
        activity3.Partner_Activity_Type__c = type2.Id;
        activity3.Partner_Account__c = account.Id;
        activity3.Channel_Program__c = program.Id;
        activity3.Points_Awarded__c = 100;
        insert activity3; // 100 points
        
        member = [SELECT Id, LevelId, Pending_Level__c, Total_Partner_Points__c FROM ChannelProgramMember];
        System.assertEquals(145, member.Total_Partner_Points__c);
        System.assertEquals(silver.Id, member.LevelId);
        System.assert(member.Pending_Level__c == null);

        //delete activity;
        //delete activity2;
        
        Partner_Activity__c activity4 = new Partner_Activity__c();
        activity4.Activity_Date__c = Date.today();
        activity4.Partner_Activity_Type__c = type2.Id;
        activity4.Partner_Account__c = account.Id;
        activity4.Channel_Program__c = program.Id;
        activity4.Points_Awarded__c = -100;
        insert activity4;
        
        delete activity;
		
        member = [SELECT Id, Level.Name, Pending_Level__c, Total_Partner_Points__c FROM ChannelProgramMember];
        System.assertEquals(40, member.Total_Partner_Points__c);
        System.assertEquals(silver.Name, member.Level.Name);
        System.assertEquals(bronze.Id, member.Pending_Level__c);
		
        
    }
}