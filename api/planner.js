// ⚠️ 核心修复 1：把 Vercel 的默认 10 秒超时延长到 60 秒（免费版支持的最大值）
export const maxDuration = 60; 

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { systemPrompt, userMessage } = req.body;

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://tai-map-app.vercel.app/',
        'X-Title': 'Circular Travel',
      },
      body: JSON.stringify({
        // Use a reliable model that supports JSON mode and has higher availability
        model: process.env.AI_MODEL || 'deepseek/deepseek-v4-flash', 
        messages: [
          { role: 'system', content: systemPrompt + " Respond ONLY with a valid JSON object. Do not include any explanations or markdown code blocks. Ensure the JSON is complete and not truncated." },
          { role: 'user', content: userMessage }
        ],
        // ⚠️ 核心修复 2：为了防止内容太长被截断，稍微给大点 Token
        max_tokens: 4000, 
        response_format: { type: 'json_object' }
      })
    });

    // ⚠️ 核心修复 3：如果 OpenRouter 扣费失败或者 Key 错误，直接返回真实错误
    if (!response.ok) {
      const errorData = await response.json();
      console.error('OpenRouter 拒绝了请求:', errorData);
      return res.status(response.status).json({ error: 'OpenRouter API Error', details: errorData });
    }

    const data = await response.json();
    
    // 获取 AI 返回的文本
    const content = data.choices[0].message.content;
    
    // 核心修复：清理可能存在的 Markdown 代码块标记，确保 JSON 解析成功
    const cleanContent = content.replace(/```json\n?|```/g, '').trim();
    
    try {
      res.status(200).json(JSON.parse(cleanContent));
    } catch (parseError) {
      console.error('JSON 解析失败，原始内容:', cleanContent);
      res.status(500).json({ error: 'JSON Parse Error', details: parseError.toString(), raw: cleanContent });
    }

  } catch (error) {
    console.error('Vercel 内部发生致命错误:', error);
    // 把真实的错误堆栈字符串发给前端，方便查 Bug
    res.status(500).json({ error: 'Failed to fetch AI data', details: error.toString() });
  }
}