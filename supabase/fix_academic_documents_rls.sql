-- Run this snippet in Supabase SQL Editor:
ALTER TABLE IF EXISTS academic_documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS document_chunks DISABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated;
