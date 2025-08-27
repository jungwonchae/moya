export default {
	async fetch(request, env) {
		if (request.method === "OPTIONS") {
			return new Response(null, {
				status: 204,
				headers: {
					"Access-Control-Allow-Origin": "*",
					"Access-Control-Allow-Headers": "Content-Type, Authorization",
					"Access-Control-Allow-Methods": "POST, OPTIONS",
				},
			});
		}

		if (new URL(request.url).pathname === "/analyze" && request.method === "POST") {
			try {
				const body = await request.json();
				const { image, hint } = body;

				if (!image) {
					return new Response(JSON.stringify({ error: "image is required" }), { status: 400 });
				}

				// 혈액 감지를 위한 개선된 프롬프트
				const bloodDetectionPrompt = hint || `이미지를 분석해서 다음을 JSON 형태로만 답변해주세요. 다른 설명은 하지 말고 오직 JSON만 반환하세요:

{
  "hasRedStains": boolean,
  "stainLocations": ["위치1", "위치2"],
  "stainSize": "small|medium|large|none",
  "confidence": number,
  "description": "간단한 설명"
}

특히 다음을 주의깊게 확인해주세요:
- 혈액처럼 보이는 빨간색, 적갈색, 갈색 얼룩
- 불규칙한 형태의 붉은 반점
- 마른 혈액의 특징인 어두운 적갈색 흔적
- 생리대, 패드, 옷, 바닥, 표면의 붉은 얼룩

반드시 위 JSON 형식으로만 응답하세요.`;

				const r = await fetch("https://api.openai.com/v1/chat/completions", {
					method: "POST",
					headers: {
						"Authorization": `Bearer ${env.OPENAI_API_KEY}`,
						"Content-Type": "application/json",
					},
					body: JSON.stringify({
						model: "gpt-4o-mini",
						messages: [
							{
								role: "user",
								content: [
									{ type: "text", text: bloodDetectionPrompt },
									{ type: "image_url", image_url: { url: image } }
								]
							}
						],
						max_tokens: 500,
						temperature: 0.1, // 일관된 결과를 위해 낮은 온도 설정
					}),
				});

				if (!r.ok) {
					const errorData = await r.json();
					return new Response(JSON.stringify({ 
						error: "OpenAI API error", 
						details: errorData 
					}), { 
						status: r.status,
						headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" }
					});
				}

				const data = await r.json();
				return new Response(JSON.stringify(data), {
					status: 200,
					headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
				});

			} catch (e) {
				return new Response(JSON.stringify({ 
					error: "Server error",
					message: e.toString() 
				}), { 
					status: 500,
					headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" }
				});
			}
		}

		return new Response("Not Found", { status: 404 });
	}
};