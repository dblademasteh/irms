import { query } from "../../db/index.js";

export type AnnouncementTemplate =
  | "weather_advisory"
  | "fire_alert"
  | "crime_safety"
  | "medical_alert"
  | "system_maintenance"
  | "safety_tip"
  | "incident_summary"
  | "general_emergency";

export interface GenerateInput {
  template: AnnouncementTemplate;
  details?: string;
  barangay?: string;
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

export async function generateAnnouncement(input: GenerateInput): Promise<string> {
  const stats = await getIncidentStats();
  const barangay = input.barangay?.trim() || null;
  const location = barangay ? ` in ${barangay}` : "";
  const details = input.details?.trim();

  switch (input.template) {
    case "weather_advisory": {
      const parts = [
        `WEATHER ADVISORY${location.toUpperCase()}:`,
        details ?? "Residents are advised to stay alert for possible flooding and landslides.",
        "Avoid low-lying areas and stay tuned for updates.",
      ];
      if (stats.critical > 0) {
        parts.push(`Note: ${stats.critical} critical incident(s) currently active.`);
      }
      return parts.join(" ");
    }

    case "fire_alert": {
      const fireCount = stats.byType["fire"] ?? 0;
      const parts = [
        `FIRE ALERT${location.toUpperCase()}:`,
        details ?? `Active fire incidents: ${fireCount}. Ensure fire exits are clear and follow evacuation procedures.`,
        "Contact BFP for emergencies.",
      ];
      return parts.join(" ");
    }

    case "crime_safety": {
      const crimeCount = stats.byType["crime"] ?? 0;
      const parts = [
        `PUBLIC SAFETY ADVISORY${location.toUpperCase()}:`,
        details ?? `Active crime reports: ${crimeCount}. Stay vigilant and report suspicious activity immediately.`,
        "Dial 911 for emergencies.",
      ];
      return parts.join(" ");
    }

    case "medical_alert": {
      const medCount = stats.byType["medical"] ?? 0;
      const parts = [
        `MEDICAL ALERT${location.toUpperCase()}:`,
        details ?? `Active medical emergencies: ${medCount}. First responders are on standby.`,
        "Call emergency hotlines for immediate assistance.",
      ];
      return parts.join(" ");
    }

    case "system_maintenance": {
      return [
        "SYSTEM MAINTENANCE NOTICE:",
        details ?? "The IRMS platform will undergo scheduled maintenance. Some features may be temporarily unavailable.",
        "We apologize for the inconvenience.",
      ].join(" ");
    }

    case "safety_tip": {
      return [
        "SAFETY REMINDER:",
        details ?? "Check your home for potential hazards. Keep emergency supplies ready and ensure family members know evacuation routes.",
        "Stay safe, everyone.",
      ].join(" ");
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
      return parts.join(" ");
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
      return parts.join(" ");
    }
  }
}

export function getAvailableTemplates(): { key: AnnouncementTemplate; label: string; description: string }[] {
  return [
    { key: "weather_advisory", label: "Weather Advisory", description: "Flood, storm, or weather-related warnings" },
    { key: "fire_alert", label: "Fire Alert", description: "Fire incident notifications and evacuation notices" },
    { key: "crime_safety", label: "Crime / Safety", description: "Public safety and crime advisories" },
    { key: "medical_alert", label: "Medical Alert", description: "Medical emergency notifications" },
    { key: "system_maintenance", label: "System Maintenance", description: "Scheduled maintenance notices" },
    { key: "safety_tip", label: "Safety Tip", description: "Community safety reminders and tips" },
    { key: "incident_summary", label: "Incident Summary", description: "Auto-generated situation report with live data" },
    { key: "general_emergency", label: "General Emergency", description: "Catch-all emergency broadcast" },
  ];
}
