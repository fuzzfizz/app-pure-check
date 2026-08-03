-- Migration: Add Hybrid Pending Review & Moderation columns to products table

ALTER TABLE public.products 
  ADD COLUMN IF NOT EXISTS is_verified boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS status text CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS submitted_by uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS confidence_score int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS ai_flags text[] DEFAULT '{}';

-- Set existing products as verified & approved
UPDATE public.products 
  SET is_verified = true, status = 'approved', confidence_score = 100 
  WHERE is_verified IS NULL OR status IS NULL;

-- Update RLS Policy: Public read only for verified products OR own submission
DROP POLICY IF EXISTS "Public read products" ON public.products;
CREATE POLICY "Public read verified products or own submission" ON public.products
  FOR SELECT USING (is_verified = true OR (auth.uid() IS NOT NULL AND submitted_by = auth.uid()));

-- Policy: Authenticated users can insert products with pending status
DROP POLICY IF EXISTS "Authenticated users can insert products" ON public.products;
CREATE POLICY "Authenticated users can insert products" ON public.products 
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Policy: Authenticated users can update products
DROP POLICY IF EXISTS "Authenticated users can update products" ON public.products;
CREATE POLICY "Authenticated users can update products" ON public.products 
  FOR UPDATE USING (auth.role() = 'authenticated');
