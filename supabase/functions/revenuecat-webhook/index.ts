// FrameFlow Day 30 — RevenueCat webhook → public.subscriptions (service role)
// Deploy: supabase functions deploy revenuecat-webhook --no-verify-jwt

import { createClient } from "npm:@supabase/supabase-js@2";

// --- Product ID → plan mapping (update when RevenueCat products are configured) ---
const PLAN_LIFETIME = "lifetime";
const PLAN_ANNUAL = "pro_annual";
const PLAN_MONTHLY = "pro_monthly";
const PLAN_FREE = "free";

function mapProductToPlan(productId: string | undefined): string {
  if (!productId) return PLAN_MONTHLY;
  const id = productId.toLowerCase();
  if (id.includes("lifetime")) return PLAN_LIFETIME;
  if (id.includes("annual")) return PLAN_ANNUAL;
  if (id.includes("monthly")) return PLAN_MONTHLY;
  return PLAN_MONTHLY;
}

const HANDLED_EVENTS = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "CANCELLATION",
  "EXPIRATION",
  "BILLING_ISSUE",
]);

type RevenueCatPayload = {
  event?: {
    type?: string;
    app_user_id?: string;
    product_id?: string;
    expiration_at_ms?: number | null;
    grace_period_expiration_at_ms?: number | null;
    trial_expiration_at_ms?: number | null;
    original_app_user_id?: string;
    aliases?: string[];
  };
  api_version?: string;
};

function msToIso(ms: number | null | undefined): string | null {
  if (ms == null || Number.isNaN(ms)) return null;
  return new Date(ms).toISOString();
}

function unauthorized(): Response {
  return new Response(JSON.stringify({ error: "Unauthorized" }), {
    status: 401,
    headers: { "Content-Type": "application/json" },
  });
}

function badRequest(message: string): Response {
  return new Response(JSON.stringify({ error: message }), {
    status: 400,
    headers: { "Content-Type": "application/json" },
  });
}

function ok(body: Record<string, unknown> = { ok: true }): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return badRequest("POST required");
  }

  const secret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
  if (!secret) {
    console.error("REVENUECAT_WEBHOOK_SECRET not set");
    return badRequest("Server misconfigured");
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const expectedBearer = `Bearer ${secret}`;
  if (authHeader !== secret && authHeader !== expectedBearer) {
    return unauthorized();
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return badRequest("Server misconfigured");
  }

  let payload: RevenueCatPayload;
  try {
    payload = await req.json();
  } catch {
    return badRequest("Invalid JSON body");
  }

  const event = payload.event;
  const eventType = event?.type;
  if (!eventType || !HANDLED_EVENTS.has(eventType)) {
    return badRequest(`Unknown or missing event type: ${eventType ?? "none"}`);
  }

  const appUserId = event?.app_user_id;
  if (!appUserId) {
    return badRequest("Missing app_user_id");
  }

  const parsed = appUserId.trim();
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(parsed)) {
    return badRequest(`Invalid app_user_id UUID: ${appUserId}`);
  }
  const userId = parsed;

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userRow, error: userError } = await supabase
    .from("users")
    .select("id")
    .eq("id", userId)
    .maybeSingle();

  if (userError) {
    console.error("users lookup failed", userError);
    return badRequest("User lookup failed");
  }

  if (!userRow) {
    console.warn(`No public.users row for ${userId}; webhook requires Day 30 profile sync`);
    return badRequest(`User ${userId} not found in public.users`);
  }

  const productId = event.product_id;
  const revenuecatId = event.original_app_user_id ?? appUserId;
  const periodEndMs =
    event.expiration_at_ms ??
    event.grace_period_expiration_at_ms ??
    null;
  const trialEndMs = event.trial_expiration_at_ms ?? null;

  let status = "active";
  let plan = mapProductToPlan(productId);

  switch (eventType) {
    case "INITIAL_PURCHASE":
      status = "active";
      plan = mapProductToPlan(productId);
      break;
    case "RENEWAL":
      status = "active";
      break;
    case "CANCELLATION":
      status = "cancelled";
      break;
    case "EXPIRATION":
      status = "expired";
      plan = PLAN_FREE;
      break;
    case "BILLING_ISSUE":
      status = "past_due";
      break;
  }

  const row = {
    user_id: userId,
    plan,
    status,
    revenuecat_id: revenuecatId,
    current_period_end: msToIso(periodEndMs),
    trial_end: msToIso(trialEndMs),
  };

  const { data: existing, error: selectError } = await supabase
    .from("subscriptions")
    .select("id")
    .eq("user_id", userId)
    .maybeSingle();

  if (selectError) {
    console.error("subscriptions select failed", selectError);
    return badRequest("Subscription lookup failed");
  }

  if (existing?.id) {
    const { error: updateError } = await supabase
      .from("subscriptions")
      .update(row)
      .eq("user_id", userId);

    if (updateError) {
      console.error("subscriptions update failed", updateError);
      return badRequest("Subscription update failed");
    }
  } else {
    const { error: insertError } = await supabase.from("subscriptions").insert(row);

    if (insertError) {
      console.error("subscriptions insert failed", insertError);
      return badRequest("Subscription insert failed");
    }
  }

  return ok({ event: eventType, user_id: userId, plan, status });
});
