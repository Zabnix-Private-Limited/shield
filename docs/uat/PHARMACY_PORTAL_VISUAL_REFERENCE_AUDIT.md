# 🎨 SHIELD PHARMACY STAFF PORTAL — VISUAL REFERENCE AUDIT

**Target Platform**: SHIELD Pharmacy Staff Portal (`https://shield-zabnix.vercel.app/#/portal/pharmacy-staff/`)  
**Reference Index**: `Design System/Pharmacy Design/references/REFERENCE_INDEX.md`  

---

## 1. Visual Reference Evaluation Matrix

| Reference File | Target Route | Target Viewport | Shell | Structure | Typography | Spacing | Cards | Controls | Status States | Responsive | Status |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `01_pharmacy_orders_desktop_advanced.png` | `/orders` | 1440 × 900 | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | **PASS** |
| `02_responsive_web_tablet_mobile.png` | Cross-device | 390 / 768 / 1440 | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | **PASS** |
| `03_profile_and_settings_reference.png` | `/profile`, `/settings` | 1366 × 768 | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | **PASS** |
| `04_dashboard_reference.png` | `/dashboard` | 1440 × 900 | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | **PASS** |
| `05_mobile_order_detail_partial_fulfillment.png` | `/orders` (Mobile) | 390 × 844 | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | **PASS** |
| `06_tablet_order_fulfillment.png` | `/orders` (Tablet) | 1024 × 768 | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | **PASS** |
| `07_dashboard_alternate_reference.png` | `/dashboard` | 1920 × 1080 | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | **PASS** |
| `08_settings_detailed_reference.png` | `/settings` | 1440 × 900 | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | **PASS** |
| `09_profile_detailed_reference.png` | `/profile` | 1440 × 900 | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | **PASS** |

---

## 2. Dimensional Visual Alignment Analysis

- **Canvas & Surfaces**: Clean white/light-first canvas with soft slate borders (`#E2E8F0`) and light grey background (`#F8FAFC`).
- **Brand System & Accent Palette**: Restrained SHIELD Teal (`#10B981`) and SHIELD Navy (`#0F172A`) for primary hierarchy and status chips.
- **Typography & Scale**: Outfit / Inter typeface hierarchy. Headers (`h2`), subtitles, body text, and captions adhere to design token scale.
- **Responsive Layout Rules**:
  - *Desktop (> 1180px)*: Queue + detail split-pane workspace.
  - *Tablet & Compact (< 1180px)*: Auto-pop detail view modal overlay (`showDialog`, `maxWidth: 860`, `maxHeight: 780`).
  - *Mobile (< 640px)*: Stacked card-based layout with sticky bottom action controls.

---

## 3. Justified Deltas

- **Low-Stock Inventory Cards Removed**: The Low-Stock Behavior settings card depicted in `08_settings_detailed_reference.png` was intentionally removed per SHIELD System Rule #14 (*ERP Inventory Decoupling*), as stock levels reside exclusively in the client's external ERP.
- **Single-Outlet Read-Only Profile**: Branch switching and provider selector dropdowns depicted in mockup variants are omitted on Pharmacy Staff profile per System Rule #4 (*Absolute Pharmacy Access Rule*).
