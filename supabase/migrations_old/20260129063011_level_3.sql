-- Drop all existing tables in the public schema
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    ) LOOP
        EXECUTE format('DROP TABLE IF EXISTS public.%I CASCADE', r.tablename);
    END LOOP;
END $$;

-- Create new tables with foreign key relationship
CREATE TABLE public.bravo (
    id uuid DEFAULT gen_random_uuid () PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users (id) DEFAULT auth.uid (),
    bravo_1 VARCHAR(100) NOT NULL,
    bravo_2 VARCHAR(100)
);

-- Create table alfa with a foreign key referencing bravo
CREATE TABLE public.alfa (
    id uuid DEFAULT gen_random_uuid () PRIMARY KEY,
    alfa_1 VARCHAR(100) NOT NULL,
    alfa_2 VARCHAR(100),
    bravo_id uuid NOT NULL,
    CONSTRAINT fk_bravo FOREIGN KEY (bravo_id) REFERENCES public.bravo (id) ON DELETE CASCADE
);

-- Enable Row Level Security and create policies
ALTER TABLE public.bravo ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.alfa ENABLE ROW LEVEL SECURITY;

-- Policies for bravo table
CREATE POLICY "Allow read access to all users" ON public.bravo FOR
SELECT TO public USING (true);

CREATE POLICY "Allow insert access to authenticated users" ON public.bravo FOR INSERT TO authenticated
WITH
    CHECK (auth.uid () = user_id);

CREATE POLICY "Allow update and delete access to owner only" ON public.bravo FOR ALL TO authenticated USING (auth.uid () = user_id);

-- Policies for alfa table
CREATE POLICY "Allow read access to all users" ON public.alfa FOR
SELECT TO public USING (true);

CREATE POLICY "Allow owner to manage Alfa" ON public.alfa FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1
        FROM public.bravo
        WHERE
            bravo.id = alfa.bravo_id
            AND bravo.user_id = auth.uid ()
    )
);