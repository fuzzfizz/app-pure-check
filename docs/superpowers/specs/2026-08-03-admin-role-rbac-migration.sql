-- Add role column to profiles table if not exists
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS role text DEFAULT 'user' CHECK (role IN ('user', 'admin'));

-- Index role for performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- Example SQL to set a specific user as admin (replace with target user ID):
-- UPDATE public.profiles SET role = 'admin' WHERE id = 'YOUR_USER_ID';
