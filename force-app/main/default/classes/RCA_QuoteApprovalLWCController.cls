
/**
 * @description:   Controller for the rca_invokeQuoteApproval LWC. This class provides a method
 *                 to be called from the LWC to initiate a Salesforce Flow for submitting a Quote 
 *                 for approval. It acts as a secure intermediary, handling parameter passing.
 *
 * @author:        Rohit Radhakrishnan (Salesforce)
 * @date:          June 6, 2025
 *
 * @see rca_invokeQuoteApproval LWC
 * @see RCA_QuoteApprovalBusinessUnitDealDesk Flow
 */
public with sharing class RCA_QuoteApprovalLWCController {

    private static final String DEFAULT_APPROVAL_FLOW_API_NAME = 'RCA_QuoteApprovalBusinessUnitDealDesk';

    /**
     * @description:     Accepts a Quote ID and user comments from the LWC, then invokes the
     *                   RCA_QuoteApprovalBusinessUnitDealDesk Flow to start the approval process.
     * @param :quoteId - The ID of the Quote record to be submitted for approval.
     * @param submitterComments - User-entered comments to be passed to the approval process.
     * @throws AuraHandledException if the quoteId is null, or if the Flow returns a failure
     * condition or encounters an unhandled exception.
     */
    @AuraEnabled
    public static void submitQuoteForApproval(String quoteId, String submitterComments) {
        if (quoteId == null) {
            throw new AuraHandledException('Quote ID cannot be null when submitting for approval.');
        }

        String flowApiName = DEFAULT_APPROVAL_FLOW_API_NAME;

        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('recordId', quoteId);
        flowInputs.put('submitter', UserInfo.getUserId());
        flowInputs.put('submissionComments', submitterComments);

        try {
            Flow.Interview approvalFlow = Flow.Interview.createInterview(flowApiName, flowInputs);
            approvalFlow.start();
        } 
        catch (Exception e) {
            throw new AuraHandledException('An unexpected error occurred while submitting for approval. Please contact your administrator.');
        }
    }
}