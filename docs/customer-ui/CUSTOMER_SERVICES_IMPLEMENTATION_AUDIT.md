# Customer Services implementation audit

Audited: 2026-08-06.

The former `/portal/customer/services` inline view mixed wellness products, prescription upload, provider selection, and booking. The active Services route now renders the extracted customer discovery feature. The original inline workflow remains active only at `/portal/customer/book-appointment`, preserving existing booking behavior while migration continues.

Supported: active provider category/list/search/detail summary, load-more pagination, wellness shop as a separate existing route, booking entry, prescription route, loading, empty, error/retry, and responsive scroll-safe filter chips.

Unavailable by contract: exact nearby/distance, covered services, popular/recommended ranking, favourites/recently viewed, customer-safe ratings/languages/hours/prices, practitioner profiles, provider images, and insurance-provider directory. No unavailable feature is simulated.
