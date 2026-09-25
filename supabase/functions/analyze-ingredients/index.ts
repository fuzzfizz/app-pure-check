import { serve } from "std/http/server.ts";
import { createClient } from "@supabase/supabase-js";
import { corsHeaders } from "../_shared/cors.ts";
import { verifyUserJwt } from "../_shared/auth.ts";
import { AISmartRouter, UserCustomKeyInput } from "../_shared/ai_smart_router.ts";

const SAFE_FATTY_ALCOHOLS = [
  'cetearyl alcohol',
  'cetyl alcohol',
  'stearyl alcohol',
  'behenyl alcohol',
  'myristyl alcohol',
  'lanolin alcohol',
  'arachidyl alcohol',
  'isostearyl alcohol',
  'oleyl alcohol',
  'lauryl alcohol',
  'panthenol',
];

function escapeRegExp(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function isSmartMatch(target: string, ingredient: string, aliases: string[] = []): boolean {
  const normTarget = target.trim().toLowerCase();
  const normIng = ingredient.trim().toLowerCase();
  const normAliases = aliases.map(a => String(a).trim().toLowerCase()).filter(Boolean);

  if (!normTarget || !normIng) return false;

  // 1. Exact string match against target or aliases
  if (normIng === normTarget || normAliases.includes(normIng)) {
    return true;
  }

  // 2. Exception Rule: Safe fatty alcohols should not be flagged by generic "alcohol" / "ethanol"
  if (normTarget === 'alcohol' || normTarget === 'ethanol' || normTarget === 'denatured alcohol') {
    const isSafeFatty = SAFE_FATTY_ALCOHOLS.some(safe => normIng.includes(safe));
    if (isSafeFatty) {
      return false;
    }
  }

  // 3. Word boundary regex match (\btarget\b)
  try {
    const targetRegex = new RegExp(`\\b${escapeRegExp(normTarget)}\\b`, 'i');
    if (targetRegex.test(normIng)) {
      return true;
    }

    for (const alias of normAliases) {
      const aliasRegex = new RegExp(`\\b${escapeRegExp(alias)}\\b`, 'i');
      if (aliasRegex.test(normIng)) {
        return true;
      }
    }
  } catch (_) {
    return normIng === normTarget;
  }

  return false;
}

const aiRouter = new AISmartRouter();

serve(async (req: Request) => {
  // Handle OPTIONS CORS preflight headers
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // 1. Verify User JWT Token
  const { user, errorResponse } = await verifyUserJwt(req);
  if (errorResponse) {
    console.warn('[analyze-ingredients] Unauthorized request rejected.');
    return errorResponse;
  }
  console.log(`[analyze-ingredients] Authenticated user: ${user?.id}`);

  try {
    // Extract request body
    const body = await req.json();
    const {
      profile,
      allergens = [],
      ingredients = [],
      user_api_keys = [],
      custom_api_key,
    } = body || {};

    // Prepare user custom keys (supports both array and legacy single key)
    const userKeys: UserCustomKeyInput[] = [];
    if (Array.isArray(user_api_keys)) {
      for (const k of user_api_keys) {
        if (k && typeof k.key === 'string' && k.key.trim().isNotEmpty) {
          userKeys.push({
            key: k.key.trim(),
            provider: k.provider,
            model: k.model,
          });
        }
      }
    }
    if (userKeys.length === 0 && typeof custom_api_key === 'string' && custom_api_key.trim()) {
      userKeys.push({ key: custom_api_key.trim() });
    }

    // Read Supabase config for Database Guardrails
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || Deno.env.get('SUPABASE_ANON_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 2. Query hazardous_chemicals table with Smart Match & Word Boundaries
    const hazardousMatches: Array<{ name: string; reason: string; risk_level: string }> = [];
    if (supabaseUrl && supabaseServiceKey && Array.isArray(ingredients) && ingredients.length > 0) {
      try {
        const { data: hazardousRows, error } = await supabase
          .from('hazardous_chemicals')
          .select('*');

        if (!error && hazardousRows && Array.isArray(hazardousRows)) {
          for (const row of hazardousRows) {
            const chemName = String(row.name || row.chemical_name || row.inci_name || '').trim();
            if (!chemName) continue;

            const aliases: string[] = Array.isArray(row.aliases) ? row.aliases : [];
            const matchedIng = ingredients.find((ing: string) =>
              isSmartMatch(chemName, String(ing), aliases)
            );

            if (matchedIng) {
              hazardousMatches.push({
                name: String(matchedIng),
                reason: String(row.reason || row.description || row.hazard_description || 'สารเคมีอันตรายตามฐานข้อมูล (Hazardous chemical in database)'),
                risk_level: String(row.risk_level || row.severity || 'danger')
              });
            }
          }
        }
      } catch (dbErr) {
        console.error('Error querying hazardous_chemicals:', dbErr);
      }
    }

    // 3. Check for User Allergens matching ingredients
    const allergenMatches: Array<{ name: string; reason: string; risk_level: string }> = [];
    if (Array.isArray(allergens) && Array.isArray(ingredients)) {
      for (const allergen of allergens) {
        if (typeof allergen !== 'string' || !allergen.trim()) continue;

        const matchedIng = ingredients.find((ing: string) =>
          isSmartMatch(String(allergen), String(ing))
        );

        if (matchedIng) {
          allergenMatches.push({
            name: String(matchedIng),
            reason: `ตรงกับประวัติการแพ้ของคุณ: ${allergen} (Matches your known allergen: ${allergen})`,
            risk_level: 'danger'
          });
        }
      }
    }

    // 4. Construct AI Prompt requiring strict JSON response
    const skinType = profile?.skinType || profile?.skin_type || 'normal';
    const skinConditions = Array.isArray(profile?.skinConditions) ? profile.skinConditions.join(', ') : (profile?.skinConditions || 'none');
    const skinConcerns = Array.isArray(profile?.skinConcerns) ? profile.skinConcerns.join(', ') : (profile?.skinConcerns || 'none');
    const avoidPreferences = Array.isArray(profile?.avoidPreferences) ? profile.avoidPreferences.join(', ') : (profile?.avoidPreferences || 'none');
    const allergenListStr = Array.isArray(allergens) ? allergens.join(', ') : 'none';
    const ingredientListStr = Array.isArray(ingredients) ? ingredients.join(', ') : '';

    const prompt = `
Analyze these cosmetic/skincare product ingredients for a user with the following profile:
- Skin type: ${skinType}
- Skin conditions: ${skinConditions}
- Known allergens: ${allergenListStr}
- Skin concerns: ${skinConcerns}
- Ingredients to avoid (preference): ${avoidPreferences}

Product ingredients list: ${ingredientListStr}

Return ONLY valid JSON in this exact structure:
{
  "overall_safety": "safe|caution|danger",
  "summary_th": "คำอธิบายสรุปความปลอดภัยภาษาไทย 2-3 ประโยค",
  "summary_en": "English safety summary explanation 2-3 sentences",
  "flagged_ingredients": [
    {"name": "ingredient name", "reason": "why flagged", "risk_level": "caution|danger"}
  ],
  "ingredient_breakdown": [
    {"name": "ingredient name", "function": "what it does", "risk_level": "safe|caution|danger"}
  ]
}

Rules:
- overall_safety = "danger" if any known allergen or high-risk chemical is found
- overall_safety = "caution" if concerning ingredients found but no high-risk items/allergens
- overall_safety = "safe" if no allergens and no significant concerns
- List ALL ingredients in ingredient_breakdown
- Only flag ingredients that are genuinely concerning for this user's profile
`;

    let aiResult: any = null;
    let metaInfo: any = null;

    // 5. Execute via AISmartRouter (User Keys First -> System Pool Failover)
    try {
      const routerRes = await aiRouter.execute(prompt, userKeys);
      aiResult = routerRes.data;
      metaInfo = routerRes.meta;
    } catch (routerErr) {
      console.error('[analyze-ingredients] AISmartRouter failed all candidates:', routerErr);
    }

    // Safe fallback structure if all AI providers are exhausted
    if (!aiResult) {
      aiResult = {
        overall_safety: "safe",
        summary_th: "วิเคราะห์ส่วนผสมตามระบบฐานข้อมูลความปลอดภัย (ระบบ AI กำลังพักการทำงาน)",
        summary_en: "Ingredients analyzed according to safety database system.",
        flagged_ingredients: [],
        ingredient_breakdown: (Array.isArray(ingredients) ? ingredients : []).map((ing: string) => ({
          name: String(ing),
          function: "Cosmetic ingredient",
          risk_level: "safe"
        }))
      };
      metaInfo = { source: 'safety_fallback', provider: 'local_guardrails', model: 'rule-based' };
    }

    // 6. Post-process response: Enforce Database Guardrails
    const flaggedList: Array<{ name: string; reason: string; risk_level: string }> = Array.isArray(aiResult.flagged_ingredients)
      ? [...aiResult.flagged_ingredients]
      : [];

    const addFlagged = (item: { name: string; reason: string; risk_level: string }) => {
      const exists = flaggedList.some(
        f => f.name.toLowerCase() === item.name.toLowerCase()
      );
      if (!exists) {
        flaggedList.push(item);
      }
    };

    let forceDanger = false;
    let forceCaution = false;

    for (const match of allergenMatches) {
      addFlagged(match);
      forceDanger = true;
    }

    for (const match of hazardousMatches) {
      addFlagged(match);
      if (match.risk_level === 'danger') {
        forceDanger = true;
      } else {
        forceCaution = true;
      }
    }

    aiResult.flagged_ingredients = flaggedList;

    if (forceDanger) {
      aiResult.overall_safety = 'danger';
    } else if (forceCaution && aiResult.overall_safety !== 'danger') {
      aiResult.overall_safety = 'caution';
    }

    // Attach router metadata for observability
    aiResult._meta = metaInfo;

    // Return JSON response with HTTP status 200 and CORS headers
    return new Response(JSON.stringify(aiResult), {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    });

  } catch (err: any) {
    console.error('Unhandled error in analyze-ingredients:', err);
    return new Response(
      JSON.stringify({ error: err.message || 'Internal Server Error' }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    );
  }
});
