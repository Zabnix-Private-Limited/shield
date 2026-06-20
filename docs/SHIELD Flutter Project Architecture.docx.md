# SHIELD Flutter Project Architecture & Complete Folder Structure

Version: 1.0

Project: SHIELD

Platform:

* Android

* Web

* PWA

* Future iOS

Architecture:

Feature First \+ Clean Architecture \+ Modular Design

State Management:

Riverpod

Navigation:

GoRouter

Networking:

Dio

Local Storage:

Hive

Secure Storage:

Flutter Secure Storage

---

# 1. Project Structure

shield/

├── android/  
├── ios/  
├── web/  
├── linux/  
├── macos/  
├── windows/

├── assets/  
│  
├── docs/  
│  
├── scripts/  
│  
├── test/  
│  
├── integration\_test/  
│  
├── lib/  
│  
└── pubspec.yaml

---

# 2. Assets Structure

assets/

├── fonts/

├── icons/

├── images/

├── animations/

├── logos/

├── placeholders/

├── certificates/

└── translations/

---

# 3. Docs Structure

docs/

├── frd/

├── erd/

├── api/

├── architecture/

├── deployment/

└── uiux/

---

# 4. Scripts

scripts/

├── build\_android.sh

├── build\_web.sh

├── deploy\_staging.sh

├── deploy\_prod.sh

└── backup\_db.sh

---

# 5. Main Flutter Structure

lib/

├── main.dart

├── bootstrap.dart

├── app/

├── core/

├── features/

├── shared/

└── generated/

---

# 6. App Layer

Purpose:

Application configuration.

app/

├── app.dart

├── routes/

├── theme/

├── config/

├── localization/

└── providers/

---

# Routes

routes/

├── app\_router.dart

├── auth\_routes.dart

├── customer\_routes.dart

├── pharmacy\_routes.dart

├── clinic\_routes.dart

├── dental\_routes.dart

├── crm\_routes.dart

├── admin\_routes.dart

└── settings\_routes.dart

---

# Theme

theme/

├── app\_theme.dart

├── app\_colors.dart

├── app\_spacing.dart

├── app\_radius.dart

├── app\_typography.dart

└── app\_shadows.dart

---

# Config

config/

├── environment.dart

├── api\_config.dart

├── storage\_config.dart

├── notification\_config.dart

└── app\_constants.dart

---

# 7. Core Layer

Purpose:

Reusable framework components.

core/

├── auth/

├── network/

├── storage/

├── permissions/

├── security/

├── notifications/

├── qr/

├── pdf/

├── ocr/

├── analytics/

├── audit/

├── exceptions/

├── utilities/

└── widgets/

---

# Auth Core

auth/

├── auth\_service.dart

├── auth\_provider.dart

├── token\_manager.dart

└── auth\_guard.dart

---

# Network Core

network/

├── dio\_client.dart

├── interceptors/

├── api\_response.dart

└── network\_checker.dart

---

# Storage Core

storage/

├── secure\_storage.dart

├── hive\_storage.dart

└── cache\_manager.dart

---

# OCR Core

ocr/

├── document\_classifier.dart

├── pdf\_extractor.dart

├── ocr\_processor.dart

└── extraction\_validator.dart

---

# PDF Core

pdf/

├── pdf\_viewer.dart

├── pdf\_uploader.dart

└── pdf\_manager.dart

---

# QR Core

qr/

├── qr\_generator.dart

├── qr\_scanner.dart

└── qr\_validator.dart

---

# 8. Shared Layer

Purpose:

Shared models and reusable resources.

shared/

├── models/

├── enums/

├── validators/

├── widgets/

├── extensions/

├── mixins/

├── constants/

└── helpers/

---

# Shared Models

models/

├── customer.dart

├── user.dart

├── membership.dart

├── wallet.dart

├── document.dart

├── appointment.dart

├── notification.dart

└── audit\_log.dart

---

# Shared Widgets

widgets/

├── app\_button.dart

├── app\_card.dart

├── app\_input.dart

├── app\_loader.dart

├── app\_dialog.dart

├── app\_table.dart

├── app\_search.dart

├── app\_empty\_state.dart

└── app\_error\_state.dart

---

# 9. Feature Structure

Every feature follows:

feature/

├── data/

├── domain/

├── presentation/

└── providers/

---

# Example

Customer Module

customers/

├── data/

│   ├── datasource/

│   ├── repository/

│   ├── dto/

│   └── models/

├── domain/

│   ├── entities/

│   ├── repository/

│   └── usecases/

├── presentation/

│   ├── screens/

│   ├── widgets/

│   └── controllers/

└── providers/

---

# 10. Features List

features/

├── authentication/

├── dashboard/

├── customers/

├── memberships/

├── shield\_cards/

├── wallet/

├── credit/

├── transactions/

├── documents/

├── document\_intelligence/

├── pharmacy/

├── clinic/

├── dental/

├── appointments/

├── crm/

├── complaints/

├── notifications/

├── reports/

├── users/

├── roles/

├── permissions/

├── businesses/

├── settings/

├── profile/

└── audit/

---

# 11. Dashboard Feature

dashboard/

├── data/

├── domain/

├── presentation/

│   ├── customer\_dashboard/

│   ├── pharmacy\_dashboard/

│   ├── clinic\_dashboard/

│   ├── dental\_dashboard/

│   ├── crm\_dashboard/

│   ├── shield\_dashboard/

│   └── admin\_dashboard/

└── providers/

---

# 12. Wallet Module

wallet/

├── data/

├── domain/

├── presentation/

│   ├── wallet\_dashboard/

│   ├── transactions/

│   ├── recharge/

│   └── statements/

└── providers/

---

# 13. Document Intelligence Module

document\_intelligence/

├── data/

├── domain/

├── presentation/

│   ├── upload/

│   ├── classification/

│   ├── extraction/

│   ├── validation/

│   └── processing\_logs/

└── providers/

---

# 14. CRM Module

crm/

├── data/

├── domain/

├── presentation/

│   ├── tasks/

│   ├── followups/

│   ├── complaints/

│   ├── notes/

│   └── dashboard/

└── providers/

---

# 15. State Management

Riverpod

Structure

providers/

├── auth\_provider.dart

├── customer\_provider.dart

├── wallet\_provider.dart

├── document\_provider.dart

├── appointment\_provider.dart

├── crm\_provider.dart

└── dashboard\_provider.dart

---

# 16. API Layer Structure

data/

├── datasource/

│   ├── remote/

│   └── local/

├── dto/

├── mapper/

└── repository/

---

# Remote APIs

remote/

├── auth\_api.dart

├── customer\_api.dart

├── wallet\_api.dart

├── document\_api.dart

├── appointment\_api.dart

├── crm\_api.dart

└── admin\_api.dart

---

# 17. Offline Support

offline/

├── sync\_manager.dart

├── offline\_queue.dart

├── conflict\_resolver.dart

└── retry\_manager.dart

Capabilities

* Offline Forms

* Offline Documents

* Offline Appointments

* Auto Sync

---

# 18. PWA Structure

web/

├── icons/

├── manifest.json

├── favicon.png

├── service\_worker.js

└── index.html

---

# 19. Environment Management

.env.dev

.env.staging

.env.prod

Environment Loader

environment.dart

---

# 20. Testing Structure

test/

├── unit/

├── widget/

├── integration/

└── mocks/

Coverage Goal

Minimum 80%

---

# 21. Build Targets

Android

flutter build apk

Android Bundle

flutter build appbundle

Web

flutter build web

PWA

flutter build web \--pwa-strategy\=offline-first

---

# 22. Architectural Principles

* Feature First

* Clean Architecture

* Modular Design

* Offline First

* Mobile First

* API First

* Scalable

* Testable

* Secure

* Maintainable

End of Flutter Architecture & Folder Structure Specification.