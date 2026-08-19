# Notifications & Cross-Portal Event Contract

## Goal

Every user-impacting Pharmacy workflow change should have a defined notification policy. Notifications must be event-driven from backend truth, not fabricated by the UI.

## Event matrix

| Event | Pharmacy staff | Customer | Notes |
|---|---|---|---|
| New pharmacy order | Yes | Optional acknowledgement | push/in-app |
| Order accepted | Optional | Yes | status update |
| Partial approval proposed | Yes | Yes | include affected items |
| Item rejected | Yes | Yes | reason |
| Substitute proposed | Yes | Yes | confirmation may be required |
| Substitute confirmed | Yes | Yes | update order |
| Invoice uploaded | Optional | Yes when sent | private document |
| Invoice sent | Optional | Yes | notification/deep link |
| Ready for pickup | Yes | Yes | pickup details |
| Out for delivery | Yes | Yes | delivery status |
| Partial dispatch | Yes | Yes | explain remaining items |
| Completed | Optional | Yes | final status |
| Cancelled | Yes | Yes | reason |
| Manual payment submitted | Yes | Optional | Pharmacy action required |
| Payment approved | Optional | Yes | wallet/payment result |
| Payment rejected | Optional | Yes | include reason |
| Chronic refill reminder | Yes/configurable | Yes/configurable | future feature contract |

## Channels

Supported channel availability may vary:
- In-app
- Push notification
- Email
- SMS
- WhatsApp only if a real provider/integration exists

Do not show a working WhatsApp/SMS toggle if there is no backend delivery integration.

## Payload principles

Notifications should carry:
- event type
- order/payment/customer-safe identifier
- concise human message
- deep-link target
- timestamp
- provider context
- optional action required

Never place sensitive medical detail in lock-screen push text unless explicitly permitted by product/privacy policy.

## Cross-portal scope

Pharmacy can emit backend events consumed by Customer/other portals. During Pharmacy-only implementation, do not redesign other portal UIs. Record required consumer changes in `todo.md` when outside current scope.

## Deep links

Examples:
```text
pharmacy order event -> Pharmacy Orders detail
customer order event -> Customer order detail (future/when supported)
payment alert -> Pharmacy Payment review
invoice sent -> Customer order/invoice view
```

Backend IDs must be authorization-checked after navigation.
