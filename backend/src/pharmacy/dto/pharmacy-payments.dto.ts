export class SubmitManualPaymentDto {
  customerId: string;
  amount: number;
  paymentChannel: 'BANK_TRANSFER' | 'UPI' | 'PAY_AT_PHARMACY' | 'PAID_THROUGH_AGENT';
  paymentMethodId?: string;
  referenceNumber?: string;
  proofFileName?: string;
  customerNotes?: string;
}

export class RejectPaymentDto {
  rejectionReason: string;
}
