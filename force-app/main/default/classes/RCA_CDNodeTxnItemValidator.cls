/**************************************************************************************************
 * Class         : RCA_CDNodeTxnItemValidator
 * -------------------------------------------------------------------------------------------------
 * Purpose       : Determines whether any node involved in the update is already in **CTX_DELETED**
 *                 state (in which case we skip the attribute update).
 *
 * Key Methods   : • checkForValidItem  – public façade used by the pre-hook  
 *                 • generateQueryPaths – helper that builds the query payload  
 *                 • checkTxnItemStatus – parses query results (kept separate for testability)  
 **************************************************************************************************/
public with sharing class RCA_CDNodeTxnItemValidator {

    public static Boolean checkForValidItem(
            Map<String, Map<String, String>> pathAndAttribute,
            String currentContextId) {

        if (pathAndAttribute == null || pathAndAttribute.isEmpty()) {
            return false;
        }

        Context.IndustriesContext ctx = new Context.IndustriesContext();

        Map<String, Object> input  = generateQueryPaths(pathAndAttribute, currentContextId);
        Map<String, Object> output = ctx.queryContextRecordsAndChildren(input);
        Boolean hasValidItem = !(hasCtxDeleted(checkTxnItemStatus(output)));
        return hasValidItem;
    }
    public static Map<String, Object> generateQueryPaths(
            Map<String, Map<String, String>> pathAndAttribute,
            String currentContextId) {

        List<Map<String, Object>> qp = new List<Map<String, Object>>();

        for (String key : pathAndAttribute.keySet()) {
            List<String> elements = key.split(':');
            if (elements.size() == 2) {
                qp.add(new Map<String, Object>{ 'dataPath' => elements });
            }
        }
        return new Map<String, Object>{
            'queryPaths' => qp,
            'contextId'  => currentContextId
        };
    }

    /*--------------------------------------------------------------------*/
    public static Boolean hasCtxDeleted(Map<String, String> statusMap) {
        for (String v : statusMap.values()) {
            if (v == 'CTX_DELETED') {
                return true;
            }
        }
        return false;
    }

    /*--------------------------------------------------------------------*/
    public static Map<String, String> checkTxnItemStatus(Map<String, Object> nodeItemStatusMap) {
        Map<String, String> result = new Map<String, String>();
        if (nodeItemStatusMap == null || !nodeItemStatusMap.containsKey('queryResults')) {
            return result;
        }

        for (Object qrObj : (List<Object>) nodeItemStatusMap.get('queryResults')) {
            Map<String, Object> qr = (Map<String, Object>) qrObj;
            Map<String, Object> qrResult = (Map<String, Object>) qr.get('queryResult');
            if (qrResult == null) {
                continue;
            }

            List<Object> records = (List<Object>) qrResult.get('queryRecords');
            if (records == null || records.isEmpty()) {
                continue;
            }

            Map<String, Object> recordWrap = (Map<String, Object>) records[0];
            Map<String, Object> record     = (Map<String, Object>) recordWrap.get('record');
            if (record == null) {
                continue;
            }

            Map<String, Object> av = (Map<String, Object>) record.get('attributesAndValues');
            if (av == null) {
                continue;
            }

            String parentId = (String) av.get('SalesTransactionItemParent');
            String recId    = (String) record.get('contextDataRecordId');
            String state    = (String) record.get('currentState');

            if (String.isNotBlank(parentId) && String.isNotBlank(recId)) {
                result.put(parentId + ':' + recId, state);
            }
        }
        return result;
    }
}
