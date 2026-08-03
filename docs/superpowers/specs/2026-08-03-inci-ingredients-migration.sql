-- Enable pg_trgm extension for fuzzy trigram search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create inci_ingredients table
CREATE TABLE IF NOT EXISTS public.inci_ingredients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  category text,
  description_th text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.inci_ingredients ENABLE ROW LEVEL SECURITY;

-- Allow public read access
CREATE POLICY "Public read inci_ingredients" ON public.inci_ingredients 
  FOR SELECT USING (true);

-- Create Trigram GIN Index for fast fuzzy search
CREATE INDEX IF NOT EXISTS idx_inci_ingredients_name_trgm 
  ON public.inci_ingredients USING gin (name gin_trgm_ops);

-- Seed initial common INCI cosmetic ingredients
INSERT INTO public.inci_ingredients (name, category, description_th)
VALUES
  ('Water', 'Solvent', 'น้ำบริสุทธิ์ ตัวทำละลายหลักในเครื่องสำอาง'),
  ('Aqua', 'Solvent', 'ชื่อเรียกสากลของน้ำในระบบ INCI'),
  ('Glycerin', 'Humectant', 'สารกักเก็บความชุ่มชื้นให้แก่ผิว'),
  ('Niacinamide', 'Vitamin / Active', 'วิตามินบี 3 ช่วยลดรอยแดง ปรับผิวกระจ่างใส และลดความมัน'),
  ('Hyaluronic Acid', 'Humectant', 'กรดไฮยาลูรอนิก ช่วยเติมน้ำและอุ้มน้ำให้ผิว'),
  ('Sodium Hyaluronate', 'Humectant', 'เกลือโซเดียมของไฮยาลูรอนิก โมเลกุลเล็กซึมสู่ผิวง่าย'),
  ('Salicylic Acid', 'Exfoliant (BHA)', 'กรดซาลิไซลิก ช่วยผลัดเซลล์ผิวและไม่อุดตันรูขุมขน'),
  ('Centella Asiatica Extract', 'Botanical Extract', 'สารสกัดใบบัวบก ช่วยปลอบประโลมผิวและลดการอักเสบ'),
  ('Ceramide NP', 'Skin-Identical', 'เซราไมด์ช่วยเสริมสร้างเกราะป้องกันผิวให้แข็งแรง'),
  ('Panthenol', 'Pro-Vitamin B5', 'พานทีนอล ช่วยฟื้นฟูผิวและลดอาการระคายเคือง'),
  ('Tocopherol', 'Antioxidant (Vitamin E)', 'วิตามินอี ช่วยต่อต้านอนุมูลอิสระและบำรุงผิว'),
  ('Cetearyl Alcohol', 'Fatty Alcohol / Emulsifier', 'แอลกอฮอล์กลุ่มไขมันที่ปลอดภัย ให้ความนุ่มชุ่มชื้นแก่ผิว'),
  ('Cetyl Alcohol', 'Fatty Alcohol / Emulsifier', 'แอลกอฮอล์เนื้อครีมปลอดภัย ช่วยเพิ่มเนื้อและกักความชื้น'),
  ('Butylene Glycol', 'Humectant / Solvent', 'สารช่วยนำพาความชุ่มชื้นและปรับเนื้อสัมผัส'),
  ('Propylene Glycol', 'Humectant / Solvent', 'สารช่วยกักเก็บความชุ่มชื้น'),
  ('Allantoin', 'Soothing', 'อัลลันโทอิน ช่วยลดการระคายเคืองและสมานผิว'),
  ('Retinol', 'Active (Vitamin A)', 'เรตินอล ช่วยลดเลือนริ้วรอยและกระตุ้นคอลลาเจน'),
  ('Dimethicone', 'Emollient / Silicone', 'ซิลิโคนที่ปลอดภัย ช่วยเคลือบผิวให้เนียนลื่น')
ON CONFLICT (name) DO NOTHING;
