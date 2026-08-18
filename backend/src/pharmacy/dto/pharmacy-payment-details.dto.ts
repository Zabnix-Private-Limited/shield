export class CreateBankAccountDto {
  accountHolderName: string;
  bankName: string;
  accountNumber: string;
  ifscCode: string;
  branchName?: string;
  displayLabel?: string;
  isPrimary?: boolean;
  isActive?: boolean;
}

export class UpdateBankAccountDto {
  accountHolderName?: string;
  bankName?: string;
  accountNumber?: string;
  ifscCode?: string;
  branchName?: string;
  displayLabel?: string;
  isPrimary?: boolean;
  isActive?: boolean;
}

export class CreateUpiDto {
  upiId: string;
  displayLabel?: string;
  isPrimary?: boolean;
  isActive?: boolean;
}

export class UpdateUpiDto {
  upiId?: string;
  displayLabel?: string;
  isPrimary?: boolean;
  isActive?: boolean;
}
