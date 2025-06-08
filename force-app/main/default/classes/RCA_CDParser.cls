/**************************************************************************************************
 * Class         : RCA_CDParser
 * -------------------------------------------------------------------------------------------------
 * Purpose       : Wraps the low-level **IndustriesContext.queryTags** call and extracts the
 *                 “SalesTransactionItemAttribute” tag list for the supplied context.
 **************************************************************************************************/
public with sharing class RCA_CDParser {

    public static List<Object> retrieveContext(
            String ctxId,
            Context.IndustriesContext ctx) {
        //Test Code Starts
        Map<String, Object> inputTest = new Map<String, Object>{
            'contextId' => ctxId,
            'tags'      => new List<String>{ 'SalesTransactionItem' }
        };
        Map<String, Object> outputTest    = ctx.queryTags(inputTest);
        Map<String, Object> queryResTest   = (Map<String, Object>) outputTest.get('queryResTest');
        System.debug('RCA_CDParser.retrieveContext - ctxId: ' + JSON.serialize(queryResTest));        
        //Test Code End
        Map<String, Object> input = new Map<String, Object>{
            'contextId' => ctxId,
            'tags'      => new List<String>{ 'SalesTransactionItemAttribute' }
        };

        Map<String, Object> output     = ctx.queryTags(input);
        Map<String, Object> queryRes   = (Map<String, Object>) output.get('queryResult');

        return (queryRes != null)
             ? (List<Object>) queryRes.get('SalesTransactionItemAttribute')
             : new List<Object>();
    }
}