/**************************************************************************************************
 * Class         : RCA_CDModifyController
 * -------------------------------------------------------------------------------------------------
 * Hook Type     : *Pre*-Procedure hook for Summer ’25 Pricing (implements
 *                 RevSignaling.SignalingApexProcessor).
 *
 * Flow          : 1) Validate request → 2) fetch attribute rows → 3) map attributes
 *                 4) skip CTX_DELETED → 5) build payload → 6) update context.
 *
 * Sharing       : marked **without sharing** because pricing hooks generally require
 *                 system-level access to context data; adjust if your security model differs.
 **************************************************************************************************/
global without sharing class RCA_CDModifyController
        implements RevSignaling.SignalingApexProcessor {

    global RevSignaling.TransactionResponse execute(RevSignaling.TransactionRequest request) {

        RevSignaling.TransactionResponse resp = new RevSignaling.TransactionResponse();
        try {
            //Step 1:  Validate input
            if (request == null || String.isBlank(request.ctxInstanceId)) {
                resp.status  = RevSignaling.TransactionStatus.FAILED;
                resp.message = 'Context Id is missing in TransactionRequest.';
                return resp;
            }
            String ctxId = request.ctxInstanceId;
        
             //Step 2: Initialize IndustriesContext instance
            Context.IndustriesContext ctx = new Context.IndustriesContext();

            //Step 3: Retrieve attribute tag data
            List<Object> rows = RCA_CDParser.retrieveContext(ctxId, ctx);
            if (rows.isEmpty()) {
                resp.status  = RevSignaling.TransactionStatus.SUCCESS;
                resp.message = 'No attribute rows to process.';
                return resp;
            }
        
            //Step 4: Build path → attributeMap
            Map<String, Map<String,String>> attrMap =
                RCA_CDAttributeProcessor.processAttributes(
                    rows,
                    RCA_CDAttributeDataHelper.attributeTagMapper()
                );
            
            if (attrMap.isEmpty()) {
                resp.status  = RevSignaling.TransactionStatus.SUCCESS;
                resp.message = 'No relevant attributes found for mapping.';
                return resp;
            }
            //Step 5: Skip CD update for QLI delete calls
            if (!RCA_CDNodeTxnItemValidator.checkForValidItem(attrMap, ctxId)) {
                resp.status  = RevSignaling.TransactionStatus.SUCCESS;
                resp.message = 'Detected CTX_DELETED items and update skipped.';
                return resp;
            }
            //Step 6: Generate node-update payload
            Map<String,Object> payload =
                RCA_CDAttributeProcessor.genUpdateRep(attrMap, ctxId);
            
            //Step 7: Perform update
            ctx.updateContextAttributes(payload);

            resp.status  = RevSignaling.TransactionStatus.SUCCESS;
            resp.message = 'Pre-hook executed successfully.';
            return resp;

        } catch (Exception ex) {
            resp.status  = RevSignaling.TransactionStatus.FAILED;
            resp.message = ex.getMessage();
            return resp;
        }
    }
}