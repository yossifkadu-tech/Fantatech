// ─────────────────────────────────────────────────────────────────────────────
// ai-agent — Supabase Edge Function
//
// Thin, stateless proxy between the FantaTech Flutter app and the Anthropic
// Messages API. Holds the ANTHROPIC_API_KEY server-side (set via
// `supabase secrets set`) — it must never reach the client or the repo.
//
// This function does NOT execute smart-home commands itself. It only talks
// to Claude and returns its response (which may contain `tool_use` blocks).
// The Flutter app is the one with access to the real device/gateway layer,
// so it executes any requested tool locally and calls this function again
// with a `tool_result` appended — a normal Anthropic tool-use loop.
//
// Request body:
//   { "messages": [...Anthropic message objects...],
//     "devices":  [{ id, name, type, room, isOn, attributes }, ...],
//     "locale":   "he" | "en" | ... }
//
// Response body: the raw Anthropic Messages API response JSON.
// ─────────────────────────────────────────────────────────────────────────────

const ANTHROPIC_VERSION = "2023-06-01";
const MODEL = "claude-sonnet-5";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ── Tools the agent may call. Each one maps 1:1 to a real AppState/
// DeviceCommander method on the Flutter side — the agent never invents a
// capability that doesn't exist in the app.
const TOOLS = [
  {
    name: "set_power",
    description:
      "Turn a device on or off (lights, switches, plugs, climate power, etc.). Use the exact device id from the device list provided.",
    input_schema: {
      type: "object",
      properties: {
        device_id: { type: "string", description: "Exact device id from the device list." },
        on: { type: "boolean", description: "true to turn on, false to turn off." },
      },
      required: ["device_id", "on"],
    },
  },
  {
    name: "set_brightness",
    description: "Set a dimmable light's brightness, 0-100 percent.",
    input_schema: {
      type: "object",
      properties: {
        device_id: { type: "string" },
        percent: { type: "integer", minimum: 0, maximum: 100 },
      },
      required: ["device_id", "percent"],
    },
  },
  {
    name: "set_cover_position",
    description: "Set a blind/cover/valve position, 0 (fully closed) to 100 (fully open).",
    input_schema: {
      type: "object",
      properties: {
        device_id: { type: "string" },
        position: { type: "integer", minimum: 0, maximum: 100 },
      },
      required: ["device_id", "position"],
    },
  },
  {
    name: "set_climate",
    description: "Change an AC/climate device's mode, target temperature, or fan speed. Provide only the field being changed.",
    input_schema: {
      type: "object",
      properties: {
        device_id: { type: "string" },
        hvac_mode: { type: "string", description: "e.g. cool, heat, auto, off" },
        temperature: { type: "number" },
        fan_mode: { type: "string", description: "e.g. low, medium, high, auto" },
      },
      required: ["device_id"],
    },
  },
  {
    name: "set_security_mode",
    description: "Arm or disarm the home security system.",
    input_schema: {
      type: "object",
      properties: {
        mode: {
          type: "string",
          enum: ["disarmed", "armedHome", "armedAway"],
        },
      },
      required: ["mode"],
    },
  },
];

function systemPrompt(devices: unknown, locale: string): string {
  return `You are the FantaTech smart-home voice assistant. You control real devices in the user's home through the tools provided — you never simulate or pretend a tool ran.

Rules you must always follow:
- Understand intent, not just keywords. Handle follow-ups like "turn them off too" or "do the same upstairs" using the conversation history you're given.
- Reply conversationally, briefly, and naturally — you are not a command-line tool.
- When the user's request requires a device action, call the matching tool. Never claim an action succeeded, is in progress, or will happen unless a tool_result actually confirms it — if a tool_result reports failure, say so honestly and offer to retry or suggest an alternative.
- If a request is ambiguous (e.g. "turn off the lights" and there are lights in several rooms), ask a short clarifying question instead of guessing.
- Respond in the user's language (locale hint: ${locale}). Keep replies short enough to sound natural when read aloud by text-to-speech.
- Only use device ids that literally appear in the device list below — never invent one.

Current devices in the home:
${JSON.stringify(devices)}`;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "ANTHROPIC_API_KEY is not configured on the server." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { messages, devices, locale } = await req.json();
    if (!Array.isArray(messages)) {
      return new Response(JSON.stringify({ error: "messages[] is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": ANTHROPIC_VERSION,
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 1024,
        system: systemPrompt(devices ?? [], locale ?? "en"),
        tools: TOOLS,
        messages,
      }),
    });

    const body = await res.text();
    return new Response(body, {
      status: res.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
