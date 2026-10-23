import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "@supabase/supabase-js";
import { importPKCS8, SignJWT } from "jose";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type FirebaseServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
};

type FcmError = {
  error?: {
    details?: Array<{ errorCode?: string }>;
    message?: string;
    status?: string;
  };
};

function normalizePrivateKey(value: string): string {
  let privateKey = value.trim();
  if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
    try {
      privateKey = JSON.parse(privateKey) as string;
    } catch {
      // Keep the original value so the PEM validation reports the problem.
    }
  }

  return privateKey
    .replace(/\\+r\\+n/g, "\n")
    .replace(/\\+n/g, "\n")
    .replace(/\r\n/g, "\n");
}

let cachedAccessToken: string | undefined;
let cachedAccessTokenExpiresAt = 0;

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function getGoogleAccessToken(
  credentials: FirebaseServiceAccount,
): Promise<string> {
  if (cachedAccessToken && cachedAccessTokenExpiresAt > Date.now() + 60_000) {
    return cachedAccessToken;
  }

  const privateKey = normalizePrivateKey(credentials.private_key);
  if (!privateKey.startsWith("-----BEGIN PRIVATE KEY-----")) {
    throw new Error("Firebase private key is not an unencrypted PKCS#8 PEM");
  }
  const encodedKey = privateKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  if (!/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(encodedKey)) {
    const invalidCharacterCount = [...encodedKey].filter(
      (character) => !/[A-Za-z0-9+/=]/.test(character),
    ).length;
    throw new Error(
      `Firebase private key has invalid base64 (length ${encodedKey.length}, invalid characters ${invalidCharacterCount})`,
    );
  }
  const key = await importPKCS8(privateKey, "RS256");
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(credentials.client_email)
    .setSubject(credentials.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(key);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  const result = await response.json();
  if (!response.ok || typeof result.access_token !== "string") {
    throw new Error(`Google OAuth failed: ${JSON.stringify(result)}`);
  }

  cachedAccessToken = result.access_token;
  cachedAccessTokenExpiresAt = Date.now() + Number(result.expires_in) * 1000;
  return cachedAccessToken;
}

async function sendToToken(
  accessToken: string,
  projectId: string,
  token: string,
  order: { id: string; order_number: string },
): Promise<{ ok: boolean; invalidToken: boolean; error?: string }> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: {
            title: "طلب جديد 🔔",
            body: "لديك طلب جديد من أحد العملاء",
          },
          data: {
            type: "new_order",
            orderId: order.id,
            orderNumber: order.order_number,
          },
          android: {
            priority: "HIGH",
            notification: {
              channel_id: "new_orders",
              sound: "new_order",
              tag: `new_order_${order.id}`,
              default_vibrate_timings: false,
              vibrate_timings: ["0s", "0.5s", "0.25s", "0.5s"],
            },
          },
        },
      }),
    },
  );

  if (response.ok) return { ok: true, invalidToken: false };

  const error = (await response.json()) as FcmError;
  const code = error.error?.details?.find((detail) => detail.errorCode)
    ?.errorCode;
  return {
    ok: false,
    invalidToken: code === "UNREGISTERED" || response.status === 404,
    error: error.error?.message ?? `FCM returned HTTP ${response.status}`,
  };
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const serviceAccountValue = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  const pushSecret = Deno.env.get("ADMIN_ORDER_PUSH_SECRET");
  const credentials: FirebaseServiceAccount = serviceAccountValue
    ? JSON.parse(serviceAccountValue) as FirebaseServiceAccount
    : {
      client_email: Deno.env.get("FIREBASE_CLIENT_EMAIL") ?? "",
      private_key: Deno.env.get("FIREBASE_PRIVATE_KEY") ?? "",
      project_id: Deno.env.get("FIREBASE_PROJECT_ID") ?? "",
    };
  if (
    !supabaseUrl || !serviceRoleKey || !pushSecret ||
    !credentials.client_email || !credentials.private_key ||
    !credentials.project_id
  ) {
    return jsonResponse({ error: "Server push configuration is incomplete" }, 500);
  }
  if (request.headers.get("x-admin-order-secret") !== pushSecret) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  let orderId: string;
  try {
    const body = await request.json();
    orderId = typeof body.orderId === "string" ? body.orderId : "";
  } catch {
    return jsonResponse({ error: "Invalid request body" }, 400);
  }
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(orderId)) {
    return jsonResponse({ error: "A valid orderId is required" }, 400);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  try {
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("id, order_number, created_at")
      .eq("id", orderId)
      .maybeSingle();
    if (orderError) throw orderError;
    if (!order) return jsonResponse({ error: "Order not found" }, 404);

    const { data: claimed, error: claimError } = await supabase.rpc(
      "claim_admin_order_push",
      { p_order_id: order.id },
    );
    if (claimError) throw claimError;
    if (claimed !== true) {
      return jsonResponse({ status: "already_sent_or_in_progress" });
    }

    const { data: devices, error: devicesError } = await supabase
      .from("admin_device_tokens")
      .select("token")
      .eq("is_active", true);
    if (devicesError) throw devicesError;
    if (!devices?.length) {
      await supabase
        .from("admin_order_pushes")
        .update({ status: "failed", last_error: "No active admin devices" })
        .eq("order_id", order.id);
      return jsonResponse({ status: "no_active_admin_devices" }, 202);
    }

    const accessToken = await getGoogleAccessToken(credentials);
    const results = await Promise.all(
      devices.map(async ({ token }) => {
        const result = await sendToToken(accessToken, credentials.project_id, token, order);
        if (result.invalidToken) {
          await supabase
            .from("admin_device_tokens")
            .update({ is_active: false, updated_at: new Date().toISOString() })
            .eq("token", token);
        }
        return result;
      }),
    );

    const sentCount = results.filter((result) => result.ok).length;
    const failures = results
      .filter((result) => !result.ok)
      .map((result) => result.error)
      .filter(Boolean);
    await supabase
      .from("admin_order_pushes")
      .update({
        status: sentCount > 0 ? "sent" : "failed",
        sent_at: sentCount > 0 ? new Date().toISOString() : null,
        last_error: failures.length ? failures.join("; ").slice(0, 1000) : null,
      })
      .eq("order_id", order.id);

    if (sentCount === 0) {
      return jsonResponse({ error: "FCM delivery failed", failures }, 502);
    }
    return jsonResponse({ status: "sent", sentCount, failedCount: failures.length });
  } catch (error) {
    console.error("Admin order push failed", error);
    await supabase
      .from("admin_order_pushes")
      .update({ status: "failed", last_error: String(error).slice(0, 1000) })
      .eq("order_id", orderId);
    return jsonResponse({ error: "Unable to send admin order push" }, 500);
  }
});
