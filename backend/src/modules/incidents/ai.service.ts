import { config } from "../common/config.js";

export interface IncidentAnalysisResult {
  summary: string;
  recommendedSeverity: "low" | "medium" | "high" | "critical";
  keyRisks: string[];
  recommendedUnits: ("fire" | "medical" | "police")[];
  emergencyAdvice: string[];
}

export interface ChatHistoryMessage {
  role: "user" | "model" | "assistant";
  text: string;
}

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || process.env.GOOGLE_AI_API_KEY || "";
const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-1.5-flash";

/**
 * Call Google Gemini REST API model
 */
async function callGeminiModel(
  systemInstruction: string,
  contents: { role: "user" | "model"; parts: { text: string }[] }[],
  jsonResponse: boolean = false
): Promise<string | null> {
  if (!GEMINI_API_KEY) return null;

  try {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;
    const body: any = {
      systemInstruction: {
        parts: [{ text: systemInstruction }],
      },
      contents,
    };

    if (jsonResponse) {
      body.generationConfig = { responseMimeType: "application/json" };
    }

    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errText = await response.text();
      console.warn(`[Gemini API Error] ${response.status}: ${errText}`);
      return null;
    }

    const data = await response.json();
    const candidate = data.candidates?.[0];
    const text = candidate?.content?.parts?.[0]?.text;
    return text || null;
  } catch (err) {
    console.error("[Gemini API Exception]", err);
    return null;
  }
}

export async function analyzeIncidentReport(incident: {
  title: string;
  type: string;
  description?: string | null;
  severity?: string;
  barangay_name?: string;
  address?: string | null;
}): Promise<IncidentAnalysisResult> {
  // Attempt Real Gemini Model Analysis if GEMINI_API_KEY is available
  if (GEMINI_API_KEY) {
    const systemPrompt = `You are IRMS AI, an expert emergency incident situational analyzer for public safety dispatchers.
Analyze the provided emergency incident details and output a JSON object adhering to this EXACT structure:
{
  "summary": "Concise 1-2 sentence tactical summary for dispatchers",
  "recommendedSeverity": "low" | "medium" | "high" | "critical",
  "keyRisks": ["Risk 1", "Risk 2"],
  "recommendedUnits": ["fire" | "medical" | "police"],
  "emergencyAdvice": ["Safety/First-Aid instruction 1", "Instruction 2"]
}`;

    const userPrompt = `Incident Title: ${incident.title}
Category: ${incident.type}
Severity: ${incident.severity || 'unspecified'}
Location: ${incident.barangay_name || incident.address || 'unknown'}
Description: ${incident.description || 'none'}`;

    const geminiReply = await callGeminiModel(
      systemPrompt,
      [{ role: "user", parts: [{ text: userPrompt }] }],
      true
    );

    if (geminiReply) {
      try {
        const parsed = JSON.parse(geminiReply);
        return {
          summary: parsed.summary || `AI Tactical Analysis for ${incident.type.toUpperCase()}`,
          recommendedSeverity: (["low", "medium", "high", "critical"].includes(parsed.recommendedSeverity) ? parsed.recommendedSeverity : "medium") as any,
          keyRisks: Array.isArray(parsed.keyRisks) ? parsed.keyRisks : ["Potential situational escalation"],
          recommendedUnits: Array.isArray(parsed.recommendedUnits) ? parsed.recommendedUnits.filter((u: string) => ["fire", "medical", "police"].includes(u)) : ["police"],
          emergencyAdvice: Array.isArray(parsed.emergencyAdvice) ? parsed.emergencyAdvice : ["Keep clear of scene."],
        };
      } catch (err) {
        console.warn("[Gemini JSON Parse Error, falling back to rule engine]", err);
      }
    }
  }

  // Fallback Heuristic / Keyword Rule Analysis Engine
  const text = `${incident.title} ${incident.type} ${incident.description ?? ""} ${incident.address ?? ""}`.toLowerCase();
  
  const keyRisks: string[] = [];
  const recommendedUnits: ("fire" | "medical" | "police")[] = [];
  const emergencyAdvice: string[] = [];
  let recommendedSeverity: "low" | "medium" | "high" | "critical" = "medium";

  if (text.includes("fire") || text.includes("burn") || text.includes("smoke") || text.includes("explosion") || text.includes("blaze")) {
    recommendedUnits.push("fire");
    keyRisks.push("Smoke inhalation hazard", "Structural collapse risk", "Rapid fire spread");
    emergencyAdvice.push("Evacuate immediate area and stay low under smoke.", "Do not use elevators.", "Keep clear of electrical wiring.");
    if (text.includes("trapped") || text.includes("explosion") || text.includes("building")) {
      recommendedSeverity = "critical";
    } else {
      recommendedSeverity = "high";
    }
  }

  if (text.includes("bleed") || text.includes("unconscious") || text.includes("injury") || text.includes("head") || text.includes("fracture") || text.includes("chest") || text.includes("breath") || text.includes("heart") || text.includes("pain")) {
    if (!recommendedUnits.includes("medical")) recommendedUnits.push("medical");
    keyRisks.push("Severe trauma / blood loss", "Potential airway obstruction");
    emergencyAdvice.push("Apply firm pressure to bleeding wounds with a clean cloth.", "Keep victim calm and still.", "Check breathing and pulse continuously.");
    if (text.includes("unconscious") || text.includes("chest pain") || text.includes("heavy bleeding")) {
      recommendedSeverity = "critical";
    } else if (recommendedSeverity !== "critical") {
      recommendedSeverity = "high";
    }
  }

  if (text.includes("crime") || text.includes("robbery") || text.includes("assault") || text.includes("weapon") || text.includes("gun") || text.includes("fight") || text.includes("stolen") || text.includes("suspect")) {
    if (!recommendedUnits.includes("police")) recommendedUnits.push("police");
    keyRisks.push("Threat of active violence", "Perpetrator on loose");
    emergencyAdvice.push("Stay in a secure shelter and do not confront suspects.", "Note suspect physical description and flee direction if safe.");
    if (text.includes("gun") || text.includes("weapon") || text.includes("stab")) {
      recommendedSeverity = "critical";
    } else if (recommendedSeverity !== "critical") {
      recommendedSeverity = "high";
    }
  }

  if (text.includes("flood") || text.includes("water") || text.includes("typhoon") || text.includes("landslide") || text.includes("rescue")) {
    if (!recommendedUnits.includes("fire")) recommendedUnits.push("fire");
    if (!recommendedUnits.includes("police")) recommendedUnits.push("police");
    keyRisks.push("Flash flooding hazard", "Electrical shock in standing water");
    emergencyAdvice.push("Move to higher ground immediately.", "Turn off main power breaker if safe.");
  }

  if (recommendedUnits.length === 0) {
    if (incident.type.toLowerCase().includes("fire")) recommendedUnits.push("fire");
    else if (incident.type.toLowerCase().includes("medical") || incident.type.toLowerCase().includes("health")) recommendedUnits.push("medical");
    else recommendedUnits.push("police");
  }

  if (keyRisks.length === 0) {
    keyRisks.push("Potential situational escalation", "Traffic congestion around scene");
  }

  if (emergencyAdvice.length === 0) {
    emergencyAdvice.push("Keep clear of the scene for emergency responders.", "Maintain line of communication open.");
  }

  const summary = `AI Tactical Analysis: Incident categorized as ${incident.type.toUpperCase()} in ${incident.barangay_name ?? 'reported area'}. Suggested severity level is ${recommendedSeverity.toUpperCase()} with ${recommendedUnits.join(', ').toUpperCase()} unit response.`;

  return {
    summary,
    recommendedSeverity,
    keyRisks,
    recommendedUnits,
    emergencyAdvice,
  };
}

export async function handleAiChatQuery(
  prompt: string,
  contextIncident?: any,
  history: ChatHistoryMessage[] = []
): Promise<string> {
  // Check if GEMINI_API_KEY is available for Model Conversation
  if (GEMINI_API_KEY) {
    const systemInstruction = `You are IRMS AI, an intelligent, empathetic emergency response assistant.
Your job is to:
1. Provide immediate, accurate first-aid instructions and safety advice for emergencies (fire, medical, crime, natural disasters).
2. Help users track their incident reports.
3. Keep responses concise, clear, and reassuring.

Current Active Incident Context:
${contextIncident ? `Tracking Code: #${contextIncident.tracking_code || contextIncident.id?.slice(0, 8)}, Title: ${contextIncident.title}, Status: ${contextIncident.status}, Type: ${contextIncident.type}` : 'No specific active incident context provided.'}`;

    const formattedContents: { role: "user" | "model"; parts: { text: string }[] }[] = [];

    // Map conversation history
    for (const item of history) {
      formattedContents.push({
        role: item.role === "user" ? "user" : "model",
        parts: [{ text: item.text }],
      });
    }

    // Add current prompt
    formattedContents.push({
      role: "user",
      parts: [{ text: prompt }],
    });

    const geminiReply = await callGeminiModel(systemInstruction, formattedContents, false);
    if (geminiReply) return geminiReply;
  }

  // Fallback Rule Parser
  const p = prompt.toLowerCase();
  
  if (p.includes("status") || p.includes("track") || p.includes("where is")) {
    if (contextIncident) {
      return `Emergency Report #${contextIncident.tracking_code || contextIncident.id.slice(0, 8)} is currently in '${(contextIncident.status || 'submitted').toUpperCase()}' status. Dispatched units: ${contextIncident.dispatcher_name ? 'Assigned by ' + contextIncident.dispatcher_name : 'Pending dispatcher assignment'}.`;
    }
    return "To track an incident, please provide your 8-digit tracking code or open the incident report page.";
  }

  if (p.includes("cpr") || p.includes("breath") || p.includes("heart")) {
    return "CPR Steps:\n1. Call emergency services immediately.\n2. Place hands on center of chest.\n3. Push hard and fast (100-120 beats/min).\n4. Allow chest to recoil after each compression.";
  }

  if (p.includes("bleed") || p.includes("blood") || p.includes("wound")) {
    return "Severe Bleeding First-Aid:\n1. Apply direct pressure to wound using clean cloth or bandage.\n2. Keep firm pressure continuously for 10-15 minutes.\n3. Elevate injured area if possible.\n4. Do not remove soaked cloths; add more layers on top.";
  }

  if (p.includes("fire") || p.includes("smoke") || p.includes("burn")) {
    return "Fire Safety Response:\n1. Evacuate immediately — get out and stay out.\n2. Stay low under smoke.\n3. Feel doors with back of hand before opening.\n4. Call emergency responders once outside.";
  }

  return "I am the IRMS AI Assistant. I can help answer first-aid instructions, assist in reporting emergencies, or check status updates on active incidents. How can I help you right now?";
}
