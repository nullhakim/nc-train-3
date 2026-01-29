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
    bravo_1 VARCHAR(100) NOT NULL,
    bravo_2 VARCHAR(100)
);

-- Create table alfa with a foreign key referencing bravo
CREATE TABLE public.alfa (
    id uuid DEFAULT gen_random_uuid () PRIMARY KEY,
    alfa_1 VARCHAR(100) NOT NULL,
    alfa_2 VARCHAR(100),
    bravo_id uuid,
    CONSTRAINT fk_bravo FOREIGN KEY (bravo_id) REFERENCES public.bravo (id) ON DELETE SET NULL
);