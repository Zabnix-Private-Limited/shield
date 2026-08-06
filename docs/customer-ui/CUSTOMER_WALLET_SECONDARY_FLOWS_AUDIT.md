# Cash Wallet secondary flows audit

Current customer wallet reads `GET /customer/wallet` and displays CASH ledger history. CASH remains separate from `REWARD_POINTS`; `SHIELD_BENEFIT` is not a customer cash balance. Current gaps to verify next: backend-supported filtering/detail/statement/export, valid-zero versus API-error handling, and offline recovery. No add-funds, transfer, withdrawal, or payment workflow will be exposed without a verified transactional contract.
