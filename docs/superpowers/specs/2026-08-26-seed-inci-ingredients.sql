-- ====================================================================
-- PureCheck: Comprehensive Standard INCI Cosmetic Ingredients Database
-- Sourced from CosIng (European Commission) & CIR (Cosmetic Ingredient Review)
-- ====================================================================

-- 1. Ensure Table Structure & Extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS public.inci_ingredients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  category text,
  description_th text,
  created_at timestamptz DEFAULT now()
);

-- 2. Row Level Security Policies
ALTER TABLE public.inci_ingredients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read inci_ingredients" ON public.inci_ingredients;
CREATE POLICY "Public read inci_ingredients" ON public.inci_ingredients 
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow service role or admin manage inci_ingredients" ON public.inci_ingredients;
CREATE POLICY "Allow service role or admin manage inci_ingredients" ON public.inci_ingredients 
  FOR ALL USING (auth.role() = 'service_role' OR auth.role() = 'authenticated');

-- 3. Trigram Index for Fast Fuzzy & Substring Search
CREATE INDEX IF NOT EXISTS idx_inci_ingredients_name_trgm 
  ON public.inci_ingredients USING gin (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_inci_ingredients_name_lower 
  ON public.inci_ingredients (lower(name));

-- 4. Bulk Insert Standard INCI Ingredients
INSERT INTO public.inci_ingredients (name, category, description_th)
VALUES
  -- Solvents & Carriers
  ('Water', 'Solvent', 'น้ำบริสุทธิ์ ตัวทำละลายหลักในเครื่องสำอาง'),
  ('Aqua', 'Solvent', 'ชื่อเรียกสากลของน้ำในระบบ INCI'),
  ('Alcohol Denat.', 'Solvent / Astringent', 'แอลกอฮอล์แปลงสภาพ ช่วยฆ่าเชื้อและช่วยให้ผลิตภัณฑ์แห้งไว'),
  ('Propanediol', 'Solvent / Humectant', 'สารนำพาความชุ่มชื้นจากธรรมชาติ อ่อนโยนต่อผิว'),
  ('Butylene Glycol', 'Humectant / Solvent', 'สารช่วยนำพาความชุ่มชื้นและปรับเนื้อสัมผัส'),
  ('Dipropylene Glycol', 'Solvent / Humectant', 'ตัวทำละลายและกักเก็บความชุ่มชื้น'),
  ('Pentylene Glycol', 'Humectant / Solvent', 'สารให้ความชุ่มชื้นและช่วยเสริมฤทธิ์กันเสีย'),
  ('Hexylene Glycol', 'Solvent / Surfactant', 'ตัวทำละลายและสารช่วยทำความสะอาด'),
  ('Propylene Glycol', 'Humectant / Solvent', 'สารช่วยกักเก็บความชุ่มชื้น'),

  -- Humectants & Hydrators
  ('Glycerin', 'Humectant', 'สารกักเก็บความชุ่มชื้นให้แก่ผิวอย่างมีประสิทธิภาพสูง'),
  ('Hyaluronic Acid', 'Humectant', 'กรดไฮยาลูรอนิก ช่วยเติมน้ำและอุ้มน้ำให้ผิวเต่งตึง'),
  ('Sodium Hyaluronate', 'Humectant', 'เกลือโซเดียมของไฮยาลูรอนิก โมเลกุลเล็กซึมสู่ผิวง่าย'),
  ('Hydrolyzed Hyaluronic Acid', 'Humectant', 'ไฮยาลูรอนิกโมเลกุลเล็กพิเศษ ซึมลึกถึงผิวชั้นใน'),
  ('Sodium Acetylated Hyaluronate', 'Humectant', 'ซูเปอร์ไฮยาลูรอนิก ยึดเกาะผิวได้ยาวนาน'),
  ('Sodium Hyaluronate Crosspolymer', 'Humectant', 'ไฮยาลูรอนิกโครงสร้างตาข่าย ล็อคความชุ่มชื้นต่อเนื่อง'),
  ('Panthenol', 'Pro-Vitamin B5', 'พานทีนอล ช่วยฟื้นฟูผิว ลดอาการระคายเคืองและสมานแผล'),
  ('Urea', 'Humectant / Keratolytic', 'สารให้ความชุ่มชื้นตามธรรมชาติและช่วยผลัดเซลล์ผิวแห้งกร้าน'),
  ('Hydroxyethyl Urea', 'Humectant', 'อนุพันธ์ยูเรีย ให้ความชุ่มชื้นสูงโดยไม่เหนียวเหนอะหนะ'),
  ('Trehalose', 'Humectant / Antioxidant', 'น้ำตาลธรรมชาติช่วยปกป้องเซลล์ผิวจากการสูญเสียน้ำ'),
  ('Betaine', 'Humectant', 'สารสกัดจากชูการ์บีท ปรับสมดุลความชุ่มชื้นและลดการระคายเคือง'),
  ('Sodium PCA', 'NMF / Humectant', 'สารให้ความชุ่มชื้นตามธรรมชาติของผิว (NMF)'),
  ('Polyglutamic Acid', 'Humectant', 'กรดโพลีกลูตามิก อุ้มน้ำได้มากกว่าไฮยาลูรอนิกถึง 4-5 เท่า'),
  ('Beta-Glucan', 'Soothing / Humectant', 'เบต้ากลูแคน เสริมภูมิคุ้มกันผิวและลดการอักเสบ'),
  ('Saccharide Isomerate', 'Humectant', 'สารสกัดคาร์โบไฮเดรตธรรมชาติ ล็อคความชุ่มชื้นได้ถึง 72 ชม.'),

  -- Ceramides & Barrier Lipids
  ('Ceramide NP', 'Skin-Identical Lipid', 'เซราไมด์ 3 ช่วยเสริมสร้างเกราะป้องกันผิวให้แข็งแรง'),
  ('Ceramide AP', 'Skin-Identical Lipid', 'เซราไมด์ 6-II เสริมความยืดหยุ่นและเกราะผิว'),
  ('Ceramide EOP', 'Skin-Identical Lipid', 'เซราไมด์ 1 ยึดโครงสร้างเกราะชั้นผิวให้แข็งแรง'),
  ('Ceramide NS', 'Skin-Identical Lipid', 'เซราไมด์ 2 ช่วยเพิ่มความชุ่มชื้นในชั้นผิว'),
  ('Ceramide AS', 'Skin-Identical Lipid', 'เซราไมด์ 5 เสริมความแข็งแรงให้เยื่อหุ้มเซลล์ผิว'),
  ('Phytosphingosine', 'Skin-Identical Lipid', 'สารตั้งต้นเซราไมด์ มีฤทธิ์ต้านเชื้อแบคทีเรียและลดสิว'),
  ('Cholesterol', 'Skin-Identical Lipid', 'คอเลสเตอรอลธรรมชาติ ช่วยฟื้นฟูเกราะป้องกันผิวร่วมกับเซราไมด์'),
  ('Phospholipids', 'Emollient / Skin-Identical', 'ฟอสโฟลิพิด ช่วยนำพาสารอาหารและเสริมเกราะผิว'),
  ('Hydrogenated Lecithin', 'Emulsifier / Skin-Identical', 'เลซิตินธรรมชาติ ช่วยเสริมเกราะผิวและนำพาสารสกัด'),
  ('Squalane', 'Emollient / Skin-Identical', 'สควาเลนจากพืช ไม่อุดตันรูขุมขน กักเก็บความชุ่มชื้น'),
  ('Squalene', 'Emollient / Antioxidant', 'ไขมันธรรมชาติบำรุงผิวและต้านอนุมูลอิสระ'),

  -- Actives, Exfoliants & Vitamins
  ('Niacinamide', 'Active / Vitamin B3', 'วิตามินบี 3 ช่วยลดรอยแดง ปรับผิวกระจ่างใส และคุมมัน'),
  ('Salicylic Acid', 'Exfoliant (BHA)', 'กรดซาลิไซลิก ละลายในน้ำมัน สลายสิวอุดตันในรูขุมขน'),
  ('Glycolic Acid', 'Exfoliant (AHA)', 'กรดไกลโคลิก ผลัดเซลล์ผิวชั้นนอก เผยผิวเนียนกระจ่างใส'),
  ('Lactic Acid', 'Exfoliant (AHA) / Humectant', 'กรดแลกติก ผลัดเซลล์ผิวอย่างอ่อนโยนและให้ความชุ่มชื้น'),
  ('Mandelic Acid', 'Exfoliant (AHA)', 'กรดแมนเดลิก โมเลกุลใหญ่ อ่อนโยน เหมาะกับผิวแพ้ง่าย'),
  ('Gluconolactone', 'Exfoliant (PHA)', 'กรดพีเอชเอ ผลัดเซลล์ผิวอ่อนโยนพร้อมต้านอนุมูลอิสระ'),
  ('Lactobionic Acid', 'Exfoliant (PHA)', 'กรดแลคโตไบโอนิก อ่อนโยนและกักเก็บน้ำในผิว'),
  ('Retinol', 'Active (Vitamin A)', 'เรตินอล ช่วยลดเลือนริ้วรอย กระตุ้นคอลลาเจนและผลัดเซลล์ผิว'),
  ('Retinal', 'Active (Vitamin A)', 'เรตินัลดีไฮด์ แปลงสภาพเป็นกรดวิตามินเอได้ไวกว่าเรตินอล'),
  ('Bakuchiol', 'Active / Plant Alternative', 'สารสกัดพืชธรรมชาติ ออกฤทธิ์คล้ายเรตินอลโดยไม่ระคายเคือง'),
  ('Ascorbic Acid', 'Active (Vitamin C)', 'วิตามินซีบริสุทธิ์ ช่วยผิวกระจ่างใสและต้านอนุมูลอิสระ'),
  ('Ascorbyl Glucoside', 'Active (Vitamin C)', 'อนุพันธ์วิตามินซีเสถียรสูง อ่อนโยนต่อผิว'),
  ('3-O-Ethyl Ascorbic Acid', 'Active (Vitamin C)', 'อนุพันธ์วิตามินซีซึมสู่ผิวได้ลึกและคงตัวดีเยี่ยม'),
  ('Tetrahexyldecyl Ascorbate', 'Active (Vitamin C)', 'วิตามินซีละลายในไขมัน ซึมลึกและอ่อนโยน'),
  ('Sodium Ascorbyl Phosphate', 'Active (Vitamin C)', 'อนุพันธ์วิตามินซี มีคุณสมบัติต้านเชื้อสิว'),
  ('Tocopherol', 'Antioxidant (Vitamin E)', 'วิตามินอีธรรมชาติ ต้านอนุมูลอิสระและปกป้องไขมันในผิว'),
  ('Tocopheryl Acetate', 'Antioxidant (Vitamin E)', 'อนุพันธ์วิตามินอี ให้ความชุ่มชื้นและคงตัวสูง'),
  ('Azelaic Acid', 'Active', 'กรดอะเซลาอิก ลดการอักเสบ ฆ่าเชื้อสิว และลดรอยดำ'),
  ('Potassium Azeloyl Diglycinate', 'Active', 'อนุพันธ์กรดอะเซลาอิก คุมมันและปรับผิวกระจ่างใส'),
  ('Tranexamic Acid', 'Active', 'กรดทราเนซามิก ยับยั้งเม็ดสีเมลานิน ลดฝ้ากระจุดด่างดำ'),
  ('Alpha-Arbutin', 'Active', 'อัลฟ่าอาร์บูติน ปรับผิวกระจ่างใสและลดเลือนจุดด่างดำ'),
  ('Arbutin', 'Active', 'อาร์บูติน สารสกัดจากพืชธรรมชาติช่วยลดเลือนเม็ดสี'),
  ('Kojic Acid', 'Active', 'กรดโคจิก ช่วยลดการสร้างเม็ดสีผิว'),
  ('Allantoin', 'Soothing', 'อัลลันโทอิน ช่วยลดการระคายเคืองและสมานผิว'),
  ('Bisabolol', 'Soothing', 'บิซาโบลอล สารสกัดจากคาโมมายล์ ปลอบประโลมผิวแพ้ง่าย'),
  ('Ectoin', 'Soothing / Active', 'เอคโทอิน ปกป้องเซลล์ผิวจากมลภาวะและรังสียูวี'),
  ('Adenosine', 'Anti-Aging', 'อะดีโนซีน ฟื้นฟูเซลล์ผิวและลดเลือนริ้วรอย'),

  -- Fatty Alcohols, Emulsifiers & Esters
  ('Cetearyl Alcohol', 'Fatty Alcohol / Emulsifier', 'แอลกอฮอล์ไขมันชนิดปลอดภัย ให้ความนุ่มชุ่มชื้น'),
  ('Cetyl Alcohol', 'Fatty Alcohol / Emulsifier', 'แอลกอฮอล์เนื้อครีมปลอดภัย ช่วยเพิ่มเนื้อและกักความชื้น'),
  ('Stearyl Alcohol', 'Fatty Alcohol / Emulsifier', 'แอลกอฮอล์ไขมัน ช่วยผสานเนื้อครีมและให้ความนุ่มผิว'),
  ('Behenyl Alcohol', 'Fatty Alcohol / Emulsifier', 'แอลกอฮอล์ไขมันธรรมชาติ เพิ่มความเข้มข้นให้เนื้อสัมผัส'),
  ('Caprylic/Capric Triglyceride', 'Emollient', 'น้ำมันสกัดจากมะพร้าว บางเบา ไม่อุดตันรูขุมขน'),
  ('C12-15 Alkyl Benzoate', 'Emollient', 'สารบำรุงผิวนุ่มลื่น บางเบา ไม่เหนอะหนะ'),
  ('Cetyl Ethylhexanoate', 'Emollient', 'เอสเทอร์บำรุงผิว ให้สัมผัสเนียนลื่นเบาสบาย'),
  ('Isopropyl Myristate', 'Emollient', 'สารช่วยเพิ่มการดูดซึมและให้ความนุ่มลื่น'),
  ('Glyceryl Stearate', 'Emulsifier / Emollient', 'สารผสานน้ำกับน้ำมันธรรมชาติ ให้ความชุ่มชื้น'),
  ('PEG-100 Stearate', 'Emulsifier', 'สารช่วยผสานเนื้อครีมให้เข้ากันอย่างเนียนละเอียด'),
  ('PEG-40 Stearate', 'Emulsifier / Surfactant', 'สารช่วยทำความสะอาดและผสานเนื้อผลิตภัณฑ์'),
  ('Polysorbate 20', 'Emulsifier / Solubilizer', 'สารช่วยละลายน้ำหอมและสารสกัดในน้ำ'),
  ('Polysorbate 60', 'Emulsifier', 'สารผสานเนื้อครีมและโลชั่น'),
  ('Polysorbate 80', 'Emulsifier', 'สารผสานน้ำมันในน้ำอย่างเสถียร'),
  ('Cetearyl Glucoside', 'Emulsifier', 'สารผสานเนื้อครีมธรรมชาติจากน้ำตาลและข้าวโพด'),
  ('Sorbitan Olivate', 'Emulsifier', 'สารผสานเนื้อจากน้ำมันมะกอก อ่อนโยนต่อผิว'),
  ('Cetearyl Olivate', 'Emulsifier', 'สารผสานจากน้ำมันมะกอก เสริมความแข็งแรงเกราะผิว'),
  ('Behentrimonium Methosulfate', 'Conditioning / Emulsifier', 'สารปรับผิวนุ่มลื่น อ่อนโยน ไม่ระคายเคือง'),
  ('Sodium Lauroyl Lactylate', 'Emulsifier / Surfactant', 'สารผสานช่วยเสริมการทำงานของเซราไมด์ในชั้นผิว'),
  ('Ceteareth-20', 'Emulsifier', 'สารช่วยผสานเนื้ออิมัลชัน'),

  -- Surfactants & Cleansing Agents
  ('Cocamidopropyl Betaine', 'Surfactant (Amphoteric)', 'สารทำความสะอาดจากมะพร้าว ฟองนุ่ม อ่อนโยน'),
  ('Sodium Cocoyl Isethionate', 'Surfactant (Anionic)', 'สารทำความสะอาดสูตรอ่อนโยนพิเศษจากมะพร้าว'),
  ('Sodium Lauroyl Sarcosinate', 'Surfactant', 'สารทำความสะอาดอ่อนโยน ไม่ทำลายเกราะผิว'),
  ('Coco-Glucoside', 'Surfactant (Non-ionic)', 'สารทำความสะอาดธรรมชาติจากมะพร้าวและน้ำตาล'),
  ('Decyl Glucoside', 'Surfactant (Non-ionic)', 'สารทำความสะอาดจากพืช อ่อนโยนสำหรับผิวบอบบาง'),
  ('Lauryl Glucoside', 'Surfactant (Non-ionic)', 'สารทำความสะอาดจากพืช ย่อยสลายได้ตามธรรมชาติ'),
  ('Sodium Methyl Cocoyl Taurate', 'Surfactant', 'สารทำความสะอาดฟองละเอียด อ่อนโยน ไม่แห้งตึง'),
  ('Disodium Laureth Sulfosuccinate', 'Surfactant', 'สารทำความสะอาดอ่อนโยน ปราศจากซัลเฟตระคายเคือง'),

  -- Thickeners & Polymers
  ('Carbomer', 'Viscosity Control / Polymer', 'สารเพิ่มความหนืดและขึ้นเนื้อเจลใส'),
  ('Xanthan Gum', 'Viscosity Control / Natural', 'สารเพิ่มความหนืดธรรมชาติจากกระบวนการหมัก'),
  ('Acrylates/C10-30 Alkyl Acrylate Crosspolymer', 'Viscosity Control', 'โพลีเมอร์ช่วยสร้างเนื้อเจลและกักเก็บน้ำมัน'),
  ('Hydroxyethylcellulose', 'Viscosity Control', 'สารเพิ่มความหนืดจากเซลลูโลสพืช'),
  ('Ammonium Acryloyldimethyltaurate/VP Copolymer', 'Viscosity Control', 'โพลีเมอร์สร้างเนื้อสัมผัสบางเบา เกลี่ยง่าย'),
  ('Polyacrylate Crosspolymer-6', 'Viscosity Control', 'สารสร้างเนื้อเจลครีมสัมผัสนุ่มละมุน'),

  -- Silicones
  ('Dimethicone', 'Emollient / Silicone', 'ซิลิโคนปลอดภัย ช่วยเคลือบกักความชื้นและให้ผิวเนียนลื่น'),
  ('Cyclopentasiloxane', 'Silicone', 'ซิลิโคนระเหยไว ให้สัมผัสบางเบา ไม่เหนียวเหนอะ'),
  ('Cyclohexasiloxane', 'Silicone', 'ซิลิโคนเพิ่มความนุ่มลื่นและกระจายตัว'),
  ('Dimethiconol', 'Silicone', 'ซิลิโคนช่วยเคลือบปกป้องผิวและเส้นผม'),
  ('Phenyl Trimethicone', 'Silicone', 'ซิลิโคนช่วยเพิ่มความเงางามและนุ่มลื่น'),

  -- Preservatives, Buffers & Chelators
  ('Phenoxyethanol', 'Preservative', 'สารกันเสียมาตรฐานความปลอดภัยสูง อ่อนโยน'),
  ('Ethylhexylglycerin', 'Preservative Booster / Humectant', 'สารเสริมฤทธิ์กันเสียและบำรุงผิวนุ่มชุ่มชื้น'),
  ('Sodium Benzoate', 'Preservative', 'สารกันเสียเกรดอาหาร ปลอดภัยต่อผิว'),
  ('Potassium Sorbate', 'Preservative', 'สารกันเสียธรรมชาติ ป้องกันเชื้อราและยีสต์'),
  ('1,2-Hexanediol', 'Preservative Booster / Solvent', 'สารยับยั้งเชื้อและเพิ่มความชุ่มชื้น'),
  ('Caprylyl Glycol', 'Preservative Booster / Emollient', 'สารเสริมการกันเสียและให้ความชุ่มชื้น'),
  ('Disodium EDTA', 'Chelating Agent', 'สารจับประจุโลหะ ช่วยรักษาความเสถียรของสูตร'),
  ('Tetrasodium EDTA', 'Chelating Agent', 'สารจับประจุโลหะ เพิ่มประสิทธิภาพการทำความสะอาด'),
  ('Citric Acid', 'pH Adjuster / AHA', 'กรดซิตริกธรรมชาติ ช่วยปรับสมดุลค่า pH ให้เหมาะกับผิว'),
  ('Sodium Citrate', 'Buffering Agent', 'เกลือโซเดียมซิเตรต ควบคุมค่า pH ให้คงที่'),
  ('Sodium Hydroxide', 'pH Adjuster', 'สารปรับค่าความเป็นกรด-ด่าง'),
  ('Potassium Phosphate', 'Buffering Agent', 'สารควบคุมสมดุลกรด-ด่างในผลิตภัณฑ์'),
  ('Dipotassium Phosphate', 'Buffering Agent', 'สารควบคุมและรักษาเสถียรภาพค่า pH'),

  -- Sunscreens / UV Filters
  ('Zinc Oxide', 'Physical UV Filter', 'ซิงค์ออกไซด์ กันแดดสะท้อนรังสี UVA/UVB อ่อนโยนพิเศษ'),
  ('Titanium Dioxide', 'Physical UV Filter', 'ไททาเนียมไดออกไซด์ กันแดดสะท้อนรังสี UVB/UVA'),
  ('Ethylhexyl Methoxycinnamate', 'Chemical UV Filter', 'สารกันแดดดูดซับรังสี UVB ประสิทธิภาพสูง'),
  ('Ethylhexyl Salicylate', 'Chemical UV Filter', 'สารดูดซับรังสี UVB และช่วยให้สารกันแดดอื่นเสถียร'),
  ('Homosalate', 'Chemical UV Filter', 'สารกรองรังสี UVB'),
  ('Avobenzone', 'Chemical UV Filter', 'สารกันแดดดูดซับรังสี UVA ได้อย่างครอบคลุม'),
  ('Octocrylene', 'Chemical UV Filter', 'สารกันแดดดูดซับรังสี UVB และช่วยให้ Avobenzone เสถียร'),
  ('Bis-Ethylhexyloxyphenol Methoxyphenyl Triazine', 'Chemical UV Filter (Tinosorb S)', 'สารกันแดดรุ่นใหม่ ป้องกันทั้ง UVA และ UVB เสถียรสูงมาก'),
  ('Methylene Bis-Benzotriazolyl Tetramethylbutylphenol', 'Hybrid UV Filter (Tinosorb M)', 'สารกันแดดไฮบริด ดูดซับและสะท้อนรังสีได้ในตัวเดียว'),
  ('Diethylamino Hydroxybenzoyl Hexyl Benzoate', 'Chemical UV Filter (Uvinul A Plus)', 'สารกันแดด UVA เสถียรสูง ไม่เสื่อมสลายง่าย'),
  ('Ethylhexyl Triazone', 'Chemical UV Filter (Uvinul T 150)', 'สารกันแดด UVB ประสิทธิภาพการดูดซับสูงสุด'),

  -- Botanicals & Extracts
  ('Centella Asiatica Extract', 'Botanical Extract', 'สารสกัดใบบัวบก ปลอบประโลมผิว ลดการอักเสบและรอยสิว'),
  ('Madecassoside', 'Active Botanical', 'สารบริสุทธิ์จากใบบัวบก สมานแผลและลดการระคายเคือง'),
  ('Asiaticoside', 'Active Botanical', 'สารสกัดใบบัวบก ช่วยกระตุ้นการสร้างคอลลาเจน'),
  ('Aloe Barbadensis Leaf Juice', 'Botanical Extract', 'น้ำว่านหางจระเข้ เติมความชุ่มชื้นและลดอาการแสบแดง'),
  ('Aloe Barbadensis Leaf Extract', 'Botanical Extract', 'สารสกัดว่านหางจระเข้ บำรุงผิวให้เนียนนุ่ม'),
  ('Camellia Sinensis Leaf Extract', 'Botanical / Antioxidant', 'สารสกัดชาเขียว ต้านอนุมูลอิสระและคุมความมัน'),
  ('Chamomilla Recutita (Matricaria) Flower Extract', 'Botanical Extract', 'สารสกัดดอกคาโมมายล์ ลดการแพ้และระคายเคือง'),
  ('Glycyrrhiza Glabra (Licorice) Root Extract', 'Botanical Extract', 'สารสกัดชะเอมเทศ ลดรอยดำและต้านการอักเสบ'),
  ('Melaleuca Alternifolia (Tea Tree) Leaf Oil', 'Essential Oil / Active', 'น้ำมันทีทรี ยับยั้งเชื้อแบคทีเรียสาเหตุของสิว'),
  ('Calendula Officinalis Flower Extract', 'Botanical Extract', 'สารสกัดดอกดาวเรือง สมานผิวและฟื้นฟูผิวแห้งกร้าน'),
  ('Houttuynia Cordata Extract', 'Botanical Extract', 'สารสกัดพลูคาว ต้านการอักเสบและกระชับรูขุมขน'),
  ('Salix Alba (Willow) Bark Extract', 'Botanical Extract', 'สารสกัดเปลือกวิลโลว์ แหล่งกรดซาลิไซลิกธรรมชาติ'),
  ('Artemisia Princeps Leaf Extract', 'Botanical Extract', 'สารสกัดจิงจูฉ่าย/มักวอร์ต ปลอบประโลมผิวแพ้ง่าย'),
  ('Avena Sativa (Oat) Kernel Extract', 'Botanical Extract', 'สารสกัดข้าวโอ๊ต ลดอาการคันและเสริมเกราะผิว'),
  ('Propolis Extract', 'Natural Active', 'สารสกัดพรอพอลิส ฆ่าเชื้อแบคทีเรียและฟื้นฟูผิว'),
  ('Snail Secretion Filtrate', 'Natural Active', 'เมือกหอยทาก ซ่อมแซมเซลล์ผิวและเพิ่มความยืดหยุ่น'),
  ('Galactomyces Ferment Filtrate', 'Ferment Active', 'พิเทร่า/กาแลคโตมัยเซส ปรับผิวเรียบเนียนกระจ่างใส'),
  ('Bifida Ferment Lysate', 'Probiotic / Active', 'สารหมักบิฟิดา ฟื้นฟูเกราะป้องกันผิวและต้านริ้วรอย'),

  -- Plant Oils & Butters
  ('Simmondsia Chinensis (Jojoba) Seed Oil', 'Plant Oil', 'น้ำมันโจโจ้บา โครงสร้างใกล้เคียงน้ำมันผิว ไม่อุดตัน'),
  ('Helianthus Annuus (Sunflower) Seed Oil', 'Plant Oil', 'น้ำมันเมล็ดทานตะวัน อุดมด้วยวิตามินอีและกรดไขมันจำเป็น'),
  ('Argania Spinosa Kernel Oil', 'Plant Oil', 'น้ำมันอาร์แกน บำรุงผิวล้ำลึกและชะลอริ้วรอย'),
  ('Rosa Canina Fruit Oil', 'Plant Oil', 'น้ำมันโรสฮิป อุดมด้วยวิตามินเอและซี ลดรอยแผลเป็น'),
  ('Butyrospermum Parkii (Shea) Butter', 'Plant Butter', 'เชียบัตเตอร์ บำรุงผิวแห้งแตกให้เนียนนุ่มชุ่มชื้น')
ON CONFLICT (name) DO UPDATE SET
  category = EXCLUDED.category,
  description_th = EXCLUDED.description_th;
