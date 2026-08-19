export class PharmacySettingsDto {
  autoAcceptOrders?: boolean;
  requireInvoiceBeforeDispatch?: boolean;
  allowPartialFulfillment?: boolean;
  allowPartialDispatch?: boolean;
  lowStockAlerts?: boolean;
  lowStockThreshold?: number;
  suggestSubstitutes?: boolean;
  requireCustomerConfirmation?: boolean;
  enableChronicTagging?: boolean;
  defaultRefillCadenceDays?: number;
  newOrderSoundAlerts?: boolean;
  paymentSubmissionAlerts?: boolean;
  enableHomeDelivery?: boolean;
  enableStorePickup?: boolean;
  mandatoryManualVerification?: boolean;
  requireUtrProof?: boolean;
  dateFormat?: 'YYYY-MM-DD' | 'DD/MM/YYYY' | 'MM/DD/YYYY';
  timeFormat?: '12-hour AM/PM' | '24-hour';
}
