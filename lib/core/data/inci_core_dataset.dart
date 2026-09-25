/// Curated Standard INCI Cosmetic Ingredient Dataset
/// Sourced from CosIng (European Commission) & CIR (Cosmetic Ingredient Review) standards.
class InciItem {
  final String name;
  final String category;
  final String descriptionTh;

  const InciItem({
    required this.name,
    required this.category,
    required this.descriptionTh,
  });
}

class InciCoreDataset {
  static const List<InciItem> items = [
    // Solvents & Carriers
    InciItem(name: 'Water', category: 'Solvent', descriptionTh: 'น้ำบริสุทธิ์ ตัวทำละลายหลักในเครื่องสำอาง'),
    InciItem(name: 'Aqua', category: 'Solvent', descriptionTh: 'ชื่อเรียกสากลของน้ำในระบบ INCI'),
    InciItem(name: 'Aqua / Water / Eau', category: 'Solvent', descriptionTh: 'น้ำบริสุทธิ์ (ชื่อควบ 3 ภาษา: ละติน / อังกฤษ / ฝรั่งเศส)'),
    InciItem(name: 'Aqua/Water/Eau', category: 'Solvent', descriptionTh: 'น้ำบริสุทธิ์ (ชื่อควบ 3 ภาษา: ละติน / อังกฤษ / ฝรั่งเศส)'),
    InciItem(name: 'Aqua / Water', category: 'Solvent', descriptionTh: 'น้ำบริสุทธิ์ (ชื่อควบ 2 ภาษา: ละติน / อังกฤษ)'),
    InciItem(name: 'Aqua/Water', category: 'Solvent', descriptionTh: 'น้ำบริสุทธิ์ (ชื่อควบ 2 ภาษา: ละติน / อังกฤษ)'),
    InciItem(name: 'Water / Aqua', category: 'Solvent', descriptionTh: 'น้ำบริสุทธิ์ (ชื่อควบ 2 ภาษา: อังกฤษ / ละติน)'),
    InciItem(name: 'Water/Aqua', category: 'Solvent', descriptionTh: 'น้ำบริสุทธิ์ (ชื่อควบ 2 ภาษา: อังกฤษ / ละติน)'),
    InciItem(name: 'Water (Aqua)', category: 'Solvent', descriptionTh: 'น้ำบริสุทธิ์ (ระบบ INCI)'),
    InciItem(name: 'Aqua (Water)', category: 'Solvent', descriptionTh: 'น้ำบริสุทธิ์ (ระบบ INCI)'),
    InciItem(name: 'Alcohol Denat.', category: 'Solvent / Astringent', descriptionTh: 'แอลกอฮอล์แปลงสภาพ ช่วยฆ่าเชื้อและช่วยให้ผลิตภัณฑ์แห้งไว'),
    InciItem(name: 'Alcohol Denat', category: 'Solvent / Astringent', descriptionTh: 'แอลกอฮอล์แปลงสภาพ ช่วยฆ่าเชื้อและช่วยให้ผลิตภัณฑ์แห้งไว'),
    InciItem(name: 'Propanediol', category: 'Solvent / Humectant', descriptionTh: 'สารนำพาความชุ่มชื้นจากธรรมชาติ อ่อนโยนต่อผิว'),
    InciItem(name: 'Butylene Glycol', category: 'Humectant / Solvent', descriptionTh: 'สารช่วยนำพาความชุ่มชื้นและปรับเนื้อสัมผัส'),
    InciItem(name: 'Dipropylene Glycol', category: 'Solvent / Humectant', descriptionTh: 'ตัวทำละลายและกักเก็บความชุ่มชื้น'),
    InciItem(name: 'Pentylene Glycol', category: 'Humectant / Solvent', descriptionTh: 'สารให้ความชุ่มชื้นและช่วยเสริมฤทธิ์กันเสีย'),
    InciItem(name: 'Hexylene Glycol', category: 'Solvent / Surfactant', descriptionTh: 'ตัวทำละลายและสารช่วยทำความสะอาด'),
    InciItem(name: 'Propylene Glycol', category: 'Humectant / Solvent', descriptionTh: 'สารช่วยกักเก็บความชุ่มชื้น'),

    // Humectants & Hydrators
    InciItem(name: 'Glycerin', category: 'Humectant', descriptionTh: 'สารกักเก็บความชุ่มชื้นให้แก่ผิวอย่างมีประสิทธิภาพสูง'),
    InciItem(name: 'Hyaluronic Acid', category: 'Humectant', descriptionTh: 'กรดไฮยาลูรอนิก ช่วยเติมน้ำและอุ้มน้ำให้ผิวเต่งตึง'),
    InciItem(name: 'Sodium Hyaluronate', category: 'Humectant', descriptionTh: 'เกลือโซเดียมของไฮยาลูรอนิก โมเลกุลเล็กซึมสู่ผิวง่าย'),
    InciItem(name: 'Hydrolyzed Hyaluronic Acid', category: 'Humectant', descriptionTh: 'ไฮยาลูรอนิกโมเลกุลเล็กพิเศษ ซึมลึกถึงผิวชั้นใน'),
    InciItem(name: 'Sodium Acetylated Hyaluronate', category: 'Humectant', descriptionTh: 'ซูเปอร์ไฮยาลูรอนิก ยึดเกาะผิวได้ยาวนาน'),
    InciItem(name: 'Sodium Hyaluronate Crosspolymer', category: 'Humectant', descriptionTh: 'ไฮยาลูรอนิกโครงสร้างตาข่าย ล็อคความชุ่มชื้นต่อเนื่อง'),
    InciItem(name: 'Panthenol', category: 'Pro-Vitamin B5', descriptionTh: 'พานทีนอล ช่วยฟื้นฟูผิว ลดอาการระคายเคืองและสมานแผล'),
    InciItem(name: 'Urea', category: 'Humectant / Keratolytic', descriptionTh: 'สารให้ความชุ่มชื้นตามธรรมชาติและช่วยผลัดเซลล์ผิวแห้งกร้าน'),
    InciItem(name: 'Hydroxyethyl Urea', category: 'Humectant', descriptionTh: 'อนุพันธ์ยูเรีย ให้ความชุ่มชื้นสูงโดยไม่เหนียวเหนอะหนะ'),
    InciItem(name: 'Trehalose', category: 'Humectant / Antioxidant', descriptionTh: 'น้ำตาลธรรมชาติช่วยปกป้องเซลล์ผิวจากการสูญเสียน้ำ'),
    InciItem(name: 'Betaine', category: 'Humectant', descriptionTh: 'สารสกัดจากชูการ์บีท ปรับสมดุลความชุ่มชื้นและลดการระคายเคือง'),
    InciItem(name: 'Sodium PCA', category: 'NMF / Humectant', descriptionTh: 'สารให้ความชุ่มชื้นตามธรรมชาติของผิว (NMF)'),
    InciItem(name: 'Polyglutamic Acid', category: 'Humectant', descriptionTh: 'กรดโพลีกลูตามิก อุ้มน้ำได้มากกว่าไฮยาลูรอนิกถึง 4-5 เท่า'),
    InciItem(name: 'Beta-Glucan', category: 'Soothing / Humectant', descriptionTh: 'เบต้ากลูแคน เสริมภูมิคุ้มกันผิวและลดการอักเสบ'),
    InciItem(name: 'Saccharide Isomerate', category: 'Humectant', descriptionTh: 'สารสกัดคาร์โบไฮเดรตธรรมชาติ ล็อคความชุ่มชื้นได้ถึง 72 ชม.'),

    // Ceramides & Barrier Lipids
    InciItem(name: 'Ceramide NP', category: 'Skin-Identical Lipid', descriptionTh: 'เซราไมด์ 3 ช่วยเสริมสร้างเกราะป้องกันผิวให้แข็งแรง'),
    InciItem(name: 'Ceramide AP', category: 'Skin-Identical Lipid', descriptionTh: 'เซราไมด์ 6-II เสริมความยืดหยุ่นและเกราะผิว'),
    InciItem(name: 'Ceramide EOP', category: 'Skin-Identical Lipid', descriptionTh: 'เซราไมด์ 1 ยึดโครงสร้างเกราะชั้นผิวให้แข็งแรง'),
    InciItem(name: 'Ceramide NS', category: 'Skin-Identical Lipid', descriptionTh: 'เซราไมด์ 2 ช่วยเพิ่มความชุ่มชื้นในชั้นผิว'),
    InciItem(name: 'Ceramide AS', category: 'Skin-Identical Lipid', descriptionTh: 'เซราไมด์ 5 เสริมความแข็งแรงให้เยื่อหุ้มเซลล์ผิว'),
    InciItem(name: 'Phytosphingosine', category: 'Skin-Identical Lipid', descriptionTh: 'สารตั้งต้นเซราไมด์ มีฤทธิ์ต้านเชื้อแบคทีเรียและลดสิว'),
    InciItem(name: 'Cholesterol', category: 'Skin-Identical Lipid', descriptionTh: 'คอเลสเตอรอลธรรมชาติ ช่วยฟื้นฟูเกราะป้องกันผิวร่วมกับเซราไมด์'),
    InciItem(name: 'Phospholipids', category: 'Emollient / Skin-Identical', descriptionTh: 'ฟอสโฟลิพิด ช่วยนำพาสารอาหารและเสริมเกราะผิว'),
    InciItem(name: 'Hydrogenated Lecithin', category: 'Emulsifier / Skin-Identical', descriptionTh: 'เลซิตินธรรมชาติ ช่วยเสริมเกราะผิวและนำพาสารสกัด'),
    InciItem(name: 'Squalane', category: 'Emollient / Skin-Identical', descriptionTh: 'สควาเลนจากพืช ไม่อุดตันรูขุมขน กักเก็บความชุ่มชื้น'),
    InciItem(name: 'Squalene', category: 'Emollient / Antioxidant', descriptionTh: 'ไขมันธรรมชาติบำรุงผิวและต้านอนุมูลอิสระ'),

    // Actives, Exfoliants & Vitamins
    InciItem(name: 'Niacinamide', category: 'Active / Vitamin B3', descriptionTh: 'วิตามินบี 3 ช่วยลดรอยแดง ปรับผิวกระจ่างใส และคุมมัน'),
    InciItem(name: 'Salicylic Acid', category: 'Exfoliant (BHA)', descriptionTh: 'กรดซาลิไซลิก ละลายในน้ำมัน สลายสิวอุดตันในรูขุมขน'),
    InciItem(name: 'Glycolic Acid', category: 'Exfoliant (AHA)', descriptionTh: 'กรดไกลโคลิก ผลัดเซลล์ผิวชั้นนอก เผยผิวเนียนกระจ่างใส'),
    InciItem(name: 'Lactic Acid', category: 'Exfoliant (AHA) / Humectant', descriptionTh: 'กรดแลกติก ผลัดเซลล์ผิวอย่างอ่อนโยนและให้ความชุ่มชื้น'),
    InciItem(name: 'Mandelic Acid', category: 'Exfoliant (AHA)', descriptionTh: 'กรดแมนเดลิก โมเลกุลใหญ่ อ่อนโยน เหมาะกับผิวแพ้ง่าย'),
    InciItem(name: 'Gluconolactone', category: 'Exfoliant (PHA)', descriptionTh: 'กรดพีเอชเอ ผลัดเซลล์ผิวอ่อนโยนพร้อมต้านอนุมูลอิสระ'),
    InciItem(name: 'Lactobionic Acid', category: 'Exfoliant (PHA)', descriptionTh: 'กรดแลคโตไบโอนิก อ่อนโยนและกักเก็บน้ำในผิว'),
    InciItem(name: 'Retinol', category: 'Active (Vitamin A)', descriptionTh: 'เรตินอล ช่วยลดเลือนริ้วรอย กระตุ้นคอลลาเจนและผลัดเซลล์ผิว'),
    InciItem(name: 'Retinal', category: 'Active (Vitamin A)', descriptionTh: 'เรตินัลดีไฮด์ แปลงสภาพเป็นกรดวิตามินเอได้ไวกว่าเรตินอล'),
    InciItem(name: 'Bakuchiol', category: 'Active / Plant Alternative', descriptionTh: 'สารสกัดพืชธรรมชาติ ออกฤทธิ์คล้ายเรตินอลโดยไม่ระคายเคือง'),
    InciItem(name: 'Ascorbic Acid', category: 'Active (Vitamin C)', descriptionTh: 'วิตามินซีบริสุทธิ์ ช่วยผิวกระจ่างใสและต้านอนุมูลอิสระ'),
    InciItem(name: 'Ascorbyl Glucoside', category: 'Active (Vitamin C)', descriptionTh: 'อนุพันธ์วิตามินซีเสถียรสูง อ่อนโยนต่อผิว'),
    InciItem(name: '3-O-Ethyl Ascorbic Acid', category: 'Active (Vitamin C)', descriptionTh: 'อนุพันธ์วิตามินซีซึมสู่ผิวได้ลึกและคงตัวดีเยี่ยม'),
    InciItem(name: 'Tetrahexyldecyl Ascorbate', category: 'Active (Vitamin C)', descriptionTh: 'วิตามินซีละลายในไขมัน ซึมลึกและอ่อนโยน'),
    InciItem(name: 'Sodium Ascorbyl Phosphate', category: 'Active (Vitamin C)', descriptionTh: 'อนุพันธ์วิตามินซี มีคุณสมบัติต้านเชื้อสิว'),
    InciItem(name: 'Tocopherol', category: 'Antioxidant (Vitamin E)', descriptionTh: 'วิตามินอีธรรมชาติ ต้านอนุมูลอิสระและปกป้องไขมันในผิว'),
    InciItem(name: 'Tocopherol (Vitamin E)', category: 'Antioxidant (Vitamin E)', descriptionTh: 'วิตามินอีธรรมชาติ ต้านอนุมูลอิสระและปกป้องไขมันในผิว'),
    InciItem(name: 'Tocopheryl Acetate', category: 'Antioxidant (Vitamin E)', descriptionTh: 'อนุพันธ์วิตามินอี ให้ความชุ่มชื้นและคงตัวสูง'),
    InciItem(name: 'Azelaic Acid', category: 'Active', descriptionTh: 'กรดอะเซลาอิก ลดการอักเสบ ฆ่าเชื้อสิว และลดรอยดำ'),
    InciItem(name: 'Potassium Azeloyl Diglycinate', category: 'Active', descriptionTh: 'อนุพันธ์กรดอะเซลาอิก คุมมันและปรับผิวกระจ่างใส'),
    InciItem(name: 'Tranexamic Acid', category: 'Active', descriptionTh: 'กรดทราเนซามิก ยับยั้งเม็ดสีเมลานิน ลดฝ้ากระจุดด่างดำ'),
    InciItem(name: 'Alpha-Arbutin', category: 'Active', descriptionTh: 'อัลฟ่าอาร์บูติน ปรับผิวกระจ่างใสและลดเลือนจุดด่างดำ'),
    InciItem(name: 'Arbutin', category: 'Active', descriptionTh: 'อาร์บูติน สารสกัดจากพืชธรรมชาติช่วยลดเลือนเม็ดสี'),
    InciItem(name: 'Kojic Acid', category: 'Active', descriptionTh: 'กรดโคจิก ช่วยลดการสร้างเม็ดสีผิว'),
    InciItem(name: 'Allantoin', category: 'Soothing', descriptionTh: 'อัลลันโทอิน ช่วยลดการระคายเคืองและสมานผิว'),
    InciItem(name: 'Bisabolol', category: 'Soothing', descriptionTh: 'บิซาโบลอล สารสกัดจากคาโมมายล์ ปลอบประโลมผิวแพ้ง่าย'),
    InciItem(name: 'Ectoin', category: 'Soothing / Active', descriptionTh: 'เอคโทอิน ปกป้องเซลล์ผิวจากมลภาวะและรังสียูวี'),
    InciItem(name: 'Adenosine', category: 'Anti-Aging', descriptionTh: 'อะดีโนซีน ฟื้นฟูเซลล์ผิวและลดเลือนริ้วรอย'),

    // Fatty Alcohols, Emulsifiers & Esters
    InciItem(name: 'Cetearyl Alcohol', category: 'Fatty Alcohol / Emulsifier', descriptionTh: 'แอลกอฮอล์ไขมันชนิดปลอดภัย ให้ความนุ่มชุ่มชื้น'),
    InciItem(name: 'Cetyl Alcohol', category: 'Fatty Alcohol / Emulsifier', descriptionTh: 'แอลกอฮอล์เนื้อครีมปลอดภัย ช่วยเพิ่มเนื้อและกักความชื้น'),
    InciItem(name: 'Stearyl Alcohol', category: 'Fatty Alcohol / Emulsifier', descriptionTh: 'แอลกอฮอล์ไขมัน ช่วยผสานเนื้อครีมและให้ความนุ่มผิว'),
    InciItem(name: 'Behenyl Alcohol', category: 'Fatty Alcohol / Emulsifier', descriptionTh: 'แอลกอฮอล์ไขมันธรรมชาติ เพิ่มความเข้มข้นให้เนื้อสัมผัส'),
    InciItem(name: 'Caprylic/Capric Triglyceride', category: 'Emollient', descriptionTh: 'น้ำมันสกัดจากมะพร้าว บางเบา ไม่อุดตันรูขุมขน'),
    InciItem(name: 'C12-15 Alkyl Benzoate', category: 'Emollient', descriptionTh: 'สารบำรุงผิวนุ่มลื่น บางเบา ไม่เหนอะหนะ'),
    InciItem(name: 'Cetyl Ethylhexanoate', category: 'Emollient', descriptionTh: 'เอสเทอร์บำรุงผิว ให้สัมผัสเนียนลื่นเบาสบาย'),
    InciItem(name: 'Isopropyl Myristate', category: 'Emollient', descriptionTh: 'สารช่วยเพิ่มการดูดซึมและให้ความนุ่มลื่น'),
    InciItem(name: 'Glyceryl Stearate', category: 'Emulsifier / Emollient', descriptionTh: 'สารผสานน้ำกับน้ำมันธรรมชาติ ให้ความชุ่มชื้น'),
    InciItem(name: 'PEG-100 Stearate', category: 'Emulsifier', descriptionTh: 'สารช่วยผสานเนื้อครีมให้เข้ากันอย่างเนียนละเอียด'),
    InciItem(name: 'PEG-40 Stearate', category: 'Emulsifier / Surfactant', descriptionTh: 'สารช่วยทำความสะอาดและผสานเนื้อผลิตภัณฑ์'),
    InciItem(name: 'Polysorbate 20', category: 'Emulsifier / Solubilizer', descriptionTh: 'สารช่วยละลายน้ำหอมและสารสกัดในน้ำ'),
    InciItem(name: 'Polysorbate 60', category: 'Emulsifier', descriptionTh: 'สารผสานเนื้อครีมและโลชั่น'),
    InciItem(name: 'Polysorbate 80', category: 'Emulsifier', descriptionTh: 'สารผสานน้ำมันในน้ำอย่างเสถียร'),
    InciItem(name: 'Cetearyl Glucoside', category: 'Emulsifier', descriptionTh: 'สารผสานเนื้อครีมธรรมชาติจากน้ำตาลและข้าวโพด'),
    InciItem(name: 'Sorbitan Olivate', category: 'Emulsifier', descriptionTh: 'สารผสานเนื้อจากน้ำมันมะกอก อ่อนโยนต่อผิว'),
    InciItem(name: 'Cetearyl Olivate', category: 'Emulsifier', descriptionTh: 'สารผสานจากน้ำมันมะกอก เสริมความแข็งแรงเกราะผิว'),
    InciItem(name: 'Behentrimonium Methosulfate', category: 'Conditioning / Emulsifier', descriptionTh: 'สารปรับผิวนุ่มลื่น อ่อนโยน ไม่ระคายเคือง'),
    InciItem(name: 'Sodium Lauroyl Lactylate', category: 'Emulsifier / Surfactant', descriptionTh: 'สารผสานช่วยเสริมการทำงานของเซราไมด์ในชั้นผิว'),
    InciItem(name: 'Ceteareth-20', category: 'Emulsifier', descriptionTh: 'สารช่วยผสานเนื้ออิมัลชัน'),

    // Surfactants & Cleansing Agents
    InciItem(name: 'Cocamidopropyl Betaine', category: 'Surfactant (Amphoteric)', descriptionTh: 'สารทำความสะอาดจากมะพร้าว ฟองนุ่ม อ่อนโยน'),
    InciItem(name: 'Sodium Cocoyl Isethionate', category: 'Surfactant (Anionic)', descriptionTh: 'สารทำความสะอาดสูตรอ่อนโยนพิเศษจากมะพร้าว'),
    InciItem(name: 'Sodium Lauroyl Sarcosinate', category: 'Surfactant', descriptionTh: 'สารทำความสะอาดอ่อนโยน ไม่ทำลายเกราะผิว'),
    InciItem(name: 'Coco-Glucoside', category: 'Surfactant (Non-ionic)', descriptionTh: 'สารทำความสะอาดธรรมชาติจากมะพร้าวและน้ำตาล'),
    InciItem(name: 'Decyl Glucoside', category: 'Surfactant (Non-ionic)', descriptionTh: 'สารทำความสะอาดจากพืช อ่อนโยนสำหรับผิวบอบบาง'),
    InciItem(name: 'Lauryl Glucoside', category: 'Surfactant (Non-ionic)', descriptionTh: 'สารทำความสะอาดจากพืช ย่อยสลายได้ตามธรรมชาติ'),
    InciItem(name: 'Sodium Methyl Cocoyl Taurate', category: 'Surfactant', descriptionTh: 'สารทำความสะอาดฟองละเอียด อ่อนโยน ไม่แห้งตึง'),
    InciItem(name: 'Disodium Laureth Sulfosuccinate', category: 'Surfactant', descriptionTh: 'สารทำความสะอาดอ่อนโยน ปราศจากซัลเฟตระคายเคือง'),

    // Thickeners & Polymers
    InciItem(name: 'Carbomer', category: 'Viscosity Control / Polymer', descriptionTh: 'สารเพิ่มความหนืดและขึ้นเนื้อเจลใส'),
    InciItem(name: 'Xanthan Gum', category: 'Viscosity Control / Natural', descriptionTh: 'สารเพิ่มความหนืดธรรมชาติจากกระบวนการหมัก'),
    InciItem(name: 'Acrylates/C10-30 Alkyl Acrylate Crosspolymer', category: 'Viscosity Control', descriptionTh: 'โพลีเมอร์ช่วยสร้างเนื้อเจลและกักเก็บน้ำมัน'),
    InciItem(name: 'Hydroxyethylcellulose', category: 'Viscosity Control', descriptionTh: 'สารเพิ่มความหนืดจากเซลลูโลสพืช'),
    InciItem(name: 'Ammonium Acryloyldimethyltaurate/VP Copolymer', category: 'Viscosity Control', descriptionTh: 'โพลีเมอร์สร้างเนื้อสัมผัสบางเบา เกลี่ยง่าย'),
    InciItem(name: 'Polyacrylate Crosspolymer-6', category: 'Viscosity Control', descriptionTh: 'สารสร้างเนื้อเจลครีมสัมผัสนุ่มละมุน'),

    // Silicones
    InciItem(name: 'Dimethicone', category: 'Emollient / Silicone', descriptionTh: 'ซิลิโคนปลอดภัย ช่วยเคลือบกักความชื้นและให้ผิวเนียนลื่น'),
    InciItem(name: 'Cyclopentasiloxane', category: 'Silicone', descriptionTh: 'ซิลิโคนระเหยไว ให้สัมผัสบางเบา ไม่เหนียวเหนอะ'),
    InciItem(name: 'Cyclohexasiloxane', category: 'Silicone', descriptionTh: 'ซิลิโคนเพิ่มความนุ่มลื่นและกระจายตัว'),
    InciItem(name: 'Dimethiconol', category: 'Silicone', descriptionTh: 'ซิลิโคนช่วยเคลือบปกป้องผิวและเส้นผม'),
    InciItem(name: 'Phenyl Trimethicone', category: 'Silicone', descriptionTh: 'ซิลิโคนช่วยเพิ่มความเงางามและนุ่มลื่น'),

    // Preservatives, Buffers & Chelators
    InciItem(name: 'Phenoxyethanol', category: 'Preservative', descriptionTh: 'สารกันเสียมาตรฐานความปลอดภัยสูง อ่อนโยน'),
    InciItem(name: 'Ethylhexylglycerin', category: 'Preservative Booster / Humectant', descriptionTh: 'สารเสริมฤทธิ์กันเสียและบำรุงผิวนุ่มชุ่มชื้น'),
    InciItem(name: 'Sodium Benzoate', category: 'Preservative', descriptionTh: 'สารกันเสียเกรดอาหาร ปลอดภัยต่อผิว'),
    InciItem(name: 'Potassium Sorbate', category: 'Preservative', descriptionTh: 'สารกันเสียธรรมชาติ ป้องกันเชื้อราและยีสต์'),
    InciItem(name: '1,2-Hexanediol', category: 'Preservative Booster / Solvent', descriptionTh: 'สารยับยั้งเชื้อและเพิ่มความชุ่มชื้น'),
    InciItem(name: 'Caprylyl Glycol', category: 'Preservative Booster / Emollient', descriptionTh: 'สารเสริมการกันเสียและให้ความชุ่มชื้น'),
    InciItem(name: 'Disodium EDTA', category: 'Chelating Agent', descriptionTh: 'สารจับประจุโลหะ ช่วยรักษาความเสถียรของสูตร'),
    InciItem(name: 'Tetrasodium EDTA', category: 'Chelating Agent', descriptionTh: 'สารจับประจุโลหะ เพิ่มประสิทธิภาพการทำความสะอาด'),
    InciItem(name: 'Citric Acid', category: 'pH Adjuster / AHA', descriptionTh: 'กรดซิตริกธรรมชาติ ช่วยปรับสมดุลค่า pH ให้เหมาะกับผิว'),
    InciItem(name: 'Sodium Citrate', category: 'Buffering Agent', descriptionTh: 'เกลือโซเดียมซิเตรต ควบคุมค่า pH ให้คงที่'),
    InciItem(name: 'Sodium Hydroxide', category: 'pH Adjuster', descriptionTh: 'สารปรับค่าความเป็นกรด-ด่าง'),
    InciItem(name: 'Potassium Phosphate', category: 'Buffering Agent', descriptionTh: 'สารควบคุมสมดุลกรด-ด่างในผลิตภัณฑ์'),
    InciItem(name: 'Dipotassium Phosphate', category: 'Buffering Agent', descriptionTh: 'สารควบคุมและรักษาเสถียรภาพค่า pH'),

    // Sunscreens / UV Filters
    InciItem(name: 'Zinc Oxide', category: 'Physical UV Filter', descriptionTh: 'ซิงค์ออกไซด์ กันแดดสะท้อนรังสี UVA/UVB อ่อนโยนพิเศษ'),
    InciItem(name: 'Titanium Dioxide', category: 'Physical UV Filter', descriptionTh: 'ไททาเนียมไดออกไซด์ กันแดดสะท้อนรังสี UVB/UVA'),
    InciItem(name: 'Ethylhexyl Methoxycinnamate', category: 'Chemical UV Filter', descriptionTh: 'สารกันแดดดูดซับรังสี UVB ประสิทธิภาพสูง'),
    InciItem(name: 'Ethylhexyl Salicylate', category: 'Chemical UV Filter', descriptionTh: 'สารดูดซับรังสี UVB และช่วยให้สารกันแดดอื่นเสถียร'),
    InciItem(name: 'Homosalate', category: 'Chemical UV Filter', descriptionTh: 'สารกรองรังสี UVB'),
    InciItem(name: 'Avobenzone', category: 'Chemical UV Filter', descriptionTh: 'สารกันแดดดูดซับรังสี UVA ได้อย่างครอบคลุม'),
    InciItem(name: 'Octocrylene', category: 'Chemical UV Filter', descriptionTh: 'สารกันแดดดูดซับรังสี UVB และช่วยให้ Avobenzone เสถียร'),
    InciItem(name: 'Bis-Ethylhexyloxyphenol Methoxyphenyl Triazine', category: 'Chemical UV Filter (Tinosorb S)', descriptionTh: 'สารกันแดดรุ่นใหม่ ป้องกันทั้ง UVA และ UVB เสถียรสูงมาก'),
    InciItem(name: 'Methylene Bis-Benzotriazolyl Tetramethylbutylphenol', category: 'Hybrid UV Filter (Tinosorb M)', descriptionTh: 'สารกันแดดไฮบริด ดูดซับและสะท้อนรังสีได้ในตัวเดียว'),
    InciItem(name: 'Diethylamino Hydroxybenzoyl Hexyl Benzoate', category: 'Chemical UV Filter (Uvinul A Plus)', descriptionTh: 'สารกันแดด UVA เสถียรสูง ไม่เสื่อมสลายง่าย'),
    InciItem(name: 'Ethylhexyl Triazone', category: 'Chemical UV Filter (Uvinul T 150)', descriptionTh: 'สารกันแดด UVB ประสิทธิภาพการดูดซับสูงสุด'),

    // Botanicals & Extracts
    InciItem(name: 'Centella Asiatica Extract', category: 'Botanical Extract', descriptionTh: 'สารสกัดใบบัวบก ปลอบประโลมผิว ลดการอักเสบและรอยสิว'),
    InciItem(name: 'Madecassoside', category: 'Active Botanical', descriptionTh: 'สารบริสุทธิ์จากใบบัวบก สมานแผลและลดการระคายเคือง'),
    InciItem(name: 'Asiaticoside', category: 'Active Botanical', descriptionTh: 'สารสกัดใบบัวบก ช่วยกระตุ้นการสร้างคอลลาเจน'),
    InciItem(name: 'Aloe Barbadensis Leaf Juice', category: 'Botanical Extract', descriptionTh: 'น้ำว่านหางจระเข้ เติมความชุ่มชื้นและลดอาการแสบแดง'),
    InciItem(name: 'Aloe Barbadensis Leaf Extract', category: 'Botanical Extract', descriptionTh: 'สารสกัดว่านหางจระเข้ บำรุงผิวให้เนียนนุ่ม'),
    InciItem(name: 'Camellia Sinensis Leaf Extract', category: 'Botanical / Antioxidant', descriptionTh: 'สารสกัดชาเขียว ต้านอนุมูลอิสระและคุมความมัน'),
    InciItem(name: 'Chamomilla Recutita (Matricaria) Flower Extract', category: 'Botanical Extract', descriptionTh: 'สารสกัดดอกคาโมมายล์ ลดการแพ้และระคายเคือง'),
    InciItem(name: 'Glycyrrhiza Glabra (Licorice) Root Extract', category: 'Botanical Extract', descriptionTh: 'สารสกัดชะเอมเทศ ลดรอยดำและต้านการอักเสบ'),
    InciItem(name: 'Melaleuca Alternifolia (Tea Tree) Leaf Oil', category: 'Essential Oil / Active', descriptionTh: 'น้ำมันทีทรี ยับยั้งเชื้อแบคทีเรียสาเหตุของสิว'),
    InciItem(name: 'Calendula Officinalis Flower Extract', category: 'Botanical Extract', descriptionTh: 'สารสกัดดอกดาวเรือง สมานผิวและฟื้นฟูผิวแห้งกร้าน'),
    InciItem(name: 'Houttuynia Cordata Extract', category: 'Botanical Extract', descriptionTh: 'สารสกัดพลูคาว ต้านการอักเสบและกระชับรูขุมขน'),
    InciItem(name: 'Salix Alba (Willow) Bark Extract', category: 'Botanical Extract', descriptionTh: 'สารสกัดเปลือกวิลโลว์ แหล่งกรดซาลิไซลิกธรรมชาติ'),
    InciItem(name: 'Artemisia Princeps Leaf Extract', category: 'Botanical Extract', descriptionTh: 'สารสกัดจิงจูฉ่าย/มักวอร์ต ปลอบประโลมผิวแพ้ง่าย'),
    InciItem(name: 'Avena Sativa (Oat) Kernel Extract', category: 'Botanical Extract', descriptionTh: 'สารสกัดข้าวโอ๊ต ลดอาการคันและเสริมเกราะผิว'),
    InciItem(name: 'Propolis Extract', category: 'Natural Active', descriptionTh: 'สารสกัดพรอพอลิส ฆ่าเชื้อแบคทีเรียและฟื้นฟูผิว'),
    InciItem(name: 'Snail Secretion Filtrate', category: 'Natural Active', descriptionTh: 'เมือกหอยทาก ซ่อมแซมเซลล์ผิวและเพิ่มความยืดหยุ่น'),
    InciItem(name: 'Galactomyces Ferment Filtrate', category: 'Ferment Active', descriptionTh: 'พิเทร่า/กาแลคโตมัยเซส ปรับผิวเรียบเนียนกระจ่างใส'),
    InciItem(name: 'Bifida Ferment Lysate', category: 'Probiotic / Active', descriptionTh: 'สารหมักบิฟิดา ฟื้นฟูเกราะป้องกันผิวและต้านริ้วรอย'),

    // Plant Oils & Butters
    InciItem(name: 'Simmondsia Chinensis (Jojoba) Seed Oil', category: 'Plant Oil', descriptionTh: 'น้ำมันโจโจ้บา โครงสร้างใกล้เคียงน้ำมันผิว ไม่อุดตัน'),
    InciItem(name: 'Helianthus Annuus (Sunflower) Seed Oil', category: 'Plant Oil', descriptionTh: 'น้ำมันเมล็ดทานตะวัน อุดมด้วยวิตามินอีและกรดไขมันจำเป็น'),
    InciItem(name: 'Argania Spinosa Kernel Oil', category: 'Plant Oil', descriptionTh: 'น้ำมันอาร์แกน บำรุงผิวล้ำลึกและชะลอริ้วรอย'),
    InciItem(name: 'Rosa Canina Fruit Oil', category: 'Plant Oil', descriptionTh: 'น้ำมันโรสฮิป อุดมด้วยวิตามินเอและซี ลดรอยแผลเป็น'),
    InciItem(name: 'Butyrospermum Parkii (Shea) Butter', category: 'Plant Butter', descriptionTh: 'เชียบัตเตอร์ บำรุงผิวแห้งแตกให้เนียนนุ่มชุ่มชื้น'),
  ];

  static final Map<String, InciItem> _nameIndex = {
    for (final item in items) item.name.toLowerCase().trim(): item,
  };

  /// Check if an ingredient name matches our standard INCI dictionary
  static bool contains(String name) {
    final clean = _normalize(name);
    if (_nameIndex.containsKey(clean)) return true;

    // Check alias variations (e.g. without punctuation / brackets)
    final simplified = clean.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (simplified.isEmpty) return false;
    for (final key in _nameIndex.keys) {
      if (key.replaceAll(RegExp(r'[^a-z0-9]'), '') == simplified) {
        return true;
      }
    }
    return false;
  }

  /// Get InciItem details by name
  static InciItem? find(String name) {
    final clean = _normalize(name);
    if (_nameIndex.containsKey(clean)) return _nameIndex[clean];

    final simplified = clean.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (simplified.isEmpty) return null;
    for (final entry in _nameIndex.entries) {
      if (entry.key.replaceAll(RegExp(r'[^a-z0-9]'), '') == simplified) {
        return entry.value;
      }
    }
    return null;
  }

  /// Search local ingredients by query (for instant autocomplete)
  static List<String> search(String query, {int limit = 5}) {
    if (query.trim().isEmpty) return [];
    final cleanQuery = query.toLowerCase().trim();
    final results = <String>[];

    for (final item in items) {
      if (item.name.toLowerCase().contains(cleanQuery) ||
          item.descriptionTh.toLowerCase().contains(cleanQuery)) {
        results.add(item.name);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  static String _normalize(String input) {
    return input.toLowerCase().trim();
  }
}
