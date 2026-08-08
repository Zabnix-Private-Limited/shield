# Customer Notifications API Matrix

Classification: `COMPLETE — SUPPORTED FUNCTIONAL SCOPE`

| Capability | Route | API | Customer rule | Classification |
| --- | --- | --- | --- | --- |
| Inbox/unread count | Notifications | `GET /notifications/me` | Session-derived customer; safe projection | Supported |
| Mark one read | Notifications | `POST /notifications/:id/read` | Existing ownership check verifies notification/customer match | Supported |
| Mark all read | Notifications | `POST /notifications/mark-all-read` | Existing mutation pins scope to authenticated customer | Supported |
| Category/filter/detail | Notifications | Safe inbox response | UI derives category from safe title/message; detail is local sheet | Supported |
| Deep-link metadata | — | — | Notification schema has no safe stored action payload | Deferred |
| Server pagination | — | — | Current schema/contract has no pagination parameters | Deferred |

Database source: `notifications` in `current_schema.md`. No SQL is required.
