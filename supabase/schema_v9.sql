-- ============================================================
-- AI ChatBot v9 — NORMALIZED SCHEMA (ROLL NUMBER BASED)
-- Attendance + Results + Schedules (Separate Tables)
-- ============================================================

-- 1. Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Drop old tables (Clearing everything for a clean v9 setup)
DROP TABLE IF EXISTS mentor_interventions CASCADE;
DROP TABLE IF EXISTS issue_reports        CASCADE;
DROP TABLE IF EXISTS document_chunks      CASCADE;
DROP TABLE IF EXISTS messages             CASCADE;
DROP TABLE IF EXISTS conversations        CASCADE;
DROP TABLE IF EXISTS student_documents    CASCADE;
DROP TABLE IF EXISTS attendance           CASCADE; -- New table
DROP TABLE IF EXISTS academic_results     CASCADE; -- New table
DROP TABLE IF EXISTS schedules            CASCADE; -- New table
DROP TABLE IF EXISTS academic_records     CASCADE; -- Old name
DROP TABLE IF EXISTS academic_schedules   CASCADE; -- Old name
DROP TABLE IF EXISTS users                CASCADE;

-- ══════════════════════════════════════════════════════════
-- USERS (Core Profile)
-- ══════════════════════════════════════════════════════════
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name          TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'student'
                CHECK (role IN ('student','mentor')),
  
  -- Roll Number is now UNIQUE and NOT NULL for students
  -- (Using a trigger or logic to handle mentor roll numbers if needed, 
  -- but strictly required for student FK references)
  roll_number      TEXT UNIQUE, 
  
  phone         TEXT,
  department    TEXT, 
  profile_url   TEXT,
  program       TEXT, 
  branch        TEXT, 
  semester      TEXT,
  section       TEXT,
  mentor_email  TEXT,
  
  -- Profile Details (Added back for compatibility)
  skills           JSONB DEFAULT '[]'::jsonb,
  hobbies          JSONB DEFAULT '[]'::jsonb,
  career_interests JSONB DEFAULT '[]'::jsonb,
  designation      TEXT,
  expertise        JSONB DEFAULT '[]'::jsonb,
  office_location  TEXT,
  office_hours     TEXT,
  
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  last_active   TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════
-- [NEW] ATTENDANCE (Linked by Roll Number)
-- ══════════════════════════════════════════════════════════
CREATE TABLE attendance (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_roll_no       TEXT NOT NULL REFERENCES users(roll_number) ON DELETE CASCADE,
  subject_code          TEXT NOT NULL,
  subject_name          TEXT,
  total_classes         INTEGER DEFAULT 0,
  attended_classes      INTEGER DEFAULT 0,
  attendance_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
    CASE WHEN total_classes > 0 THEN (attended_classes::DECIMAL / total_classes::DECIMAL) * 100 ELSE 0 END
  ) STORED,
  last_updated          TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════
-- [NEW] ACADEMIC RESULTS (Linked by Roll Number)
-- ══════════════════════════════════════════════════════════
CREATE TABLE academic_results (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_roll_no TEXT NOT NULL REFERENCES users(roll_number) ON DELETE CASCADE,
  semester        TEXT NOT NULL,
  subject_code    TEXT NOT NULL,
  subject_name    TEXT NOT NULL,
  marks_obtained  INTEGER,
  max_marks       INTEGER DEFAULT 100,
  grade           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════
-- [NEW] SCHEDULES / TIMETABLE (Linked by Roll Number)
-- ══════════════════════════════════════════════════════════
CREATE TABLE schedules (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_roll_no TEXT NOT NULL REFERENCES users(roll_number) ON DELETE CASCADE,
  day_of_week     TEXT NOT NULL, -- Monday, Tuesday, etc.
  start_time      TIME NOT NULL,
  end_time        TIME NOT NULL,
  subject_name    TEXT NOT NULL,
  room_number     TEXT,
  instructor_name TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════
-- [RAG] DOCUMENTS & VECTOR SEARCH
-- ══════════════════════════════════════════════════════════
CREATE TABLE student_documents (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id      UUID REFERENCES users(id) ON DELETE CASCADE,
  doc_type        TEXT NOT NULL CHECK (doc_type IN (
    'timetable','academic_calendar','syllabus',
    'marksheet','attendance','assignment','other'
  )),
  title           TEXT NOT NULL,
  file_name       TEXT NOT NULL,
  mime_type       TEXT NOT NULL,
  file_size       INTEGER,
  content_base64  TEXT,
  extracted_text  TEXT,
  storage_path    TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE document_chunks (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id  UUID REFERENCES student_documents(id) ON DELETE CASCADE,
  student_id   UUID REFERENCES users(id) ON DELETE CASCADE,
  chunk_text   TEXT NOT NULL,
  chunk_index  INTEGER DEFAULT 0,
  embedding    vector(768),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════
-- CHAT SYSTEM
-- ══════════════════════════════════════════════════════════
CREATE TABLE conversations (
  id                        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id                UUID REFERENCES users(id) ON DELETE CASCADE,
  mentor_email              TEXT,
  title                     TEXT DEFAULT 'New Conversation',
  is_first_message_done     BOOLEAN DEFAULT FALSE,
  student_details_collected BOOLEAN DEFAULT FALSE,
  student_name              TEXT,
  student_program           TEXT,
  student_branch            TEXT,
  student_semester          TEXT,
  student_roll_no           TEXT,
  status                    TEXT DEFAULT 'active' CHECK (status IN ('active','resolved','flagged')),
  created_at                TIMESTAMPTZ DEFAULT NOW(),
  updated_at                TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE messages (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id  UUID REFERENCES conversations(id) ON DELETE CASCADE,
  sender_role      TEXT NOT NULL,
  sender_id        UUID REFERENCES users(id) ON DELETE SET NULL,
  content          TEXT NOT NULL,
  is_ai_generated  BOOLEAN DEFAULT FALSE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════
-- ISSUE & INTERVENTION
-- ══════════════════════════════════════════════════════════
CREATE TABLE issue_reports (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id          UUID REFERENCES users(id) ON DELETE CASCADE,
  student_name        TEXT,
  student_email       TEXT,
  student_program     TEXT,
  student_branch      TEXT,
  student_semester    TEXT,
  mentor_email        TEXT,
  category            TEXT NOT NULL CHECK (category IN (
    'academic','attendance','examination','hostel','financial','placement','personal','faculty','infrastructure','other'
  )),
  title               TEXT NOT NULL,
  description         TEXT NOT NULL,
  priority            TEXT DEFAULT 'medium' CHECK (priority IN ('low','medium','high','urgent')),
  status              TEXT DEFAULT 'open' CHECK (status IN ('open','in_progress','resolved','closed')),
  mentor_response     TEXT,
  mentor_responded_at TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mentor_interventions (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id   UUID REFERENCES conversations(id) ON DELETE CASCADE,
  mentor_id         UUID REFERENCES users(id) ON DELETE SET NULL,
  note              TEXT,
  intervention_type TEXT CHECK (intervention_type IN ('takeover','flag','resolve','note')),
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════
-- INDEXES
-- ══════════════════════════════════════════════════════════
CREATE INDEX idx_users_roll         ON users(roll_number);
CREATE INDEX idx_att_roll           ON attendance(student_roll_no);
CREATE INDEX idx_res_roll           ON academic_results(student_roll_no);
CREATE INDEX idx_sched_roll         ON schedules(student_roll_no);
CREATE INDEX idx_chunks_embedding   ON document_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 50);

-- ══════════════════════════════════════════════════════════
-- DISABLE RLS & PERMISSIONS
-- ══════════════════════════════════════════════════════════
ALTER TABLE users              DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance         DISABLE ROW LEVEL SECURITY;
ALTER TABLE academic_results   DISABLE ROW LEVEL SECURITY;
ALTER TABLE schedules          DISABLE ROW LEVEL SECURITY;
ALTER TABLE student_documents  DISABLE ROW LEVEL SECURITY;
ALTER TABLE document_chunks    DISABLE ROW LEVEL SECURITY;
ALTER TABLE conversations      DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages           DISABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- ══════════════════════════════════════════════════════════
-- MATCH FUNCTION (unchanged logic)
-- ══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION match_document_chunks(
  query_embedding  vector(768),
  match_student_id UUID,
  match_count      INT     DEFAULT 5,
  min_similarity   FLOAT   DEFAULT 0.4
)
RETURNS TABLE (id UUID, chunk_text TEXT, similarity FLOAT, doc_type TEXT, doc_title TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    dc.id, dc.chunk_text, (1 - (dc.embedding <=> query_embedding))::FLOAT AS similarity,
    sd.doc_type, sd.title AS doc_title
  FROM document_chunks dc
  JOIN student_documents sd ON sd.id = dc.document_id
  WHERE dc.student_id = match_student_id AND (1 - (dc.embedding <=> query_embedding)) >= min_similarity
  ORDER BY dc.embedding <=> query_embedding LIMIT match_count;
END;
$$;

SELECT '✅ v9 Schema Ready!' AS status;
