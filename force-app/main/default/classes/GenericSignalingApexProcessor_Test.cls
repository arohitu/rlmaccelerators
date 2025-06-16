/**************************************************************************************************
 * Class         : GenericSignalingApexProcessor_Test
 * -------------------------------------------------------------------------------------------------
 * Purpose       : • This class serves as a generic, reusable template for testing any Apex class
 * that implements the RevSignaling.SignalingApexProcessor interface.
 *
 * Test Strategy : • It demonstrates the standard "Service Wrapper and Mocking" pattern, which is
 * essential for testing code that interacts with managed package classes like
 * Context.IndustriesContext that cannot be mocked directly.
 * • This simplified version runs in the system context and does not test
 * user-specific permissions or profiles.
 *
 * How to Use    : 1. Copy this entire class for your project.
 * 2. Update the mock data helper methods to generate data that fits your
 * specific business logic and scenarios.
 * 3. Adapt the test methods to assert the specific outcomes of your processor.
 **************************************************************************************************/
@isTest
private class GenericSignalingApexProcessor_Test {

    //================================================================================
    // SECTION 1: TEST SETUP
    // Test setup has been removed for simplicity. Tests will run in the default
    // system context. If user-specific behavior needs to be tested, a user
    // should be created directly within the relevant test method.
    //================================================================================


    //================================================================================
    // SECTION 2: TEST METHODS
    // Each method tests a specific execution path of the Apex Processor.
    //================================================================================

    /**
     * @description Validates the successful execution path.
     */
    @isTest
    static void testExecute_SuccessScenario() {
        // ARRANGE: Prepare the test environment and mock responses.
        
        // Create an instance of our mock provider.
        TestContextProviderMock mockProvider = new TestContextProviderMock();
        // Define the data the mock should return for this specific scenario.
        mockProvider.queryTagsResponse = getGenericQueryTagsResponse();
        mockProvider.queryContextRecordsResponse = getGenericQueryContextRecordsResponse('UNCHANGED');

        // This is the key to the pattern: we create a stub of our OWN interface,
        // which is allowed, and assign our mock provider to handle its calls.
        GenericContextService.serviceProvider = (IGenericContextService) Test.createStub(IGenericContextService.class, mockProvider);

        // Create the request object that will be passed into our processor.
        // We use JSON.deserialize because the real object has no public constructor.
        RevSignaling.TransactionRequest request = (RevSignaling.TransactionRequest) JSON.deserialize(
            '{"ctxInstanceId": "testContextId"}', RevSignaling.TransactionRequest.class
        );

        // Instantiate the class we are testing.
        RCA_CDModifyController controller = new RCA_CDModifyController(); // ** ACTION: Replace with your class **

        // ACT: Execute the method under test.
        Test.startTest();
        // The 'response' variable is an instance of RevSignaling.TransactionResponse.
        // It holds the result of the Apex hook execution.
        RevSignaling.TransactionResponse response = controller.execute(request);
        Test.stopTest();

        // ASSERT: Verify the outcome.
        // The 'status' and 'message' properties are critical for confirming the result.
        System.assertEquals(RevSignaling.TransactionStatus.SUCCESS, response.status, 'Response status should be SUCCESS.');
        System.assertEquals('Pre-hook executed successfully.', response.message, 'The final success message was expected.');
        System.assertEquals(1, mockProvider.getInvocationCount('updateContextAttributes'), 'The context update method should have been called.');
    }

    /**
     * @description Validates a specific business logic failure or skip scenario.
     */
    @isTest
    static void testExecute_BusinessLogicSkipScenario() {
        // ARRANGE: Setup a mock response that will trigger your specific business rule.
        TestContextProviderMock mockProvider = new TestContextProviderMock();
        mockProvider.queryTagsResponse = getGenericQueryTagsResponse();
        // This time, the mock simulates that a related record was deleted.
        mockProvider.queryContextRecordsResponse = getGenericQueryContextRecordsResponse('CTX_DELETED');

        GenericContextService.serviceProvider = (IGenericContextService) Test.createStub(IGenericContextService.class, mockProvider);
        RevSignaling.TransactionRequest request = (RevSignaling.TransactionRequest) JSON.deserialize(
            '{"ctxInstanceId": "testContextId"}', RevSignaling.TransactionRequest.class
        );
        RCA_CDModifyController controller = new RCA_CDModifyController(); // ** ACTION: Replace with your class **

        // ACT
        Test.startTest();
        RevSignaling.TransactionResponse response = controller.execute(request);
        Test.stopTest();

        // ASSERT: Verify the specific outcome for this scenario.
        // Even in a graceful skip, the status is often SUCCESS. The message is key.
        System.assertEquals(RevSignaling.TransactionStatus.SUCCESS, response.status, 'A graceful skip should return SUCCESS.');
        System.assertEquals('Detected CTX_DELETED items and update skipped.', response.message, 'The specific skip message was expected.');
        System.assertEquals(0, mockProvider.getInvocationCount('updateContextAttributes'), 'The context update should be skipped.');
    }


    //================================================================================
    // SECTION 3: MOCKING FRAMEWORK
    // This inner class and interface are the core of the testability pattern.
    // They allow us to simulate the managed package context API.
    //================================================================================

    /**
     * @description A generic interface defining the "contract" for context interactions.
     * This is what allows our code to be decoupled from the managed package.
     */
    public interface IGenericContextService {
        Map<String, Object> queryTags(Map<String, Object> input);
        Map<String, Object> queryContextRecordsAndChildren(Map<String, Object> input);
        void updateContextAttributes(Map<String, Object> input);
    }

    /**
     * @description A generic "Service Wrapper" class. In your production code, you would
     * create a class like this to wrap the real Context.IndustriesContext calls.
     * This demonstrates how the test class interacts with the wrapper.
     */
    public class GenericContextService {
        @TestVisible
        private static IGenericContextService serviceProvider;
        // In real code, the default provider would be an instance that
        // calls the real Context.IndustriesContext API.
    }

    /**
     * @description The mock provider that simulates the context API for tests.
     */
    public class TestContextProviderMock implements System.StubProvider {
        // Properties to hold pre-defined responses for different API calls
        public Map<String, Object> queryTagsResponse;
        public Map<String, Object> queryContextRecordsResponse;
        private Map<String, Integer> invocationCounts = new Map<String, Integer>();

        // This method intercepts calls made to our IGenericContextService interface
        public Object handleMethodCall(Object stubbedObject, String methodName, Type returnType, Type[] argTypes, String[] argNames, Object[] args) {
            methodName = methodName.toLowerCase();
            invocationCounts.put(methodName, getInvocationCount(methodName) + 1);

            // Return the pre-defined response based on the method being called
            switch on methodName {
                when 'querytags' { return queryTagsResponse; }
                when 'querycontextrecordsandchildren' { return queryContextRecordsResponse; }
                when 'updatecontextattributes' { return null; } // void method
                when else { return null; }
            }
        }

        // Helper to check how many times a method was called
        public Integer getInvocationCount(String methodName) {
            return invocationCounts.get(methodName.toLowerCase()) == null ? 0 : invocationCounts.get(methodName.toLowerCase());
        }
    }


    //================================================================================
    // SECTION 4: TEST DATA HELPERS
    // Methods to generate consistent mock response data.
    // ** ACTION: Update these to create data relevant to your project. **
    //================================================================================

    private static Map<String, Object> getGenericQueryTagsResponse() {
        List<Object> attributes = new List<Object>{
            new Map<String, Object>{
                'dataPath' => new List<Object>{ 'ctxId', 'path1', 'path2' },
                'tagValue' => new Map<String, Object>{
                    'Attribute' => new Map<String, Object>{'dmlStatus' => 'UNCHANGED', 'tagValue' => 'MyAttribute'},
                    'AttributeValue' => new Map<String, Object>{'dmlStatus' => 'UNCHANGED', 'tagValue' => 'MyValue'}
                }
            }
        };
        return new Map<String, Object>{ 'queryResult' => new Map<String, Object>{ 'SalesTransactionItemAttribute' => attributes } };
    }

    private static Map<String, Object> getGenericQueryContextRecordsResponse(String state) {
        List<Object> records = new List<Object>{
            new Map<String, Object>{
                'record' => new Map<String, Object>{
                    'currentState' => state,
                    'attributesAndValues' => new Map<String, Object>{ 'SomeField' => 'SomeValue' }
                }
            }
        };
        return new Map<String, Object>{ 'queryResults' => new List<Object>{ new Map<String, Object>{ 'queryResult' => new Map<String, Object>{ 'queryRecords' => records } } } };
    }
}
