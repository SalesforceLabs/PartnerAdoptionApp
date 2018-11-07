public with sharing class FLSCheck {
    public static boolean checkFLS(Schema.DescribeSObjectResult objectType, List<string> fields, string checkType) {
        return checkFieldLevelSecurity(objectType.fields.getMap(), fields, checkType);
    }

    private static boolean checkFieldLevelSecurity(Map<String,Schema.SObjectField> fieldMap, List<string> fields, string checkType) {
        boolean ret = false;
        for (String fieldToCheck : fields) {
            if (checkType == 'Update') {
                ret = fieldMap.get(fieldToCheck).getDescribe().isUpdateable();
            } else if (checkType == 'Read') {
                ret = fieldMap.get(fieldToCheck).getDescribe().isAccessible();
            }
        }
        return ret;
    }
}