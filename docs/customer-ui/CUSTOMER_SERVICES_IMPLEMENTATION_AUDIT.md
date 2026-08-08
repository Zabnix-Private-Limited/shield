# Customer Services implementation audit

Audited: 2026-08-08.

The former `/portal/customer/services` inline view mixed wellness products, prescription upload, provider selection, and booking. The active Services route now renders the extracted customer discovery feature. The original inline workflow remains active only at `/portal/customer/book-appointment`, preserving existing booking behavior while migration continues.

Supported: active provider category/list/search/detail summary, route-backed `type`, trimmed `q`, loaded `page`, and `provider` detail state; browser/detail back restoration; stale-search protection; duplicate-safe load-more pagination; type-aware customer copy/iconography; Pharmacy-to-existing-prescription entry; wellness shop as a separate existing route; booking entry; loading, empty, error/retry, and responsive scroll-safe filter chips. The booking route does not currently accept provider preselection, so this remains a Booking-module contract gap rather than a duplicated booking flow.

Unavailable by contract: exact nearby/distance, covered services, popular/recommended ranking, favourites/recently viewed, customer-safe ratings/languages/hours/prices, practitioner profiles, provider images, and insurance-provider directory. No unavailable feature is simulated.
