// api/analyze.js
export default async function handler(req, res) {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") return res.status(204).end();
    if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });
  
    try {
      const { image, hint } = req.body || {};
      if (!image) return res.status(400).json({ error: "image is required" });
  
      const r = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o-mini",
          messages: [
            {
              role: "user",
              content: [
                {
                  type: "text",
                  text:
                    (hint ?? "") +
                    '\n\n아래 **정확한 형식의 JSON**으로만 답해. ' +
                    '백틱, 마크다운 금지. 줄바꿈/설명 금지. ' +
                    '키: {"hasRedStains": boolean, "stainLocations": string[], "stainSize": "none|small|medium|large", "confidence": number(0~1), "description": string}',
                },
                { type: "image_url", image_url: { url: image } },
              ],
            },
          ],
          temperature: 0.1,
        }),
      });
  
      const data = await r.json();
      const raw = data?.choices?.[0]?.message?.content ?? "";
  
      // 1) 코드블록/공백 제거
      const stripped = raw
        .replace(/```json|```/g, "")
        .replace(/^\s+|\s+$/g, "");
  
      // 2) JSON 파싱 시도
      let parsed;
      try {
        parsed = JSON.parse(stripped);
      } catch {
        // 모델이 텍스트로만 말했을 때 대비한 러프한 추론/기본값
        const lower = stripped.toLowerCase();
        const likelyHas = /blood|혈액|피/.test(lower) && !/(no|없음|not)/.test(lower);
        parsed = {
          hasRedStains: likelyHas,
          stainLocations: [],
          stainSize: "none",
          confidence: 0.5,
          description: stripped,
        };
      }
  
      // 3) 키 표준화 (여러 변형을 허용)
      const coerceBool = (v) => (typeof v === "boolean" ? v : !!v);
      const n = (k, alt = []) =>
        parsed[k] ?? alt.map(a => parsed[a]).find(v => v !== undefined);
  
      let hasRedStains =
        coerceBool(n("hasRedStains", ["hasBlood", "bloodstain", "bloodStain", "hasStain"]));
  
      let confidence = n("confidence", ["score", "prob", "probability", "confidenceScore"]);
      if (typeof confidence !== "number") confidence = 0.5;
      // 0~100로 오면 0~1로 환산
      if (confidence > 1) confidence = Math.min(1, confidence / 100);
  
      let stainLocations = n("stainLocations", ["locations", "areas"]);
      if (!Array.isArray(stainLocations)) stainLocations = [];
  
      let stainSize = n("stainSize", ["size", "stain_level", "severity"]);
      if (typeof stainSize !== "string") stainSize = "none";
      const sizeMap = { none: "none", small: "small", medium: "medium", large: "large" };
      stainSize = sizeMap[stainSize.toLowerCase?.()] || "none";
  
      let description = n("description", ["summary", "reason", "explanation"]);
      if (typeof description !== "string") description = stripped;
  
      // 4) 항상 동일한 JSON으로 응답
      const out = {
        hasRedStains,
        stainLocations,
        stainSize,
        confidence,
        description,
      };
  
      return res.status(200).json(out);
    } catch (e) {
      return res.status(500).json({ error: String(e) });
    }
  }