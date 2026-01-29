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

-- Tabel Bravo: Tabel utama milik user
CREATE TABLE public.bravo (
    id uuid DEFAULT gen_random_uuid () PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users (id) DEFAULT auth.uid (),
    bravo_1 VARCHAR(100) NOT NULL,
    bravo_2 VARCHAR(100)
);

-- Tabel Alfa: Tabel anak yang menyimpan referensi gambar
CREATE TABLE public.alfa (
    id uuid DEFAULT gen_random_uuid () PRIMARY KEY,
    alfa_1 VARCHAR(100) NOT NULL,
    alfa_2 VARCHAR(100),
    bravo_id uuid NOT NULL,
    image_url TEXT, -- Menyimpan nama file (misal: "foto.png")
    CONSTRAINT fk_bravo FOREIGN KEY (bravo_id) REFERENCES public.bravo (id) ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE public.bravo ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.alfa ENABLE ROW LEVEL SECURITY;

-- Bravo Policies
CREATE POLICY "Allow read access to all users" ON public.bravo FOR
SELECT TO public USING (true);

CREATE POLICY "Allow insert access to authenticated users" ON public.bravo FOR INSERT TO authenticated
WITH
    CHECK (auth.uid () = user_id);

CREATE POLICY "Allow update and delete access to owner only" ON public.bravo FOR ALL TO authenticated USING (auth.uid () = user_id);

-- Alfa Policies
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

-- Publik bisa melihat gambar
CREATE POLICY "Allow public read access to alfa_assets" ON storage.objects FOR
SELECT TO public USING (bucket_id = 'alfa_assets');

-- User terautentikasi bisa upload
CREATE POLICY "Allow authenticated users to upload to alfa_assets" ON storage.objects FOR INSERT TO authenticated
WITH
    CHECK (bucket_id = 'alfa_assets');

-- User terautentikasi bisa update (upsert)
CREATE POLICY "Allow authenticated users to update alfa_assets" ON storage.objects
FOR UPDATE
    TO authenticated USING (bucket_id = 'alfa_assets');

-- Service Role (Admin/Edge Function) bypass aturan
CREATE POLICY "Service Role Bypass" ON storage.objects FOR ALL TO service_role USING (bucket_id = 'alfa_assets');

-- Policy Delete: Hanya pemilik data alfa yang bisa hapus file terkait
CREATE POLICY "Allow users to delete their own alfa_assets" ON storage.objects FOR DELETE TO authenticated USING (
    bucket_id = 'alfa_assets'
    AND EXISTS (
        SELECT 1
        FROM public.alfa a
            JOIN public.bravo b ON a.bravo_id = b.id
        WHERE
            b.user_id = auth.uid ()
            AND a.image_url = storage.objects.name -- Perbandingan '=' jauh lebih cepat dari 'LIKE'
    )
);

-- Menambahkan tabel ke publication Realtime Supabase
ALTER PUBLICATION supabase_realtime
ADD TABLE public.bravo,
public.alfa;