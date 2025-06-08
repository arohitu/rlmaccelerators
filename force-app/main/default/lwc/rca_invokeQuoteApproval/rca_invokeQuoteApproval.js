import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import submitQuoteForApproval from '@salesforce/apex/RCA_QuoteApprovalLWCController.submitQuoteForApproval';

export default class Rca_invokeQuoteApproval extends LightningElement {
    @api recordId;
    submitterComments = '';
    quoteRecord;
    isLoading = false; // Start in loading state

    handleCommentChange(event) {
        this.submitterComments = event.target.value;
    }

    async handleSubmit() {
        this.isLoading = true; // Show spinner during submission
        // Step 1: Validate the comments textarea (this part only runs if the form is visible)
        const commentsInput = this.template.querySelector('.comments-input');
        if (!commentsInput.reportValidity()) {
            this.isLoading = false;
            return; // Stop if comments are not valid
        }
        try {
            await submitQuoteForApproval({ quoteId: this.recordId, submitterComments: this.submitterComments });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Quote submitted for approval',
                    variant: 'success',
                })
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        } 
        catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Submitting for Approval',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error',
                })
            );
            console.error('Error submitting for approval:', JSON.stringify(error));
        } finally {
            this.isLoading = false; // Hide spinner post-submission attempt
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}