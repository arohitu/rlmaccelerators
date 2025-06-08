/**************************************************************************************************
 * Class         : RCA_CDAttributeProcessor
 * -------------------------------------------------------------------------------------------------
 * Purpose       : • Filters the raw attribute rows returned from context query  
 *                 • Builds a path→attribute map for the updater  
 *                 • Converts that map into the payload expected by IndustriesContext.updateContextAttributes
 *
 * Notes         : • `processAttributes` ignores dataPath[0] (contextId) and the last element
 *                   (QuoteLineAttribute record Id) by design.  
 *                 • `genUpdateRep` now fetches the attribute-tag map **once** for the loop.
 **************************************************************************************************/
public with sharing class RCA_CDAttributeProcessor {

    /*--------------------------------------------------------------------
      STEP A – produce { pathKey → { attributeName → attributeValue } }
      --------------------------------------------------------------------*/
    public static Map<String, Map<String, String>> processAttributes(List<Object> rows,
                                                    Map<String, String> inputMap) {

        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();

        for (Object oRow : rows) {
            Map<String, Object> row = (Map<String, Object>) oRow;
            Map<String, Object> tagValueMap = (Map<String, Object>) row.get('tagValue');
            // Assume tagValueMap is non-empty and get the first tag key
            // Convert keySet to List to access first key
            List<String> tagKeys = new List<String>(tagValueMap.keySet());
            String firstTagKey = tagKeys[0];

            Map<String, Object> firstTag = (Map<String, Object>) tagValueMap.get(firstTagKey);
            String dmlStatus = (String) firstTag.get('dmlStatus');

            if (dmlStatus == 'DELETED') {
                continue; // skip this record
            }
            List<Object> dataPath = (List<Object>) row.get('dataPath');
            if (dataPath == null || dataPath.size() <= 2) { continue; }

            /* Build key from dataPath[1 … size-2] */
            List<String> seg = new List<String>();
            for (Integer i = 1; i < dataPath.size() - 1; i++) {
                seg.add((String) dataPath[i]);
            }
            String pathKey = String.join(seg, ':');

            Map<String, Object> tagValue = (Map<String, Object>) row.get('tagValue');
            if (tagValue == null) { continue; }

            Map<String, Object> attribute = (Map<String, Object>) tagValue.get('Attribute');
            String attrKey = (attribute != null) ? (String) attribute.get('tagValue') : null;

            if (attrKey == null || !inputMap.containsKey(attrKey)) { continue; }

            Map<String, Object> attributeValue = (Map<String, Object>) tagValue.get('AttributeValue');
            String attrVal = (attributeValue != null) ? (String) attributeValue.get('tagValue') : null;

            if (!result.containsKey(pathKey)) {
                result.put(pathKey, new Map<String, String>());
            }
            result.get(pathKey).put(attrKey, attrVal);
        }
        return result;
    }

    /*--------------------------------------------------------------------
      STEP B – convert to payload for updateContextAttributes
      --------------------------------------------------------------------*/
    public static Map<String, Object> genUpdateRep(Map<String, Map<String, String>> inputMap,
                                                    String contextId) {

        Map<String, Object> result = new Map<String, Object>();
        List<Map<String, Object>> nodePathAndAttributes = new List<Map<String, Object>>();

        /* Fetch tag-map once – avoids repeated SOQL / cloning in the inner loop */
        Map<String, String> tagMapper = RCA_CDAttributeDataHelper.attributeTagMapper();

        for (String pathKey : inputMap.keySet()) {

            /* nodePath */
            Map<String, Object> nodePath = new Map<String, Object>{
                'dataPath' => pathKey.split(':')
            };

            /* attributes */
            List<Map<String, String>> attrList = new List<Map<String, String>>();
            for (String attrName : inputMap.get(pathKey).keySet()) {
                attrList.add(new Map<String, String>{
                    'attributeName'  => tagMapper.get(attrName),
                    'attributeValue' => inputMap.get(pathKey).get(attrName)
                });
            }

            nodePathAndAttributes.add(new Map<String, Object>{
                'nodePath'   => nodePath,
                'attributes' => attrList
            });
        }

        result.put('nodePathAndAttributes', nodePathAndAttributes);
        result.put('contextId', contextId);
        return result;
    }
}
