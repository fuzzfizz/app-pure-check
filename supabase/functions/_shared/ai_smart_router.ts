export interface AIEndpointConfig {
  id: string;
  name: string;
  provider: 'gemini' | 'groq' | 'cerebras' | 'openrouter' | 'deepseek' | 'github' | 'openai-compatible';
  model: string;
  apiKey: string;
  apiUrl: string;
  headers?: Record<string, string>;
  isGeminiNative?: boolean;
  priority: number;
}

export interface UserCustomKeyInput {
  key: string;
  provider?: string;
  model?: string;
}

export interface RouterResult {
  data: any;
  meta: {
    source: 'user_custom' | 'system_pool';
    provider: string;
    model: string;
    endpoint: string;
  };
}

// In-memory Cooldown Map for rate-limited endpoints (per Deno isolate)
const cooldownMap = new Map<string, number>();

export class AISmartRouter {
  private systemEndpoints: AIEndpointConfig[] = [];

  constructor() {
    this.initSystemPool();
  }

  private splitKeys(varName: string): string[] {
    const raw = Deno.env.get(varName) || '';
    const keys = raw.split(',').map(k => k.trim()).filter(Boolean);
    for (let i = 1; i <= 10; i++) {
      const numKey = Deno.env.get(`${varName}_${i}`)?.trim();
      if (numKey && !keys.includes(numKey)) {
        keys.push(numKey);
      }
    }
    return keys;
  }

  private initSystemPool() {
    this.systemEndpoints = [];

    // 1. Google Gemini Pool (1-Click Google, 15 RPM / 1,500 RPD free forever)
    const geminiKeys = this.splitKeys('GEMINI_API_KEYS');
    if (geminiKeys.length === 0 && Deno.env.get('GEMINI_API_KEY')) {
      geminiKeys.push(Deno.env.get('GEMINI_API_KEY')!.trim());
    }

    geminiKeys.forEach((key, idx) => {
      // Primary model: gemini-1.5-flash
      this.systemEndpoints.push({
        id: `sys-gemini-1.5-flash-k${idx + 1}`,
        name: `Gemini 1.5 Flash (System Key #${idx + 1})`,
        provider: 'gemini',
        model: 'gemini-1.5-flash',
        apiKey: key,
        apiUrl: `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${key}`,
        isGeminiNative: true,
        priority: 1,
      });

      // Secondary model: gemini-2.0-flash
      this.systemEndpoints.push({
        id: `sys-gemini-2.0-flash-k${idx + 1}`,
        name: `Gemini 2.0 Flash (System Key #${idx + 1})`,
        provider: 'gemini',
        model: 'gemini-2.0-flash',
        apiKey: key,
        apiUrl: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${key}`,
        isGeminiNative: true,
        priority: 2,
      });
    });

    // 2. Groq Cloud Pool (30 RPM, 14,400 RPD free, LPU ultra-fast)
    const groqKeys = this.splitKeys('GROQ_API_KEYS');
    if (groqKeys.length === 0 && Deno.env.get('GROQ_API_KEY')) {
      groqKeys.push(Deno.env.get('GROQ_API_KEY')!.trim());
    }
    groqKeys.forEach((key, idx) => {
      this.systemEndpoints.push({
        id: `sys-groq-llama3-k${idx + 1}`,
        name: `Groq Llama 3.3 70B (System Key #${idx + 1})`,
        provider: 'groq',
        model: 'llama-3.3-70b-versatile',
        apiKey: key,
        apiUrl: 'https://api.groq.com/openai/v1/chat/completions',
        priority: 3,
      });
    });

    // 3. Cerebras Cloud Pool (30 RPM, 60,000 TPM free)
    const cerebrasKeys = this.splitKeys('CEREBRAS_API_KEYS');
    if (cerebrasKeys.length === 0 && Deno.env.get('CEREBRAS_API_KEY')) {
      cerebrasKeys.push(Deno.env.get('CEREBRAS_API_KEY')!.trim());
    }
    cerebrasKeys.forEach((key, idx) => {
      this.systemEndpoints.push({
        id: `sys-cerebras-llama3-k${idx + 1}`,
        name: `Cerebras Llama 3.3 70B (System Key #${idx + 1})`,
        provider: 'cerebras',
        model: 'llama-3.3-70b',
        apiKey: key,
        apiUrl: 'https://api.cerebras.ai/v1/chat/completions',
        priority: 4,
      });
    });

    // 4. OpenRouter Free Tier Pool (:free models reset every minute)
    const openrouterKeys = this.splitKeys('OPENROUTER_API_KEYS');
    if (openrouterKeys.length === 0 && Deno.env.get('OPENROUTER_API_KEY')) {
      openrouterKeys.push(Deno.env.get('OPENROUTER_API_KEY')!.trim());
    }
    openrouterKeys.forEach((key, idx) => {
      this.systemEndpoints.push({
        id: `sys-openrouter-deepseek-free-k${idx + 1}`,
        name: `OpenRouter Free DeepSeek R1 (System Key #${idx + 1})`,
        provider: 'openrouter',
        model: 'deepseek/deepseek-r1:free',
        apiKey: key,
        apiUrl: 'https://openrouter.ai/api/v1/chat/completions',
        headers: { 'HTTP-Referer': 'https://purecheck.app', 'X-Title': 'PureCheck' },
        priority: 5,
      });
      this.systemEndpoints.push({
        id: `sys-openrouter-llama3-free-k${idx + 1}`,
        name: `OpenRouter Free Llama 3.3 (System Key #${idx + 1})`,
        provider: 'openrouter',
        model: 'meta-llama/llama-3.3-70b-instruct:free',
        apiKey: key,
        apiUrl: 'https://openrouter.ai/api/v1/chat/completions',
        headers: { 'HTTP-Referer': 'https://purecheck.app', 'X-Title': 'PureCheck' },
        priority: 6,
      });
    });

    // 5. DeepSeek Direct API
    const deepseekKeys = this.splitKeys('DEEPSEEK_API_KEYS');
    if (deepseekKeys.length === 0 && Deno.env.get('DEEPSEEK_API_KEY')) {
      deepseekKeys.push(Deno.env.get('DEEPSEEK_API_KEY')!.trim());
    }
    deepseekKeys.forEach((key, idx) => {
      this.systemEndpoints.push({
        id: `sys-deepseek-chat-k${idx + 1}`,
        name: `DeepSeek Chat (System Key #${idx + 1})`,
        provider: 'deepseek',
        model: 'deepseek-chat',
        apiKey: key,
        apiUrl: 'https://api.deepseek.com/chat/completions',
        priority: 7,
      });
    });

    // 6. GitHub Models (150 RPD free for GitHub users)
    const githubKeys = this.splitKeys('GITHUB_MODELS_KEYS');
    if (githubKeys.length === 0 && Deno.env.get('GITHUB_MODELS_KEY')) {
      githubKeys.push(Deno.env.get('GITHUB_MODELS_KEY')!.trim());
    }
    githubKeys.forEach((key, idx) => {
      this.systemEndpoints.push({
        id: `sys-github-models-k${idx + 1}`,
        name: `GitHub Models GPT-4o-mini (System Key #${idx + 1})`,
        provider: 'github',
        model: 'gpt-4o-mini',
        apiKey: key,
        apiUrl: 'https://models.inference.ai.azure.com/chat/completions',
        priority: 8,
      });
    });
  }

  // Convert raw user keys into executable AIEndpointConfig objects
  private buildUserEndpoints(userKeys: UserCustomKeyInput[]): AIEndpointConfig[] {
    const list: AIEndpointConfig[] = [];
    userKeys.slice(0, 3).forEach((item, idx) => {
      const cleanKey = item.key.trim();
      if (!cleanKey) return;

      const provider = (item.provider || '').toLowerCase();
      let isGemini = provider === 'gemini' || cleanKey.startsWith('AIzaSy');
      let apiUrl = '';
      let model = item.model || '';

      if (isGemini) {
        model = model || 'gemini-1.5-flash';
        apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${cleanKey}`;
        list.push({
          id: `user-key-${idx + 1}`,
          name: `User Key #${idx + 1} (Gemini ${model})`,
          provider: 'gemini',
          model,
          apiKey: cleanKey,
          apiUrl,
          isGeminiNative: true,
          priority: 0,
        });
      } else {
        let defaultEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
        let defaultModel = 'llama-3.3-70b-versatile';

        if (provider === 'cerebras' || cleanKey.startsWith('csk-')) {
          defaultEndpoint = 'https://api.cerebras.ai/v1/chat/completions';
          defaultModel = 'llama-3.3-70b';
        } else if (provider === 'openrouter' || cleanKey.startsWith('sk-or-')) {
          defaultEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
          defaultModel = 'deepseek/deepseek-r1:free';
        } else if (provider === 'deepseek' || cleanKey.startsWith('sk-')) {
          defaultEndpoint = 'https://api.deepseek.com/chat/completions';
          defaultModel = 'deepseek-chat';
        } else if (provider === 'github' || cleanKey.startsWith('ghp_')) {
          defaultEndpoint = 'https://models.inference.ai.azure.com/chat/completions';
          defaultModel = 'gpt-4o-mini';
        }

        list.push({
          id: `user-key-${idx + 1}`,
          name: `User Key #${idx + 1} (${provider || 'OpenAI-compatible'})`,
          provider: 'openai-compatible',
          model: model || defaultModel,
          apiKey: cleanKey,
          apiUrl: defaultEndpoint,
          priority: 0,
        });
      }
    });

    return list;
  }

  // Execute request with Hybrid Failover: User Keys First (Priority 0) -> System Pool
  async execute(prompt: string, userKeys: UserCustomKeyInput[] = []): Promise<RouterResult> {
    // 1. Try User Keys First (Priority 0)
    const userEndpoints = this.buildUserEndpoints(userKeys);
    for (const ep of userEndpoints) {
      try {
        console.log(`[AISmartRouter] Attempting ${ep.name}...`);
        const res = await this.callEndpoint(ep, prompt);
        if (res.success && res.data) {
          console.log(`[AISmartRouter] Successfully resolved via ${ep.name}`);
          return {
            data: res.data,
            meta: {
              source: 'user_custom',
              provider: ep.provider,
              model: ep.model,
              endpoint: ep.name,
            },
          };
        }
        if (res.rateLimited) {
          console.warn(`[AISmartRouter] ${ep.name} hit 429 quota/rate limit. Failing over...`);
        } else {
          console.warn(`[AISmartRouter] ${ep.name} failed (${res.error}). Failing over...`);
        }
      } catch (err) {
        console.error(`[AISmartRouter] Exception executing ${ep.name}:`, err);
      }
    }

    // 2. Failover to System Pool
    console.log('[AISmartRouter] Calling System Pool...');
    const now = Date.now();
    let available = this.systemEndpoints
      .filter(ep => now >= (cooldownMap.get(ep.id) || 0))
      .sort((a, b) => a.priority - b.priority);

    if (available.length === 0 && this.systemEndpoints.length > 0) {
      console.warn('[AISmartRouter] All system endpoints currently cooling down. Resetting cooldown pool...');
      cooldownMap.clear();
      available = [...this.systemEndpoints].sort((a, b) => a.priority - b.priority);
    }

    for (const ep of available) {
      try {
        console.log(`[AISmartRouter] Trying ${ep.name}...`);
        const res = await this.callEndpoint(ep, prompt);
        if (res.success && res.data) {
          console.log(`[AISmartRouter] Successfully resolved via ${ep.name}`);
          return {
            data: res.data,
            meta: {
              source: 'system_pool',
              provider: ep.provider,
              model: ep.model,
              endpoint: ep.name,
            },
          };
        }
        if (res.rateLimited) {
          console.warn(`[AISmartRouter] ${ep.name} hit Rate Limit 429. Setting 60s cooldown.`);
          cooldownMap.set(ep.id, Date.now() + 60 * 1000);
        } else {
          console.warn(`[AISmartRouter] ${ep.name} error: ${res.error}. Trying next...`);
        }
      } catch (err) {
        console.error(`[AISmartRouter] Exception with ${ep.name}:`, err);
      }
    }

    throw new Error('All user and system AI endpoints are exhausted or failed.');
  }

  private async callEndpoint(
    ep: AIEndpointConfig,
    prompt: string
  ): Promise<{ success: boolean; data?: any; rateLimited?: boolean; error?: string }> {
    if (ep.isGeminiNative) {
      const response = await fetch(ep.apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            responseMimeType: 'application/json',
            temperature: 0.2,
          },
        }),
      });

      if (response.status === 429 || response.status === 503) {
        return { success: false, rateLimited: true };
      }
      if (!response.ok) return { success: false, error: `HTTP ${response.status}` };

      const json = await response.json();
      const text = json?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!text) return { success: false, error: 'Empty candidate text' };
      const clean = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      return { success: true, data: JSON.parse(clean) };
    } else {
      const response = await fetch(ep.apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${ep.apiKey}`,
          ...(ep.headers || {}),
        },
        body: JSON.stringify({
          model: ep.model,
          messages: [
            {
              role: 'system',
              content: 'You are a professional cosmetic dermatologist and ingredient safety analyst. Return ONLY valid JSON.',
            },
            { role: 'user', content: prompt },
          ],
          response_format: { type: 'json_object' },
          temperature: 0.2,
        }),
      });

      if (response.status === 429 || response.status === 503) {
        return { success: false, rateLimited: true };
      }
      if (!response.ok) return { success: false, error: `HTTP ${response.status}` };

      const json = await response.json();
      const text = json?.choices?.[0]?.message?.content;
      if (!text) return { success: false, error: 'Empty message text' };
      const clean = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      return { success: true, data: JSON.parse(clean) };
    }
  }
}
