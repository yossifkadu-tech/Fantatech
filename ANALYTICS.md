# Fantatech — Analytics & Product Tracking

## Overview

This document describes the **options and recommended approach** for tracking user interactions with the Products screen — specifically:
- How many times users click product links (outbound traffic)
- How many purchases / transactions are estimated from those clicks

---

## Option A — Local Hub Analytics (No Cloud, Recommended for Privacy)

Store all events **locally** on the Hub server. No external dependency.

### How it works
- Frontend calls `POST /api/analytics/event` with event data
- Hub writes a row to `analytics.db` (SQLite)
- Admin panel queries `GET /api/analytics/products` to view counts

### Event shape
```json
{
  "event":      "product_click",
  "product_id": "sonoff-basic",
  "product_name": "Sonoff Basic R2",
  "url":        "https://amzn.to/...",
  "lang":       "he",
  "timestamp":  "2026-05-07T14:32:00Z"
}
```

### Hub route additions (hub/routes/analytics.py)
```python
# POST /api/analytics/event
# GET  /api/analytics/products   → { product_id, clicks, last_click }
# GET  /api/analytics/summary    → total clicks, estimated CTR, top product
```

### SQLite table
```sql
CREATE TABLE analytics_events (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  event      TEXT NOT NULL,
  product_id TEXT,
  product_name TEXT,
  url        TEXT,
  lang       TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);
```

### Pros
- 100% private — no data leaves the home network
- Works offline
- Simple to query / export

### Cons
- Only captures events from devices connected to the Hub
- No cross-device aggregation

---

## Option B — Google Analytics 4 (GA4) via gtag.js

Add GA4 to the React app and fire a custom event on each product click.

### How it works
```js
// In PromoCarousel.jsx → on product click
window.gtag?.('event', 'product_click', {
  product_id:   'sonoff-basic',
  product_name: 'Sonoff Basic R2',
  currency:     'ILS',
  value:        0,           // set to product price if known
})
```

### Pros
- Free, rich dashboard
- Funnel analysis, retention, geo
- Can track estimated conversions via GA4 goals

### Cons
- Requires network access + Google account
- Privacy: data goes to Google servers
- Requires GDPR / CCPA banner for EU/CA users

---

## Option C — Plausible / Umami (Self-hosted, Privacy-first)

Use an open-source analytics server running on the Hub machine or a cheap VPS.

### How it works
- Deploy **Umami** (Node.js) on the same server as the Hub
- One `<script>` tag in index.html
- Custom events via `window.umami.track('product_click', { product_id })`

### Pros
- GDPR-compliant, no cookies, no IP storage
- Beautiful dashboard at `http://localhost:3001`
- Works on local network

### Cons
- Additional service to run and maintain
- Requires Node.js on Hub machine

---

## Option D — Simple CSV / JSON Log File (Minimal)

No server code — just append to a log file in the Hub's `data/` directory.

```
timestamp,event,product_id,lang
2026-05-07T14:32:00Z,product_click,sonoff-basic,he
2026-05-07T14:35:10Z,product_click,ezviz-cam,en
```

### Pros
- Zero dependencies
- Trivially parseable with Excel / Python
- Survives restarts

### Cons
- No real-time UI
- Manual analysis required

---

## Recommended Implementation: Option A + Option B (Hybrid)

1. **Always log locally** (Option A) — privacy-safe, always works
2. **Optionally send to GA4** if `VITE_GA_ID` env var is set — for rich dashboards

### Frontend changes needed

**`PromoCarousel.jsx`** — wrap each product link in a tracking handler:
```jsx
function trackProductClick(product) {
  // Local Hub
  fetch('/api/analytics/event', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      event: 'product_click',
      product_id: product.id,
      product_name: product.name,
      url: product.url,
    }),
  }).catch(() => {})

  // GA4 (optional)
  window.gtag?.('event', 'product_click', {
    product_id:   product.id,
    product_name: product.name,
  })
}
```

### Hub changes needed

**`hub/routes/analytics.py`** — new file:
```python
from fastapi import APIRouter
from hub.db import get_db

router = APIRouter(prefix="/analytics")

@router.post("/event")
async def log_event(payload: dict):
    db = get_db()
    db.execute(
        "INSERT INTO analytics_events (event, product_id, product_name, url, lang) VALUES (?,?,?,?,?)",
        (payload.get("event"), payload.get("product_id"),
         payload.get("product_name"), payload.get("url"), payload.get("lang"))
    )
    db.commit()
    return {"ok": True}

@router.get("/products")
async def product_stats():
    db = get_db()
    rows = db.execute(
        "SELECT product_id, product_name, COUNT(*) as clicks, MAX(created_at) as last_click "
        "FROM analytics_events WHERE event='product_click' "
        "GROUP BY product_id ORDER BY clicks DESC"
    ).fetchall()
    return [dict(r) for r in rows]

@router.get("/summary")
async def summary():
    db = get_db()
    total = db.execute("SELECT COUNT(*) FROM analytics_events").fetchone()[0]
    top   = db.execute(
        "SELECT product_id, COUNT(*) as c FROM analytics_events "
        "WHERE event='product_click' GROUP BY product_id ORDER BY c DESC LIMIT 1"
    ).fetchone()
    return {
        "total_events": total,
        "top_product":  dict(top) if top else None,
    }
```

---

## Transaction Count Estimation

Actual purchase tracking requires an affiliate program. Recommended platforms:

| Platform | Commission | Tracking |
|----------|-----------|---------|
| Amazon Affiliates (IL) | 3–8% | `tag=fantatech-20` in URL |
| AliExpress Portals | 3–6% | Deep link with affiliate ID |
| KSP / Bug.co.il | Negotiated | API or postback URL |

### Affiliate URL format
```
https://www.amazon.com/dp/B08C7KG5LP?tag=fantatech-20
```
Any purchase within 24 hours of click = attributed commission in Amazon dashboard.

---

## Dashboard UI (Settings Page)

Add a new section in `SettingsPage.jsx` → **📊 Product Analytics**:
- List of products with click counts
- Last-click timestamp
- "Export CSV" button

---

*Last updated: 2026-05-07 | Fantatech v1.9.0*
