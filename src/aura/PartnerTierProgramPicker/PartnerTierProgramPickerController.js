/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
({
    onProgramSelect : function(cmp, event, helper) {
        var selectedProgram = cmp.find("channelProgramsSelect").get("v.value");
        var programs = cmp.get("v.availableProgramMembers");
        //console.log("Program Picked");
        for(var i=0; i < programs.length; i++) {
            if(programs[i].Program.Id == selectedProgram) {
                var e = $A.get("e.DV_PAA:PartnerTierProgramPickerEvent");
                e.setParams({
                    "selectedProgramMember" : programs[i],
                    "levelIcon" : programs[i].Level.Icon_URL__c
                });
                e.fire();
                break;
            }
        }
    },
    handleProgramPicker : function(cmp, event) {
        var select = cmp.find("channelProgramsSelect");
        select.set("v.value", event.getParam("selectedProgramMember").ProgramId);
    }
})