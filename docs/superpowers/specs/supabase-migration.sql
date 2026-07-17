-- profiles (1:1 with auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  skin_type text CHECK (skin_type IN ('oily','dry','combination','normal','sensitive')),
  skin_conditions text[] DEFAULT '{}',
  skin_concerns text[] DEFAULT '{}',
  avoid_preferences text[] DEFAULT '{}',
  onboarding_complete boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access own profile" ON public.profiles
  FOR ALL USING (auth.uid() = id);

-- user_allergens (1:many)
CREATE TABLE IF NOT EXISTS public.user_allergens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles ON DELETE CASCADE,
  ingredient_name text NOT NULL,
  reaction_symptoms text[] DEFAULT '{}',
  severity text CHECK (severity IN ('mild','moderate','severe')) DEFAULT 'mild',
  source text CHECK (source IN ('known','suspected')) DEFAULT 'known',
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on user_allergens
ALTER TABLE public.user_allergens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access own allergens" ON public.user_allergens
  FOR ALL USING (auth.uid() = user_id);

-- products (shared, community-built)
CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode text UNIQUE,
  name text NOT NULL,
  brand text,
  ingredients text[] DEFAULT '{}',
  raw_ingredients_text text,
  source text CHECK (source IN ('local','open_beauty_facts','user_entered')) DEFAULT 'local',
  verified_count int DEFAULT 0,
  image_url text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on products
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read products" ON public.products FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert products" ON public.products FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- scan_history (per user)
CREATE TABLE IF NOT EXISTS public.scan_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles ON DELETE CASCADE,
  product_id uuid REFERENCES public.products,
  safety_level text CHECK (safety_level IN ('safe','caution','danger')),
  ai_analysis jsonb,
  scanned_at timestamptz DEFAULT now()
);

-- Enable RLS on scan_history
ALTER TABLE public.scan_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access own history" ON public.scan_history
  FOR ALL USING (auth.uid() = user_id);
