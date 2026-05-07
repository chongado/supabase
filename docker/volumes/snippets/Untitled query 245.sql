-- 1. Drop ALL Row Level Security (RLS) policies to clear dependencies
DO $$ 
DECLARE 
    pol record;
BEGIN 
    FOR pol IN (SELECT policyname, tablename, schemaname FROM pg_policies WHERE schemaname = 'public') 
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
    END LOOP;
END $$;

-- 2. Remove foreign key constraints that depend on auth.users(id)
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE public.subscriptions DROP CONSTRAINT IF EXISTS subscriptions_user_id_fkey;
ALTER TABLE public.generations DROP CONSTRAINT IF EXISTS generations_user_id_fkey;

-- 3. Change column types to TEXT
ALTER TABLE public.profiles ALTER COLUMN id TYPE TEXT;
ALTER TABLE public.subscriptions ALTER COLUMN user_id TYPE TEXT;
ALTER TABLE public.generations ALTER COLUMN user_id TYPE TEXT;

-- 4. Update initial credits for new users
ALTER TABLE public.subscriptions ALTER COLUMN credits_remaining SET DEFAULT 1000;
ALTER TABLE public.subscriptions ALTER COLUMN credits_monthly SET DEFAULT 1000;

-- 5. Re-enable RLS and create new permissive policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.generations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all for profiles" ON public.profiles FOR ALL USING (true);
CREATE POLICY "Allow all for subscriptions" ON public.subscriptions FOR ALL USING (true);
CREATE POLICY "Allow all for generations" ON public.generations FOR ALL USING (true);

-- 6. Cleanup triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
