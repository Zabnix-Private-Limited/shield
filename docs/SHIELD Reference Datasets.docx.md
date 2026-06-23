# SHIELD Reference Datasets Specification

Version: 1.0
Project: SHIELD
Document Type: Dataset Specifications & Preset Rules

This document outlines the standard preset datasets, referral loop rules, and product recommendation engines within the SHIELD ecosystem.

---

## 1. Laboratory Services Dataset

This dataset lists the standard laboratory tests available for selection and booking through the Lab section of the Customer and Service Provider portals.

| Test Code | Test Name | Category | Description |
|---|---|---|---|
| LAB-001 | Complete Blood Count (CBC) | Hematology | Assesses overall health; counts red/white cells, hemoglobin, platelets. |
| LAB-002 | HbA1c (Glycated Hemoglobin) | Diabetes Care | Measures average blood sugar level over the past 3 months. |
| LAB-003 | Lipid Profile | Cardiovascular | Checks Cholesterol levels (HDL, LDL, Triglycerides). |
| LAB-004 | Liver Function Test (LFT) | Biochemistry | Measures proteins, liver enzymes, and bilirubin in blood. |
| LAB-005 | Kidney Function Test (KFT) | Biochemistry | Measures Urea, Creatinine, and Uric Acid to assess renal health. |
| LAB-006 | Thyroid Panel (T3, T4, TSH) | Endocrinology | Evaluates thyroid gland function. |
| LAB-007 | Urine Routine & Microscopy | Urinalysis | Evaluates renal function, infections, or metabolic conditions. |
| LAB-008 | Vitamin D (25-Hydroxy) | Vitamins | Assesses bone health and immune health. |
| LAB-009 | Vitamin B12 | Vitamins | Measures neurological health and red blood cell production. |

---

## 2. Homecare Services Dataset

This dataset defines the home visits and care nursing packages available under the Homecare module.

| Service Code | Service Name | Service Provider Category | Description |
|---|---|---|---|
| HC-001 | General Nurse Home Visit | Home Nursing | Registered nurse visit for vitals check, injections, or IV fluids. |
| HC-002 | Elderly Care Assistance | Home Caregiver | Non-medical daily living assistance for senior citizens. |
| HC-003 | Post-Surgical Home Care | Specialized Care | Critical post-operative support, wound dressing, and monitoring. |
| HC-004 | Physiotherapy Session | Physical Therapy | Qualified physiotherapist visit for rehabilitation and exercise. |
| HC-005 | Diabetic Wound Care | Specialized Care | Targeted dressing and management for diabetic ulcers. |
| HC-006 | Baby & Mother Care | Pediatrics | Home nurse support for newborn baby care and postpartum recovery. |

---

## 3. Dietitian Plans Dataset

Preset meal plans and counseling programs offered by dietitian services.

| Plan Code | Plan Name | Duration | Description | Target Condition |
|---|---|---|---|---|
| DIET-001 | Weight Management Program | 3 Months | Controlled calorie diet with weekly counseling sessions. | Obesity / Weight Loss |
| DIET-002 | Diabetic Diet Control | 6 Months | Low glycemic index (GI) meal planning and carb counting. | Type 2 Diabetes |
| DIET-003 | Cardiac Healthy Meal Plan | 1 Month | Low sodium, low saturated fat diet emphasizing heart-healthy grains. | Hypertension / Cholesterol |
| DIET-004 | Renal Nutrition Support | 3 Months | Protein-restricted diet managing Sodium, Potassium, and Phosphorus. | Chronic Kidney Disease |
| DIET-005 | PCOD/PCOS Balanced Plan | 3 Months | Insulin-sensitizing diets focused on hormonal balance and weight control. | PCOS / Hormonal |
| DIET-006 | Ketogenic Therapeutic Plan | 1 Month | High-fat, low-carbohydrate diet under direct clinical supervision. | Epilepsy / Metabolic |

---

## 4. Referral Loop & Points System Rules

The Points ledger of the Customer Wallet utilizes the referral loop mechanism defined below:

1. **Referral Code Generation**: Each registered Customer has a unique `referral_code` (e.g. `SHIELD-REF-1002`).
2. **Referral Input**: A new customer registering through a Sahakar agent provides the referrer's `referral_code`.
3. **Validation**: The system checks if the referral code exists in the `customers` table and matches an active customer.
4. **Successful Registration**: The new customer's record is created with `referred_by_id` pointing to the referrer's customer record.
5. **Point Crediting**:
   - Upon successful verification and approval of the new customer by the Shield Executive, the system automatically awards **100 points** to the referrer.
   - The transaction is recorded in the `wallet_transactions` table with:
     - `wallet_id` of the referrer's wallet.
     - `transaction_type` = `'CREDIT'`.
     - `sub_ledger_type` = `'POINTS'`.
     - `amount` = `100.00`.
     - `remarks` = `'Referral bonus for customer: [New Customer Name]'`.

---

## 5. Pharmacy Regularly Used & Suggested Products Logic

### Regularly Used Products (Preloading)
1. **Definition**: Products that a customer purchases repeatedly (e.g. twice or more in a 60-day period) are flagged as "Regularly Used".
2. **Preloading Logic**: When the customer opens the Pharmacy Services screen, these products are retrieved from `purchase_items` and preloaded at the top for instant re-ordering.

### Suggestive Recommendation Logic (Other Patients' Purchases)
1. **Rule**: Suggest products that similar patients with similar chronic conditions purchase together.
2. **Preset Product Associations**:
   * **If patient regularly buys Metformin (Diabetes)**:
     - Suggest: *B-Complex / Vitamin B12* (long-term metformin usage is associated with Vitamin B12 deficiency).
     - Suggest: *Glucometer Test Strips* (frequently bought together).
   * **If patient regularly buys Atorvastatin (Cholesterol)**:
     - Suggest: *Coenzyme Q10 (CoQ10)* (statin therapy depletes CoQ10 levels, causing muscle aches).
     - Suggest: *Omega-3 Fish Oil Capsule* (cardiovascular support).
   * **If patient regularly buys Telmisartan (Hypertension)**:
     - Suggest: *Digital Blood Pressure Monitor* (frequently bought together for self-monitoring).
     - Suggest: *Low-sodium Salt alternatives* (dietary support).

---

## 6. Blood Groups List

Valid options for the profile blood group selection field:
- A+ (A Positive)
- A- (A Negative)
- B+ (B Positive)
- B- (B Negative)
- AB+ (AB Positive)
- AB- (AB Negative)
- O+ (O Positive)
- O- (O Negative)

---
