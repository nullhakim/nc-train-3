-- Menghapus semua tabel yang ada di skema 'public'
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

-- Membuat tabel 'alfa' dengan kolom yang ditentukan
CREATE TABLE public.alfa (
    id uuid DEFAULT gen_random_uuid () PRIMARY KEY,
    alfa_1 VARCHAR(100) NOT NULL,
    alfa_2 VARCHAR(100)
);