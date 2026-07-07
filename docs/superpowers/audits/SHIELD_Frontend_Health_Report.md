# SHIELD Frontend Health Report
Date: 2026-07-07
Repository: `E:\K4NN4N\shield`
Scope: Flutter frontend, GoRouter, Riverpod, portal shell, admin/provider/agent/customer portals, shared widgets, PWA/offline, UI/UX

## Frontend Verdict

The frontend has two generations living side by side:

1. A strong backend-driven admin runtime.
2. Older role-specific screens for provider, agent, and customer portals.

The admin runtime is the standard SHIELD should keep moving toward. The rest of the frontend is functional but not equally platform-disciplined.

Frontend health score: 64 / 100

## Architecture Summary

| Area | Status | Notes |
| --- | --- | --- |
| GoRouter | Good | Centralized route resolution and session redirects exist. |
| Portal resolver | OK | Resolves internal first, customer second. Simple and clear. |
| Portal shell | Weak | Still imports and branches across many role-specific screens. |
| Admin runtime | Good | Backend-owned workspace rendering is real. |
| Provider portal | Mixed | Customer workspace decomposed; provider controller and other screens remain bespoke. |
| Agent portal | Weak to OK | Feature-rich, but screen-specific and less runtime-driven. |
| Customer portal | OK | Calmer and simpler, but wallet/auth/copy still need precision. |
| Shared formatters | Good start | `AppDisplayFormatters` now covers core display types. |
| Tests | Partial | Useful focused tests exist, but full portal coverage is not enough. |

## Portal Shell Health

| Finding | Severity | Evidence | Recommendation |
| --- | --- | --- | --- |
| `portal_shell.dart` remains a hotspot. | Critical | Project map reports it as 10k+ lines and it imports admin, provider, agent, and customer screens. | Reduce to frame, nav, role resolution, and a role runtime outlet. |
| Shell owns too much role branching. | High | Provider/agent/customer content is still switched in shell. | Move each role family into its own runtime/router owner. |
| Compatibility routes exist. | OK | `/documents`, `/appointments`, `/wallet`, etc. redirect through portal resolver. | Keep compatibility but avoid parallel app paths. |

## Admin Portal Health

| Area | Status | Notes |
| --- | --- | --- |
| Workspace catalog | Good but transitional | All major admin module ids are registered as backend workspace ids. |
| Module wrappers | Good | Admin modules like customers are thin wrappers around `AdminBackendWorkspaceModule`. |
| Runtime controller | Good | Shared workspace loading/query behavior exists. |
| Data table | Improved | Sorting, selection, pagination, export, hover/density improvements exist. |
| Renderer | Good foundation | Metrics, tables, details, empty/error/offline states can be shared. |
| Query persistence | Started | Needs to become universal and tested. |
| Backend-owned contracts | Good direction | Still has fallback schemas in catalog. |

### Admin Portal Risks

| Risk | Severity |
| --- | --- |
| Fallback schemas can mask missing backend workspace metadata. | High |
| Generic backend renderer can make complex modules feel shallow if contracts are thin. | High |
| Reports, CRM, wallet, memberships, and providers need deeper workflows, not just tables. | Critical |
| Admin action metadata is strongest for customers; needs wider module coverage. | High |

## Provider Portal Health

| Area | Status | Notes |
| --- | --- | --- |
| Provider customers | Improved | Decomposed into shell, header strip, and tabbed detail pane. |
| Provider queue | OK | Correct operational center exists. |
| Provider dashboard | OK | Should stay queue-first. |
| Documents/prescriptions | OK but simple | Need better preview, confidence, and workflow actions. |
| Provider auth | Works but noisy | Debug traces remain in auth/repository paths. |
| Provider controller | Weak | Still large and owns many concepts. |

### Provider Customer Workspace

Current decomposition:

| Component | Role |
| --- | --- |
| `ProviderCustomersScreen` | Route/query coordination and composition. |
| `ProviderCustomersShell` | Search, suggestions, dense table/list shell. |
| `PatientHeaderStrip` | Compact selected patient summary and tab shortcuts. |
| `ProviderPatientTabbedDetailPane` | Documents, clinical notes, billing/wallet, timeline, prescriptions. |

This is a good remediation. It should be protected from regression.

### Provider Risks

| Risk | Severity |
| --- | --- |
| Provider scope must be tested across every patient-bound endpoint. | Critical |
| Provider screens outside customers are not runtime-driven. | Medium |
| Provider document preview and prescription review need stronger UX. | High |
| Debug logging remains in internal provider auth/runtime paths. | Medium |

## Agent Portal Health

| Area | Status | Notes |
| --- | --- | --- |
| Dashboard | OK | Should prioritize today's work. |
| Customers | OK | Needs stronger next-action/follow-up cues. |
| Follow-ups | Weak | Urgency grammar is not yet strong enough. |
| Documents | Weak to OK | Tests exist, but workflow framing needs more depth. |
| Settings | Weak | Large screen, mixed responsibilities. |
| Reports | Weak | Report shell usefulness is not proven. |
| Tests | Better than expected | Agent has accessibility, responsive, golden, settings, documents, follow-up tests. |

### Agent Risks

| Risk | Severity |
| --- | --- |
| Repeated `Future.microtask` loading patterns across screens. | Medium |
| Screen-specific architecture is not aligned with admin runtime. | High |
| Follow-up and CRM-style flows need task-first interaction. | High |
| Agent scope needs stronger backend tests. | High |

## Customer Portal Health

| Area | Status | Notes |
| --- | --- | --- |
| Auth | OK | OTP and registration paths exist with error mapping. |
| Dashboard | OK | Should keep action-first and avoid static summaries. |
| Wallet | Improved | Visible cash/rewards are separated from hidden benefit. |
| Documents | OK | Needs better status and preview confidence. |
| Membership | OK | Needs clearer lifecycle and benefit usage language. |
| Prescriptions | OK | Needs calm, clear clinical metadata. |

### Customer Wallet UX

Good:

| Behavior | Status |
| --- | --- |
| Cash and reward points are visible separately. | Implemented in customer wallet UI. |
| Internal SHIELD benefit is explained as behind-the-scenes support. | Implemented. |
| Customer-visible recent transactions filter out hidden benefit entries. | Implemented. |
| Transaction tile uses display formatters. | Implemented. |

Risk:

| Risk | Severity |
| --- | --- |
| Dashboard wallet summary must never reintroduce hidden benefit as a visible balance. | Critical |
| Provider/admin wallet views must label hidden benefit as internal support only. | Critical |
| Transaction model normalization must keep `REWARD_POINTS` and `SHIELD_BENEFIT` precise. | High |

## Shared UI and Formatting

| Utility | Status |
| --- | --- |
| `AppDisplayFormatters.formatDateOrDateTime` | Exists |
| `formatCurrencyString` | Exists |
| `formatPhone` | Exists |
| `formatStatusLabel` | Exists |
| `formatIdentifier` | Exists |

Remaining formatting gaps:

| Gap | Impact |
| --- | --- |
| Some model serialization still uses ISO strings internally. | Acceptable for transport, but dangerous if shown directly. |
| Some UI paths still call `toIso8601String` before formatting. | Usually safe if formatter handles it, but audit should continue. |
| Product-language normalization is not enforced by lint/test. | Copy regressions can return. |

## PWA and Offline Health

| Area | Status | Notes |
| --- | --- | --- |
| Manifest | Exists | Basic PWA surface exists. |
| Firebase messaging service worker | Exists | Push path is present. |
| Sentry web init | Exists | Observability path exists. |
| Hive caches | Exists for customer domains | Useful, but not comprehensive. |
| Offline mutation queue | Weak | No mature cross-domain offline outbox found. |
| Realtime fallback | Partial | Realtime channel exists, but fallback UX is not fully mature. |

## Accessibility Health

| Area | Status |
| --- | --- |
| Agent accessibility tests | Present |
| Basic Flutter semantics | Present by framework |
| Keyboard-first admin operations | Not fully proven |
| Row/checkbox separation | Improved in admin data table, needs continued testing |
| Focus and shortcut model | Incomplete |

## Performance Health

| Strength | Risk |
| --- | --- |
| Tables and pagination exist in admin runtime. | Some provider/agent screens still large. |
| Provider customer monolith was decomposed. | Provider controller remains large. |
| Search and query state improvements started. | Debounce/persistence not universal. |
| Customer cache service exists. | Offline cache invalidation needs stronger rules. |

## Frontend Priority Fixes

| Priority | Fix | Why |
| --- | --- | --- |
| Critical | Finish portal shell slimming. | Shell remains the largest frontend architectural risk. |
| Critical | Make admin runtime contracts deeper for wallet, CRM, reports, memberships, providers. | These modules must become workflows, not generic tables. |
| High | Remove or gate remaining debug logs. | Production UI should not leak diagnostic noise. |
| High | Normalize provider and agent portals around shared list/detail/action patterns. | Reduces drift and improves user trust. |
| High | Expand keyboard/focus behavior for admin tables and actions. | Enterprise users need fast keyboard operation. |
| Medium | Add visual/copy regression tests for wallet hidden benefit language. | Prevents dangerous financial misrepresentation. |
| Medium | Improve PWA offline states and retry affordances. | Protects field and provider use cases. |

## Frontend Conclusion

The frontend has a good future path, but it is uneven today. Admin is a platform. Provider is improving. Agent is useful but still bespoke. Customer is calm but trust-sensitive. The next frontend work should reduce shell centrality, make provider/agent more runtime-like, protect wallet language, and add tests that prevent UX regressions.

