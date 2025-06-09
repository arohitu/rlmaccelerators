/**
 * @description:    Test class for the RCA_QuoteApprovalLWCController.
 *                  This class is designed to verify the functionality of the 
 *                  `submitQuoteForApproval` method, which serves as an intermediary 
 *                   between an LWC and a Flow to handle Quote submissions.
 * Methods:
 * 1. Successful submission path where the invoked Flow completes as expected.
 * 2. Input validation, specifically handling of a null Quote ID.
 * 3. Controlled failure path, where the Flow is expected to run but return a specific failure
 * condition.
 *
 * @author      Rohit Radhakrishnan (Salesforce)
 * @date        June 6, 2025
 **/

@isTest
private class RCA_QuoteApprovalLWCController_Test {

    /**
     * @description Sets up test data, creating a single test user with the
    * required profile and permission sets.
    * This user is then available for all test methods to run against.
    */
    /* --> uncomment from here
    @testSetup
    static void setup() {
        
        //Add test user for system.runAs() user
        // Find the specific Profile for the test user.
        Profile p = [SELECT Id FROM Profile WHERE Name = 'M Sales User' LIMIT 1];

        // Create the test user record with a unique username to prevent collisions.
        User testUser = new User(
        Alias = 'msales',
        Email = 'msalesuser@testorg.com.invalid',
        EmailEncodingKey = 'UTF-8',
        LastName = 'SalesUser',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_GB', // Using UK locale as per context
        ProfileId = p.Id,
        TimeZoneSidKey = 'Europe/London',
        Username = 'msalesuser' + System.currentTimeMillis() + '@testorg.com'
        );
        insert testUser;

        // Find the Permission Set Groups by their DeveloperName (API Name).
        // IMPORTANT: Ensure these Permission Set Groups exist in your org.
        List<PermissionSetGroup> psgsToAssign = [SELECT Id, Status FROM PermissionSetGroup
                                                 WHERE DeveloperName IN ('YOUR_PSG')];
        // Assign the Permission Set Groups to the new user.
        if (!psgsToAssign.isEmpty()) {
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (PermissionSetGroup psg : psgsToAssign) {
                // force calculation of the PSG if it is not already Updated
                if (psg.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(psg.Id);
                }
                assignments.add(new PermissionSetAssignment(
                    AssigneeId = testUser.Id,
                    PermissionSetGroupId = psg.Id
                ));
            }
            insert assignments;
        }
    }
    */ //--> uncomment till here

    private static Quote createTestQuote(Boolean setupForFlowSuccess, String flowFailureType) {
        // 1. Create dependent records (Account, Opportunity)
        Account acc = new Account(Name = 'Test Account for Quote');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test - Quote',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30)
        );
        insert opp;

        // 2. Ensure a standard price book is active and get its Id
        Id pricebookId;
        try {
            pricebookId = Test.getStandardPricebookId();
        } catch (System.QueryException e) {
            Pricebook2 customTestPb = new Pricebook2(Name='Test Custom Price Book', IsActive=true);
            insert customTestPb;
            pricebookId = customTestPb.Id;
        }

        // 3. Create the Quote record
        Quote quoteRec = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = pricebookId,
            Status = 'Draft'
        );
        insert quoteRec;
        return quoteRec;
    }

    @isTest
    static void testSubmitForApproval_Success() {
        // Find the user created in the @testSetup method.
        //User testUser = [SELECT Id FROM User WHERE Alias = 'msales' LIMIT 1];

        // Run the entire test method as the specified user to validate
        // permissions and sharing rules.
        //System.runAs(testUser) {
            Quote testQuote = createTestQuote(true, null);
            String comments = 'Test comments - expecting success.';

            Test.startTest();
            RCA_QuoteApprovalLWCController.submitQuoteForApproval(testQuote.Id, comments);
            Test.stopTest();

        // Assert the side-effect of the flow running successfully.
        // This assumes the flow creates an 'ApprovalSubmission__c' record.
        List<ApprovalSubmission> lApprSub = [SELECT Id, RelatedRecordId, Status FROM ApprovalSubmission 
                                             WHERE RelatedRecordId =:testQuote.Id  LIMIT 1];
            System.assertEquals(false, lApprSub.isEmpty(), 'An Approval Submission exist for the quote');
        //}
    }

    @isTest
    static void testSubmitForApproval_NullQuoteId() {
        //User testUser = [SELECT Id FROM User WHERE Alias = 'msales' LIMIT 1];

        //System.runAs(testUser) {
            String comments = 'Test comments - null quoteId.';
            AuraHandledException ex = null;

            Test.startTest();
            try {
                RCA_QuoteApprovalLWCController.submitQuoteForApproval(null, comments);
            } catch (AuraHandledException e) {
                ex = e;
            }
            Test.stopTest();

            System.assertNotEquals(null, ex, 'AuraHandledException should have been thrown for null Quote ID.');
            if (ex != null) {
                System.debug('NullQuoteId Test - Exception Message: ' + ex.getMessage());
            }
        //}
    }

    @isTest
    static void testSubmitForApproval_InvalidId() {
        //User testUser = [SELECT Id FROM User WHERE Alias = 'msales' LIMIT 1];

        //System.runAs(testUser) {
            String comments = 'Test comments - using an invalid ID string.';
            Exception ex = null;

            Test.startTest();
            try {
                // Pass an invalid string that cannot be a Salesforce ID
                RCA_QuoteApprovalLWCController.submitQuoteForApproval('INVALID_ID', comments);
            } catch (Exception e) {
                ex = e;
            }
            Test.stopTest();

            // The flow will fail with this invalid ID, and the controller will throw an exception.
            System.assertNotEquals(null, ex, 'An exception should be thrown when the flow is started with an invalid ID.');
        //}
    }
}