-- setup_supabase_storage.sql
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard/project/zwiyldrmakwoggyvfxsp/sql)

-- 1. Enable Storage extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create the academic_documents storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'academic_documents',
    'academic_documents',
    true,
    52428800, -- 50 MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'text/plain']
)
ON CONFLICT (id) DO UPDATE SET 
    public = true,
    file_size_limit = 52428800;

-- 3. Storage Policies: Allow full read and upload access
DROP POLICY IF EXISTS "Public Academic Documents Access" ON storage.objects;
CREATE POLICY "Public Academic Documents Access"
ON storage.objects FOR ALL
USING (bucket_id = 'academic_documents')
WITH CHECK (bucket_id = 'academic_documents');

-- 4. Ensure academic_documents and document_chunks tables have RLS enabled with permissive policies
ALTER TABLE IF EXISTS academic_documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS document_chunks DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS academic_results DISABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA storage TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO anon, authenticated;
