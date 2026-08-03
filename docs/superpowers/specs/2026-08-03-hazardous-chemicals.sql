-- hazardous_chemicals (Blacklist DB for AI Guardrails)
CREATE TABLE IF NOT EXISTS public.hazardous_chemicals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chemical_name text NOT NULL UNIQUE,
  aliases text[] DEFAULT '{}',
  risk_level text CHECK (risk_level IN ('caution', 'danger')) DEFAULT 'danger',
  hazard_category text, -- e.g., 'Carcinogen', 'Endocrine Disruptor', 'Severe Allergen'
  description_th text,
  description_en text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on hazardous_chemicals
ALTER TABLE public.hazardous_chemicals ENABLE ROW LEVEL SECURITY;

-- Allow read access to all users
CREATE POLICY "Public read hazardous chemicals" ON public.hazardous_chemicals 
  FOR SELECT USING (true);

-- Seed initial high-risk hazardous cosmetic ingredients
INSERT INTO public.hazardous_chemicals (chemical_name, aliases, risk_level, hazard_category, description_th, description_en)
VALUES 
  ('Hydroquinone', ARRAY['1,4-Benzenediol'], 'danger', 'Skin Lightener Toxicity', 'สารฟอกขาวต้องห้ามก่อให้เกิดการระคายเคืองอย่างรุนแรงและผิวบาง', 'Prohibited bleaching agent causing severe skin thinning and irritation'),
  ('Mercury', ARRAY['Mercuric chloride', 'Ammoniated mercury'], 'danger', 'Heavy Metal Toxicity', 'โลหะหนักอันตรายทำลายระบบประสาทและไต', 'Toxic heavy metal harmful to nervous system and kidneys'),
  ('Formaldehyde', ARRAY['Formolin', 'Methanal'], 'danger', 'Carcinogen & Severe Allergen', 'สารกันเสียก่อมะเร็งและระคายเคืองสูง', 'Carcinogenic preservative and severe irritant'),
  ('Parabens', ARRAY['Methylparaben', 'Propylparaben', 'Butylparaben'], 'caution', 'Endocrine Disruptor', 'สารกันเสียที่อาจรบกวนระบบฮอร์โมนในร่างกาย', 'Preservative potentially disrupting hormonal system'),
  ('Phthalates', ARRAY['DBP', 'DEP', 'DEHP'], 'danger', 'Reproductive Toxicity', 'สารพลาสติไซเซอร์อันตรายต่อระบบสืบพันธุ์', 'Plasticizer dangerous to reproductive system')
ON CONFLICT (chemical_name) DO NOTHING;
