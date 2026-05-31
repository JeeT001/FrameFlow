# FrameFlow — Supabase backend

Schema migrations for the FrameFlow macOS app. The Swift client uses Supabase Auth today; profile and subscription rows are wired in **Day 30+**.

## Prerequisites

- A Supabase project (Dashboard → Project Settings → API for URL and anon key)
- Local app `Config.swift` already points at the same project (see `App/Utils/Config.example.swift`)

## Day 29 — Apply migration

### Option A: SQL Editor (recommended for MVP)

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project → **SQL Editor**.
2. Click **New query**.
3. Paste the full contents of:
   `supabase/migrations/20260529_users_subscriptions_rls.sql`
4. Click **Run**. Expect “Success. No rows returned.”

### Option B: Supabase CLI

```bash
# From repo root, after linking project: supabase link --project-ref <ref>
supabase db push
```

## What this migration creates

| Object | Purpose |
|--------|---------|
| `public.users` | Profile row keyed by `auth.users.id` |
| `public.subscriptions` | Plan/status for Pro gating (webhook writes in Day 30) |
| RLS | Users read/update/insert **own** row only; subscriptions **select own** only |
| Triggers | Auto-set `updated_at` on profile/subscription updates |
| Index | `subscriptions_user_id_idx` for lookups by user |

## Verify RLS

Use two test auth users (sign up in the app or Auth → Users in Dashboard).

### As User A (SQL Editor with “Run as user” or client with User A JWT)

```sql
-- Should return only User A's row after Day 30 insert
SELECT * FROM public.users;
SELECT * FROM public.subscriptions;
```

### Negative test

User A must **not** see User B's rows. With the anon key and no session, both queries should return empty or error:

```sql
-- Expect 0 rows or permission denied when not authenticated
SELECT * FROM public.users;
```

### Policy checklist

| Policy | Table | Operation | Rule |
|--------|-------|-----------|------|
| `users_select_own` | users | SELECT | `auth.uid() = id` |
| `users_update_own` | users | UPDATE | `auth.uid() = id` |
| `users_insert_own` | users | INSERT | `auth.uid() = id` |
| `subs_select_own` | subscriptions | SELECT | `auth.uid() = user_id` |

Subscriptions have **no** client INSERT/UPDATE policies; the Day 30 webhook uses the **service role** key.

## Rollback (dev only)

```sql
DROP TRIGGER IF EXISTS subscriptions_set_updated_at ON public.subscriptions;
DROP TRIGGER IF EXISTS users_set_updated_at ON public.users;
DROP FUNCTION IF EXISTS public.set_updated_at();
DROP TABLE IF EXISTS public.subscriptions;
DROP TABLE IF EXISTS public.users;
```

## Next (Day 31 — not in this migration)

- RevenueCat Purchases SDK + `SubscriptionManager` in the macOS app
- Wire `AppState.isPro` from RevenueCat / `public.subscriptions`

---

## Day 30 — UserService + RevenueCat webhook

### App (Swift)

After Day 29 migration is applied:

1. Sign up in the app → row appears in `public.users` (Table Editor).
2. Relaunch → session restore backfills profile if missing (`ensureUserProfile`).
3. Profile → Save name → `display_name` updated in DB + auth metadata.

### Deploy webhook

```bash
supabase secrets set REVENUECAT_WEBHOOK_SECRET=your-shared-secret
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

supabase functions deploy revenuecat-webhook --no-verify-jwt
```

Function URL: `https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook`

See `supabase/functions/revenuecat-webhook/README.md` for curl examples and product-id mapping.

### Verify webhook + RLS

1. Wrong `Authorization` header → **401**
2. Mock `INITIAL_PURCHASE` with valid secret and real `app_user_id` (UUID in `public.users`) → row in `public.subscriptions`
3. App client: user A cannot read user B's subscription (RLS `subs_select_own`)
