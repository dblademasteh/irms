import { query } from "../../db/index.js";

export type AnnouncementTemplate =
  | "weather_advisory"
  | "fire_alert"
  | "crime_safety"
  | "medical_alert"
  | "system_maintenance"
  | "safety_tip"
  | "incident_summary"
  | "general_emergency"
  | "traffic_update"
  | "earthquake_advisory"
  | "flood_warning"
  | "tsunami_warning";

export interface GenerateInput {
  template: AnnouncementTemplate;
  details?: string;
  barangay?: string;
}

export interface GenerateOutput {
  message: string;
  category: string;
}

interface IncidentStats {
  totalActive: number;
  critical: number;
  byType: Record<string, number>;
  recentBarangays: string[];
}

async function getIncidentStats(): Promise<IncidentStats> {
  const [activeRes, criticalRes, typeRes, barangayRes] = await Promise.all([
    query(`SELECT COUNT(*) as count FROM incidents WHERE status IN ('submitted', 'under_review')`),
    query(`SELECT COUNT(*) as count FROM incidents WHERE status IN ('submitted', 'under_review') AND severity = 'critical'`),
    query(`SELECT type, COUNT(*) as count FROM incidents WHERE status IN ('submitted', 'under_review') GROUP BY type`),
    query(`SELECT b.name, COUNT(i.id) as count
           FROM incidents i
           JOIN barangays b ON b.id = i.barangay_id
           WHERE i.status IN ('submitted', 'under_review')
           GROUP BY b.name
           ORDER BY count DESC
           LIMIT 3`),
  ]);

  const byType: Record<string, number> = {};
  for (const row of typeRes.rows) {
    byType[row.type] = parseInt(row.count, 10);
  }

  return {
    totalActive: parseInt(activeRes.rows[0].count, 10),
    critical: parseInt(criticalRes.rows[0].count, 10),
    byType,
    recentBarangays: barangayRes.rows.map((r: any) => r.name),
  };
}

function formatTypeList(byType: Record<string, number>): string {
  const labels: Record<string, string> = {
    fire: "fire incidents",
    accident: "vehicle accidents",
    crime: "crime reports",
    medical: "medical emergencies",
    natural_disaster: "natural disasters",
    infrastructure: "infrastructure issues",
  };
  const entries = Object.entries(byType)
    .filter(([_, count]) => count > 0)
    .sort((a, b) => b[1] - a[1])
    .map(([type, count]) => `${count} ${labels[type] ?? type}`);
  return entries.length > 0 ? entries.join(", ") : "none reported";
}

const templateCategoryMap: Record<AnnouncementTemplate, string> = {
  weather_advisory: "weather",
  fire_alert: "emergency",
  crime_safety: "emergency",
  medical_alert: "emergency",
  system_maintenance: "system",
  safety_tip: "safety",
  incident_summary: "emergency",
  general_emergency: "emergency",
  traffic_update: "traffic",
  earthquake_advisory: "earthquake",
  flood_warning: "flood",
  tsunami_warning: "tsunami",
};

export async function generateAnnouncement(input: GenerateInput): Promise<GenerateOutput> {
  const stats = await getIncidentStats();
  const barangay = input.barangay?.trim() || null;
  const location = barangay ? ` in ${barangay}` : "";
  const details = input.details?.trim();

  let message = "";

  switch (input.template) {
    case "weather_advisory": {
      message = [
        `WEATHER ADVISORY${location.toUpperCase()}:`,
        details ?? "Residents are advised to stay alert for possible flooding and landslides.",
        "Avoid low-lying areas and stay tuned for updates.",
      ].join(" ");
      break;
    }

    case "fire_alert": {
      const fireCount = stats.byType["fire"] ?? 0;
      message = [
        `FIRE ALERT${location.toUpperCase()}:`,
        details ?? `Active fire incidents: ${fireCount}. Ensure fire exits are clear and follow evacuation procedures.`,
        "Contact BFP for emergencies.",
      ].join(" ");
      break;
    }

    case "crime_safety": {
      const crimeCount = stats.byType["crime"] ?? 0;
      message = [
        `PUBLIC SAFETY ADVISORY${location.toUpperCase()}:`,
        details ?? `Active crime reports: ${crimeCount}. Stay vigilant and report suspicious activity immediately.`,
        "Dial 911 for emergencies.",
      ].join(" ");
      break;
    }

    case "medical_alert": {
      const medCount = stats.byType["medical"] ?? 0;
      message = [
        `MEDICAL ALERT${location.toUpperCase()}:`,
        details ?? `Active medical emergencies: ${medCount}. First responders are on standby.`,
        "Call emergency hotlines for immediate assistance.",
      ].join(" ");
      break;
    }

    case "system_maintenance": {
      message = [
        "SYSTEM MAINTENANCE NOTICE:",
        details ?? "The IRMS platform will undergo scheduled maintenance. Some features may be temporarily unavailable.",
        "We apologize for the inconvenience.",
      ].join(" ");
      break;
    }

    case "safety_tip": {
      message = [
        "SAFETY REMINDER:",
        details ?? "Check your home for potential hazards. Keep emergency supplies ready and ensure family members know evacuation routes.",
        "Stay safe, everyone.",
      ].join(" ");
      break;
    }

    case "incident_summary": {
      const typeList = formatTypeList(stats.byType);
      const parts = [
        `SITUATION REPORT:`,
        `Currently ${stats.totalActive} active incident(s) across the municipality.`,
        `Breakdown: ${typeList}.`,
      ];
      if (stats.recentBarangays.length > 0) {
        parts.push(`Most affected areas: ${stats.recentBarangays.join(", ")}.`);
      }
      if (stats.critical > 0) {
        parts.push(`${stats.critical} classified as CRITICAL. All dispatchers on high alert.`);
      }
      if (details) {
        parts.push(details);
      }
      message = parts.join(" ");
      break;
    }

    case "general_emergency": {
      const parts = [
        `EMERGENCY BROADCAST${location.toUpperCase()}:`,
        details ?? "An emergency situation has been reported. Follow instructions from local authorities.",
        "Stay calm and stay informed.",
      ];
      if (stats.totalActive > 0) {
        parts.push(`Current active incidents: ${stats.totalActive}.`);
      }
      message = parts.join(" ");
      break;
    }

    case "traffic_update": {
      message = [
        `TRAFFIC ADVISORY${location.toUpperCase()}:`,
        details ?? "Exercise caution on roads. Traffic conditions may be heavier than usual.",
        "Plan your travel accordingly.",
      ].join(" ");
      break;
    }

    case "earthquake_advisory": {
      message = [
        `EARTHQUAKE ADVISORY${location.toUpperCase()}:`,
        details ?? "A tremor has been detected. If you feel shaking, drop, cover, and hold on.",
        "Stay away from windows and heavy objects. Expect possible aftershocks.",
      ].join(" ");
      break;
    }

    case "flood_warning": {
      message = [
        `FLOOD WARNING${location.toUpperCase()}:`,
        details ?? "Flooding has been reported or is imminent in your area.",
        "Move to higher ground immediately. Do not attempt to walk or drive through floodwaters.",
      ].join(" ");
      break;
    }

    case "tsunami_warning": {
      message = [
        `TSUNAMI WARNING${location.toUpperCase()}:`,
        details ?? "A tsunami warning has been issued for this area.",
        "Evacuate immediately to higher ground. Do not return until authorities give the all-clear.",
      ].join(" ");
      break;
    }
  }

  return { message, category: templateCategoryMap[input.template] };
}

export function getAvailableTemplates(): { key: AnnouncementTemplate; label: string; description: string; category: string }[] {
  return [
    { key: "weather_advisory", label: "Weather Advisory", description: "Flood, storm, or weather-related warnings", category: "weather" },
    { key: "fire_alert", label: "Fire Alert", description: "Fire incident notifications and evacuation notices", category: "emergency" },
    { key: "crime_safety", label: "Crime / Safety", description: "Public safety and crime advisories", category: "emergency" },
    { key: "medical_alert", label: "Medical Alert", description: "Medical emergency notifications", category: "emergency" },
    { key: "system_maintenance", label: "System Maintenance", description: "Scheduled maintenance notices", category: "system" },
    { key: "safety_tip", label: "Safety Tip", description: "Community safety reminders and tips", category: "safety" },
    { key: "incident_summary", label: "Incident Summary", description: "Auto-generated situation report with live data", category: "emergency" },
    { key: "general_emergency", label: "General Emergency", description: "Catch-all emergency broadcast", category: "emergency" },
    { key: "traffic_update", label: "Traffic Update", description: "Road closures, traffic jams, and route advisories", category: "traffic" },
    { key: "earthquake_advisory", label: "Earthquake Advisory", description: "Earthquake reports and safety instructions", category: "earthquake" },
    { key: "flood_warning", label: "Flood Warning", description: "Flooding alerts and evacuation notices", category: "flood" },
    { key: "tsunami_warning", label: "Tsunami Warning", description: "Tsunami warnings and coastal evacuation", category: "tsunami" },
  ];
}