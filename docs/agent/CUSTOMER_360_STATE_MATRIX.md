# Customer 360 state matrix

| State | Behaviour |
|---|---|
| Loading | The existing agent controller exposes a workspace loading state. |
| No assigned customers | Customer list renders a scoped empty state. |
| Invalid/foreign route ID | Backend returns forbidden/not-found; no customer data is rendered. |
| Empty tab source | Each tab renders an explicit empty state. |
| Update/action failure | Existing controller preserves the error state; the selected workspace is not optimistically fabricated. |
| Narrow viewport | List and detail panes stack below 1080 logical pixels; summary columns stack below 920. |
