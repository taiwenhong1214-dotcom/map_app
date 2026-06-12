// 文件路径：api/planner.js
export default async function handler(req, res) {
  // 只允许 POST 请求
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { systemPrompt, userMessage } = req.body;

    // 组装发给 OpenRouter 的请求
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        // 自动读取你在 Vercel Dashboard 中配置的环境变量
        'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://tai-map-app.vercel.app/',
        'X-Title': 'Circular Travel',
      },
      body: JSON.stringify({
        // 你可以在 Vercel Env 里加一个 AI_MODEL，或者这里写死
        model: process.env.AI_MODEL || 'openai/gpt-oss-120b:free', 
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMessage }
        ],
        response_format: { type: 'json_object' }
      })
    });

    const data = await response.json();
    
    // 提取大模型返回的文本 (JSON 字符串)
    const content = data.choices[0].message.content;
    
    // 将字符串解析为 JSON 对象并返回给 Flutter
    res.status(200).json(JSON.parse(content));

  } catch (error) {
    console.error('API 代理错误:', error);
    res.status(500).json({ error: 'Failed to fetch AI data' });
  }
}