export interface AiClassificationResult {
  suggestedType: string;
  recommendedSeverity: "low" | "medium" | "high" | "critical";
  confidenceScore: number;
  extractedKeywords: string[];
}

export function classifyIncidentText(description: string, title?: string): AiClassificationResult {
  const fullText = `${title ?? ""} ${description}`.toLowerCase();
  const keywords: string[] = [];

  // Keywords extraction
  if (fullText.includes("fire") || fullText.includes("smoke") || fullText.includes("blaze")) keywords.push("fire");
  if (fullText.includes("accident") || fullText.includes("crash") || fullText.includes("collision")) keywords.push("accident");
  if (fullText.includes("gun") || fullText.includes("robbery") || fullText.includes("theft") || fullText.includes("assault")) keywords.push("crime");
  if (fullText.includes("bleeding") || fullText.includes("unconscious") || fullText.includes("heart attack") || fullText.includes("injury")) keywords.push("medical");
  if (fullText.includes("flood") || fullText.includes("typhoon") || fullText.includes("landslide") || fullText.includes("earthquake")) keywords.push("natural_disaster");

  // Type deduction
  let suggestedType = "natural_disaster";
  if (keywords.includes("fire")) suggestedType = "fire";
  else if (keywords.includes("medical")) suggestedType = "medical";
  else if (keywords.includes("crime")) suggestedType = "crime";
  else if (keywords.includes("accident")) suggestedType = "accident";

  // Severity scoring
  let recommendedSeverity: "low" | "medium" | "high" | "critical" = "medium";
  if (fullText.includes("trapped") || fullText.includes("explosion") || fullText.includes("fatal") || fullText.includes("unconscious") || fullText.includes("critical")) {
    recommendedSeverity = "critical";
  } else if (fullText.includes("severe") || fullText.includes("heavy") || fullText.includes("gun") || fullText.includes("weapon")) {
    recommendedSeverity = "high";
  } else if (fullText.includes("minor") || fullText.includes("small")) {
    recommendedSeverity = "low";
  }

  const confidenceScore = keywords.length > 0 ? Math.min(0.7 + keywords.length * 0.1, 0.98) : 0.6;

  return {
    suggestedType,
    recommendedSeverity,
    confidenceScore,
    extractedKeywords: keywords,
  };
}
