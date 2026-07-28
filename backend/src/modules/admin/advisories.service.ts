interface Advisory {
  id: string;
  title: string;
  description: string;
  link: string;
  pubDate: string;
}

export function parseGDACSFeed(xmlText: string): Advisory[] {
  const items: Advisory[] = [];
  const itemRegex = /<item>([\s\S]*?)<\/item>/g;
  let match;
  while ((match = itemRegex.exec(xmlText)) !== null) {
    const itemContent = match[1];
    const title = getTagValue(itemContent, "title");
    const description = getTagValue(itemContent, "description");
    const link = getTagValue(itemContent, "link");
    const pubDate = getTagValue(itemContent, "pubDate");
    const guid = getTagValue(itemContent, "guid") || link;
    items.push({
      id: guid,
      title,
      description,
      link,
      pubDate,
    });
  }
  return items;
}

function getTagValue(xml: string, tag: string): string {
  const regex = new RegExp(`<${tag}(?:[^>]*)>([\\s\\S]*?)<\/${tag}>`);
  const match = xml.match(regex);
  if (!match) return "";
  let val = match[1];
  if (val.startsWith("<![CDATA[")) {
    val = val.substring(9, val.length - 3);
  }
  return val.trim();
}

export async function fetchNationalAdvisories(): Promise<Advisory[]> {
  try {
    const res = await fetch("https://www.gdacs.org/xml/rss.xml");
    if (!res.ok) {
      throw new Error(`Failed to fetch GDACS feed: ${res.statusText}`);
    }
    const xmlText = await res.text();
    return parseGDACSFeed(xmlText);
  } catch (err) {
    console.error("[advisories.service] fetchNationalAdvisories error:", err);
    return [];
  }
}
