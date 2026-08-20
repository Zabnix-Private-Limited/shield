export class SubmitManualPaymentDto {
  customerId: string;
  amount: number;
  paymentChannel: 'BANK_TRANSFER' | 'UPI' | 'PAY_AT_PHARMACY' | 'PAID_THROUGH_AGENT' | 'CASH' | 'COUNTER_UPI' | 'CARD_POS';
  paymentMethodId?: string;
  referenceNumber?: string;
  proofFileName?: string;
  customerNotes?: string;
  autoApprove?: boolean;
}

export class RejectPaymentDto {
  rejectionReason: string;
}

