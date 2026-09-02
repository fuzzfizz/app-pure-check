import { serve } from "std/http/server.ts";
import { createClient } from "@supabase/supabase-js";
import { corsHeaders } from "../_shared/cors.ts";
import { verifyUserJwt } from "../_shared/auth.ts";
import { AISmartRouter, UserCustomKeyInput } from "../_shared/ai_smart_router.ts";

const aiRouter = new AISmartRouter();

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // 1. Verify User JWT
  const { user, errorResponse } = await verifyUserJwt(req);
  if (errorResponse) {
    return errorResponse;
  }

  try {
    const body = await req.json();
    const rawList = body?.unknown_ingredients || body?.unknownIngredients || [];
    const userKeys: UserCustomKeyInput[] = Array.isArray(body?.user_api_keys)
      ? body.user_api_keys
      : [];

    const unknownList: string[] = Array.isArray(rawList)
      ? rawList.map(String).filter(s => s.trim().length > 0)
      : [];

    if (unknownList.length === 0) {
      return new Response(JSON.stringify({ corrections: {} }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const corrections: Record<string, string> = {};
    const remainingForAi: string[] = [];

    // 2. Query Supabase Database (inci_ingredients) for free fuzzy match before calling AI
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || Deno.env.get('SUPABASE_ANON_KEY') || '';

    if (supabaseUrl && supabaseKey) {
      try {
        const supabase = createClient(supabaseUrl, supabaseKey);
        for (const term of unknownList) {
          const cleanTerm = term.trim();
          // Try case-insensitive exact or prefix match in inci_ingredients table
          const { data, error } = await supabase
            .from('inci_ingredients')
            .select('name')
            .ilike('name', cleanTerm)
            .limit(1);

          if (!error && data && data.length > 0) {
            const canonical = data[0].name;
            if (canonical.toLowerCase() !== cleanTerm.toLowerCase()) {
              corrections[cleanTerm] = canonical;
            }
          } else {
            remainingForAi.push(cleanTerm);
          }
        }
      } catch (dbErr) {
        console.warn('[check-ingredient-typos] DB query failed, falling back to AI for all:', dbErr);
        remainingForAi.push(...unknownList);
      }
    } else {
      remainingForAi.push(...unknownList);
    }

    // 3. If there are terms remaining, query AI Smart Router
    if (remainingForAi.length > 0) {
      const prompt = `
Correct these cosmetic/skincare ingredient typos to standard INCI names.
Input terms: ${JSON.stringify(remainingForAi)}

Return ONLY valid JSON map of typo -> corrected standard INCI name.
Example format:
{
  "Niacinmid": "Niacinamide",
  "Watar": "Water"
}

Rules:
- If a term is already correct or is a valid custom ingredient, do NOT include it in the map.
- Keys must be exact string matches from the input terms.
- Values must be standard INCI names.
`;

      try {
        const routerRes = await aiRouter.execute(prompt, userKeys);
        const aiJson = routerRes.data;
        if (aiJson && typeof aiJson === 'object') {
          for (const [typo, fixed] of Object.entries(aiJson)) {
            if (typeof fixed === 'string' && fixed.trim().length > 0 && typo.toLowerCase() !== fixed.toLowerCase()) {
              corrections[typo] = fixed.trim();
            }
          }
        }
      } catch (aiErr) {
        console.error('[check-ingredient-typos] AI Smart Router error:', aiErr);
      }
    }

    return new Response(JSON.stringify({ corrections }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    console.error('Unhandled error in check-ingredient-typos:', err);
    return new Response(
      JSON.stringify({ error: err.message || 'Internal Server Error', corrections: {} }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
