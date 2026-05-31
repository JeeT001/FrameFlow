# revenuecat-webhook

RevenueCat server notification handler for FrameFlow. Writes to `public.subscriptions` using the Supabase **service role** (bypasses RLS).

## Secrets (Supabase Dashboard → Edge Functions → Secrets)

| Secret | Description |
|--------|-------------|
| `REVENUECAT_WEBHOOK_SECRET` | Shared secret; RevenueCat sends `Authorization: Bearer <secret>` |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (never ship in the macOS app) |
| `SUPABASE_URL` | Project URL (often auto-injected on deploy) |

## Deploy

From repo root (with [Supabase CLI](https://supabase.com/docs/guides/cli) linked):

```bash
supabase secrets set REVENUECAT_WEBHOOK_SECRET=your-shared-secret
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

supabase functions deploy revenuecat-webhook --no-verify-jwt
```

`--no-verify-jwt` allows RevenueCat to POST without a Supabase user JWT. Authorization is validated against `REVENUECAT_WEBHOOK_SECRET` inside the function.

Copy the function URL into RevenueCat → Project → Integrations → Webhooks.

## Product → plan mapping

Edit constants at the top of `index.ts`:

| Pattern in `product_id` | `plan` value |
|-------------------------|--------------|
| contains `monthly` | `pro_monthly` |
| contains `annual` | `pro_annual` |
| contains `lifetime` | `lifetime` |
| `EXPIRATION` event | `free` |

Update when App Store / RevenueCat product identifiers are finalized.

## Events handled

| Event | `status` | Notes |
|-------|----------|-------|
| `INITIAL_PURCHASE` | `active` | Sets plan from product |
| `RENEWAL` | `active` | Updates `current_period_end` |
| `CANCELLATION` | `cancelled` | |
| `EXPIRATION` | `expired` | Plan → `free` |
| `BILLING_ISSUE` | `past_due` | |

Unknown event types → **400**.

## User FK requirement

`app_user_id` must be a UUID matching `public.users.id`. If the user row is missing (never signed in / profile not synced), the function returns **400** with a clear error. Ensure Day 30 app profile sync runs before expecting webhooks to succeed.

## Manual test (curl)

Replace placeholders:

```bash
curl -i -X POST "https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook" \
  -H "Authorization: Bearer YOUR_WEBHOOK_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "api_version": "1.0",
    "event": {
      "type": "INITIAL_PURCHASE",
      "app_user_id": "YOUR-USER-UUID",
      "product_id": "frameflow_pro_monthly",
      "expiration_at_ms": 1893456000000,
      "original_app_user_id": "YOUR-USER-UUID"
    }
  }'
```

- Wrong secret → **401**
- Valid secret + unknown event → **400**
- Valid `INITIAL_PURCHASE` + existing `public.users` row → **200** and row in `public.subscriptions`

Verify RLS: signed-in user A cannot `SELECT` user B's subscription from the app (service role bypasses RLS only inside this function).
