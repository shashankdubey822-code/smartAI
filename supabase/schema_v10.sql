-- ============================================================
-- AI ChatBot v10 — INSTITUTIONAL EMS SCHEMA
-- Mentor-Only Document Ingestion, Scoped Academic Vault & RLS
-- ============================================================

-- 1. Create academic_documents table (Replaces/Evolves student_documents)
CREATE TABLE IF NOT EXISTS academic_documents (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  uploaded_by     UUID REFERENCES users(id) ON DELETE SET NULL,
  doc_type        TEXT NOT NULL CHECK (doc_type IN (
                    'academic_calendar', 'timetable', 'syllabus', 
                    'marksheet', 'notes', 'notice', 'other'
                  )),
  title           TEXT NOT NULL,
  file_name       TEXT NOT NULL,
  mime_type       TEXT NOT NULL,
  file_size       INTEGER,
  storage_path    TEXT,
  content_base64  TEXT,
  extracted_text  TEXT,
  
  -- Hierarchical Scoping & Filtering
  target_scope    TEXT NOT NULL DEFAULT 'class' CHECK (target_scope IN ('class', 'individual')),
  target_roll_no  TEXT REFERENCES users(roll_number) ON DELETE CASCADE,
  program         TEXT, -- e.g. 'B.Tech'
  branch          TEXT, -- e.g. 'Computer Science and Engineering'
  semester        TEXT, -- e.g. '4', '5'
  academic_year   TEXT NOT NULL DEFAULT '2025-2026',
  subject_code    TEXT,
  unit            TEXT,
  
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Ensure existing student_documents data can migrate cleanly if table exists
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'student_documents') THEN
    INSERT INTO academic_documents (
      id, uploaded_by, doc_type, title, file_name, mime_type, file_size, 
      storage_path, content_base64, extracted_text, created_at, updated_at,
      target_scope, academic_year
    )
    SELECT 
      id, student_id, doc_type, title, file_name, mime_type, file_size,
      storage_path, content_base64, extracted_text, created_at, updated_at,
      'class', '2025-2026'
    FROM student_documents
    ON CONFLICT (id) DO NOTHING;
  END IF;
END $$;

-- 3. Document chunks table linked to academic_documents
CREATE TABLE IF NOT EXISTS document_chunks (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id  UUID REFERENCES academic_documents(id) ON DELETE CASCADE,
  chunk_text   TEXT NOT NULL,
  chunk_index  INTEGER DEFAULT 0,
  embedding    vector(768),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 4. High performance indexes for Autonomous AI Agent lookups
CREATE INDEX IF NOT EXISTS idx_acad_docs_mentor   ON academic_documents(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_acad_docs_scope    ON academic_documents(target_scope);
CREATE INDEX IF NOT EXISTS idx_acad_docs_roll     ON academic_documents(target_roll_no);
CREATE INDEX IF NOT EXISTS idx_acad_docs_type_yr  ON academic_documents(doc_type, academic_year);
CREATE INDEX IF NOT EXISTS idx_acad_docs_branch   ON academic_documents(program, branch, semester);

-- 5. Autonomous RAG Similarity & Keyword Match Function (RPC)
CREATE OR REPLACE FUNCTION match_academic_chunks(
  query_embedding  vector(768),
  filter_doc_type  TEXT DEFAULT NULL,
  filter_roll_no   TEXT DEFAULT NULL,
  filter_year      TEXT DEFAULT NULL,
  match_count      INT  DEFAULT 5,
  min_similarity   FLOAT DEFAULT 0.4
)
RETURNS TABLE (
  id UUID, 
  document_id UUID, 
  chunk_text TEXT, 
  similarity FLOAT, 
  doc_type TEXT, 
  doc_title TEXT, 
  academic_year TEXT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    dc.id,
    dc.document_id,
    dc.chunk_text,
    (1 - (dc.embedding <=> query_embedding))::FLOAT AS similarity,
    ad.doc_type,
    ad.title AS doc_title,
    ad.academic_year
  FROM document_chunks dc
  JOIN academic_documents ad ON ad.id = dc.document_id
  WHERE 
    (filter_doc_type IS NULL OR ad.doc_type = filter_doc_type)
    AND (filter_year IS NULL OR ad.academic_year = filter_year)
    AND (
      ad.target_scope = 'class' 
      OR (ad.target_scope = 'individual' AND ad.target_roll_no = filter_roll_no)
    )
    AND (1 - (dc.embedding <=> query_embedding)) >= min_similarity
  ORDER BY dc.embedding <=> query_embedding 
  LIMIT match_count;
END;
$$;

-- 6. Permissions & RLS Configuration
-- Since Acadly manages custom session authentication in users table,
-- disable PostgreSQL RLS or configure permissive policies for anon/authenticated
ALTER TABLE academic_documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE document_chunks    DISABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated;

SELECT '✅ v10 Production Academic Vault Schema Ready!' AS status;
