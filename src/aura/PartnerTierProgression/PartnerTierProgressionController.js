/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
({
    doInit : function (cmp, event, helper) {
		helper.getAvailableProgramMembers(cmp);
    },
    
    handleProgramChange : function (cmp, event, helper) {
        var member = cmp.get("v.selectedProgramMember");
        if (member !== null && member.Level !== null && member.Level.DV_PAA__Next_Level__c !== null) {
            helper.retrieveLevelRequirements(cmp, member.Level.DV_PAA__Next_Level__c, function() {
                helper.initialiseProgressChart(cmp, member);
            });
        }
    },
    
    onProgramSelect : function(cmp, event, helper) {
        var selectedProgram = cmp.find("channelProgramsSelect").get("v.value");
        var programs = cmp.get("v.availableProgramMembers");
        
        for(var i=0; i < programs.length; i++) {
            if(programs[i].Program.Id == selectedProgram) {
                cmp.set("v.selectedProgramMember", programs[i]);
                break;
            }
        }
    },
    handleProgramPicker : function(cmp, event) {
        cmp.set("v.selectedProgramMember", event.getParam("selectedProgramMember"));
    },
    // TO DO: Try figure out how to make spinner appear while chart loads. Very flakey atm
    toggleSpinner: function (cmp, event) {
        var spinner = cmp.find("spinnerContainer");
        $A.util.toggleClass(spinner, "slds-hide");
    }
})