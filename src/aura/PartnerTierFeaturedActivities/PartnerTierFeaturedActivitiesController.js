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
        if (member !== null) {
            helper.getFeaturedActivityTypes(cmp);
        }
    },
    handleProgramPicker : function(cmp, event) {
        cmp.set("v.selectedProgramMember", event.getParam("selectedProgramMember"));
    }
})