import { serve } from "std/http/server.ts";
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
    const term = String(body?.raw_input || body?.raw_name || body?.name || '').trim();
    let action = String(body?.action || '').toLowerCase().trim();
    const userKeys: UserCustomKeyInput[] = Array.isArray(body?.user_api_keys)
      ? body.user_api_keys
      : [];

    if (!term) {
      return new Response(JSON.stringify({ error: 'Missing ingredient name' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Auto-determine action if not explicitly given
    if (!action || (action !== 'synonym' && action !== 'cosing')) {
      if (term.includes('/') || (term.includes('(') && term.includes(')'))) {
        action = 'synonym';
      } else {
        action = 'cosing';
      }
    }

    let prompt = '';
    if (action === 'synonym') {
      prompt = `
You are an expert Cosmetic Chemist and Regulatory Toxicologist specializing in INCI nomenclature.
Analyze this ingredient candidate: "${term}"

Determine:
1. Is this entry a valid multi-lingual designation, standard cosmetic synonym, or botanical/chemical alias for ONE single cosmetic ingredient?
   (Examples of VALID synonyms:
    - "Aqua / Water / Eau" -> represents single substance Water (INCI: Water)
    - "Aqua/Water" -> represents Water (INCI: Water)
    - "Water (Aqua)" -> represents Water (INCI: Water)
    - "Tocopherol (Vitamin E)" -> represents Tocopherol (INCI: Tocopherol)
    - "Simmondsia Chinensis (Jojoba) Seed Oil" -> represents Jojoba Seed Oil (INCI: Simmondsia Chinensis Seed Oil)
    - "Butyrospermum Parkii (Shea) Butter" -> represents Shea Butter (INCI: Butyrospermum Parkii Butter)
    - "Centella Asiatica Extract / Gotu Kola" -> represents Centella Asiatica Extract)
2. Or is it an INVALID, suspicious, mixed, nonsensical, or hazardous combination?
   (Examples of INVALID combinations:
    - "gas/water/aqua" -> INVALID (gas is not a cosmetic synonym for water)
    - "poison / water" -> INVALID
    - "car fuel / glycerin" -> INVALID
    - "bleach / aqua" -> INVALID
    - "randomtext / niacinamide" -> INVALID)

Return ONLY valid JSON in this exact format:
{
  "raw_input": "${term}",
  "is_valid_synonym": true,
  "canonical_inci_name": "Standard Single INCI Name",
  "reason": "Brief English explanation why it is valid or invalid"
}

If it is INVALID, return:
{
  "raw_input": "${term}",
  "is_valid_synonym": false,
  "canonical_inci_name": null,
  "reason": "Explain why it is invalid or suspicious"
}
`;
    } else {
      prompt = `
You are an expert cosmetic chemist and regulatory toxicologist specializing in EU CosIng and INCI nomenclature.
Analyze the following ingredient candidate: "${term}"

Determine:
1. Is this a valid, authorized cosmetic ingredient according to EU CosIng / CIR / INCI standards? (boolean)
2. What is its standard cosmetic functional category? (e.g. Humectant, Emollient, Active / Vitamin, Surfactant, Preservative, Botanical Extract, UV Filter, etc.)
3. Provide a concise Thai explanation (1-2 sentences) of its cosmetic function and benefits.
4. Confidence score from 0 to 100.

Return ONLY valid JSON in this exact format:
{
  "name": "${term}",
  "is_valid_inci": true,
  "cosing_id": null,
  "category": "e.g. Active / Vitamin C",
  "description_th": "คำอธิบายภาษาไทยสั้นๆ 1-2 ประโยค",
  "confidence_score": 95
}

If the term is nonsense, spam, advertising text (e.g. "100% organic", "best cream"), or completely invalid, return:
{
  "name": "${term}",
  "is_valid_inci": false,
  "category": "Invalid",
  "description_th": "ไม่พบในฐานข้อมูลสารเครื่องสำอางสากล",
  "confidence_score": 0
}
`;
    }

    const routerRes = await aiRouter.execute(prompt, userKeys);
    return new Response(JSON.stringify(routerRes.data), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    console.error('Unhandled error in verify-ingredient:', err);
    return new Response(
      JSON.stringify({ error: err.message || 'Internal Server Error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
