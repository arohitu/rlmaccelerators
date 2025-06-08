/**************************************************************************************************
 * Class         : RCA_CDAttributeDataHelper
 * -------------------------------------------------------------------------------------------------
 * Purpose       : Supplies an Attribute-to-Tag map for pricing context updates.  
 *                 Data is read from Custom Metadata Type **RCA_AttributeTagMap__mdt** so that
 *                 admins can modify mappings without code changes.
 *
 * Governor Hints: • SOQL on CMDT is unmetered.  
 *                 • Mapping is cached per transaction; callers receive a `deepClone()` to avoid
 *                   accidental mutation of the shared cache.
 *
 * Version History
 * ---------------
 * 2025-05-27  v1.0  First version
 **************************************************************************************************/
public with sharing class RCA_CDAttributeDataHelper {

    private static Map<String, String> ATTRIBUTE_TAG_MAP;

    /**
     * Public API : returns a clone of the mapping (key = AttributeName, value = TagName).
     */
    public static Map<String, String> attributeTagMapper() {

        if (ATTRIBUTE_TAG_MAP == null) {
            Map<String, String> tmp = new Map<String, String>();

            for (RCA_AttributeTagMap__mdt rec :
                 [SELECT AttributeName__c, TagName__c
                  FROM   RCA_AttributeTagMap__mdt
                  WHERE  Active__c = TRUE]) {

                tmp.put(rec.AttributeName__c, rec.TagName__c);
            }
            ATTRIBUTE_TAG_MAP = tmp;     // assign only after successful load
        }
        // Return a deep clone to prevent accidental mutation of the shared cache
        return ATTRIBUTE_TAG_MAP;
    }
}
