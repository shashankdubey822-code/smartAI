# 🏗️ AI ChatBot - Architecture & System Design

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                             │
│                    (Web, Mobile, Desktop)                       │
├─────────────────────────────────────────────────────────────────┤
│                     UI Layer (Screens)                          │
│  ┌─────────────────┬──────────────────┬──────────────────┐     │
│  │ Auth Screen     │ Student Dashboard│ Mentor Dashboard │     │
│  │ ├─ Login        │ ├─ Chat          │ ├─ Analytics     │     │
│  │ └─ Register     │ ├─ Documents     │ ├─ Student List  │     │
│  │                 │ └─ Issues        │ └─ Interventions │     │
│  └─────────────────┴──────────────────┴──────────────────┘     │
├─────────────────────────────────────────────────────────────────┤
│              State Management Layer (Provider)                  │
│  ┌──────────────────┬─────────────────────────┐               │
│  │  AuthProvider    │   ChatProvider          │               │
│  │  • Login/Logout  │   • Conversations       │               │
│  │  • Register      │   • Messages            │               │
│  │  • Session       │   • Real-time updates   │               │
│  └──────────────────┴─────────────────────────┘               │
├─────────────────────────────────────────────────────────────────┤
│                    Service Layer                                 │
│  ┌──────────────┬──────────────────┬────────────────┐          │
│  │ AIService    │ SupabaseService  │ Other Services │          │
│  │ • Embeddings │ • Auth           │                │          │
│  │ • Chat       │ • Database ops   │                │          │
│  │ • RAG search │ • File uploads   │                │          │
│  └──────────────┴──────────────────┴────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
         │                    │                       │
         ▼                    ▼                       ▼
    ┌─────────┐      ┌──────────────┐      ┌──────────────┐
    │ Gemini  │      │  Supabase    │      │  Supabase    │
    │  API    │      │  PostgreSQL  │      │   Storage    │
    │  (AI)   │      │  (Database)  │      │   (Files)    │
    └─────────┘      └──────────────┘      └──────────────┘
                            │
                            ▼
                    ┌──────────────────┐
                    │  Database Schema │
                    │  • Users         │
                    │  • Conversations │
                    │  • Messages      │
                    │  • Documents     │
                    │  • Attendance    │
                    │  • Results       │
                    │  • Schedules     │
                    └──────────────────┘
```

---

## User Flow Diagram

```
┌──────────────────────────────────────────────────────────┐
│              USER JOURNEY                                 │
└──────────────────────────────────────────────────────────┘

FIRST TIME USER:
  1. Launch App → SplashScreen
  2. Redirect to AuthScreen
  3. Choose: Student OR Mentor
  4. Fill Registration Form
  5. Submit → Database
  6. Redirect to Dashboard
  7. Session Saved Locally

RETURNING USER:
  1. Launch App → SplashScreen
  2. Check SharedPreferences
  3. Session Found → Skip Login
  4. Direct to Dashboard
  5. Load Previous Data

STUDENT WORKFLOW:
  AuthScreen
       ↓
  StudentHomeScreen
       ├→ StudentChatScreen
       │   • Send Query
       │   • AI Responds (RAG)
       │   • View History
       │
       ├→ StudentDocumentsScreen
       │   • Upload PDF/Image
       │   • Auto-chunk & embed
       │   • Store in DB
       │
       └→ StudentIssueScreen
           • Create Issue
           • Mentor Responds
           • Track Status

MENTOR WORKFLOW:
  AuthScreen
       ↓
  MentorDashboardScreen
       ├→ MentorAIChatScreen
       │   • Analyze Students
       │   • Get Recommendations
       │
       ├→ MentorChatViewScreen
       │   • View Student Chat
       │   • Intervene
       │   • Send Guidance
       │
       └→ Analytics
           • Progress Reports
           • Performance Metrics
```

---

## Data Flow: Chat & RAG Process

```
┌─────────────────────────────────────────────────────────────┐
│         STUDENT QUERIES AI - RAG FLOW                       │
└─────────────────────────────────────────────────────────────┘

1️⃣  QUERY PHASE:
    Student: "Explain binary search trees"
              ↓
    Create Embedding of Query
    (Gemini Embedding Model - 3072 dims)
              ↓
    Query Vector: [0.1, 0.2, ..., 0.9]

2️⃣  RETRIEVAL PHASE:
    SELECT document_chunks
    ORDER BY embedding <-> query_vector
    LIMIT 5
              ↓
    Top 5 Relevant Chunks Retrieved:
    • Chunk 1: "BST definition..."
    • Chunk 2: "BST insertion..."
    • Chunk 3: "BST search algorithm..."
    • Chunk 4: "BST balancing..."
    • Chunk 5: "BST complexity..."

3️⃣  AUGMENTATION PHASE:
    Build Context:
    ┌────────────────────────────┐
    │ Context from Documents:    │
    │ [Retrieved Chunks]         │
    │                            │
    │ Student Query:             │
    │ "Explain binary search..." │
    └────────────────────────────┘

4️⃣  GENERATION PHASE:
    Gemini API (gemini-2.5-flash-lite)
    Input: Context + Query
              ↓
    Output: "Binary search trees are..."
              ↓
    Stream Response to UI

5️⃣  STORAGE PHASE:
    Save Message:
    • conversation_id
    • content
    • role (user/assistant)
    • embedding
    • timestamp
              ↓
    Database → Message History Updated
```

---

## Database Relationship Diagram

```
┌──────────────┐
│   USERS      │◄─────────────────┐
├──────────────┤                  │
│ id (PK)      │                  │
│ email        │                  │
│ roll_number  │──────┐           │
│ role         │      │           │
│ name         │      │           │
│ phone        │      │           │
│ created_at   │      │           │
└──────────────┘      │           │
      ▲ │             │           │
      │ │             │           │
      │ │ (mentor_id) │           │
      │ └─────────────┼───────────┘
      │ (student_id)  │
      │               │
      │    ┌──────────┴──────────┐
      │    │                     │
┌─────┴────────────┐    ┌────────▼────────┐
│ CONVERSATIONS    │    │ MESSAGES        │
├──────────────────┤    ├─────────────────┤
│ id (PK)          │    │ id (PK)         │
│ student_id (FK)  │◄───┤ conv_id (FK)    │
│ mentor_id (FK)   │    │ sender_id (FK)  │
│ created_at       │    │ content         │
│ status           │    │ embedding       │
└──────────────────┘    │ created_at      │
                        └─────────────────┘
                                 ▲
                                 │
                    ┌────────────┴────────────┐
                    │                        │
        ┌───────────────────────┐   ┌────────────────────┐
        │ STUDENT_DOCUMENTS     │   │ DOCUMENT_CHUNKS    │
        ├───────────────────────┤   ├────────────────────┤
        │ id (PK)               │───┤ id (PK)            │
        │ student_id (FK)       │   │ doc_id (FK)        │
        │ file_name             │   │ chunk_text         │
        │ file_path             │   │ embedding (Vector) │
        │ created_at            │   │ page_number        │
        └───────────────────────┘   └────────────────────┘


┌──────────────────────────────┐
│ ATTENDANCE (via roll_number) │
├──────────────────────────────┤
│ id (PK)                      │
│ student_roll_no (FK)  ◄──────┼─── References users.roll_number
│ subject_code                 │
│ attended_classes             │
│ attendance_percentage        │
└──────────────────────────────┘

┌──────────────────────────────┐
│ ACADEMIC_RESULTS             │
├──────────────────────────────┤
│ id (PK)                      │
│ student_roll_no (FK)  ◄──────┼─── References users.roll_number
│ semester                     │
│ subject_code                 │
│ marks_obtained               │
│ grade                        │
└──────────────────────────────┘

┌──────────────────────────────┐
│ SCHEDULES/TIMETABLE          │
├──────────────────────────────┤
│ id (PK)                      │
│ student_roll_no (FK)  ◄──────┼─── References users.roll_number
│ day_of_week                  │
│ start_time                   │
│ end_time                     │
│ class_name                   │
└──────────────────────────────┘
```

---

## API Integration Points

```
┌─────────────────────────────────────────────────────────┐
│         EXTERNAL SERVICES INTEGRATION                   │
└─────────────────────────────────────────────────────────┘

1. GEMINI API
   ├─ Chat Model: gemini-2.5-flash-lite
   ├─ Fallbacks: gemini-2.5-flash, gemini-2.5-pro
   ├─ Embedding: gemini-embedding-001
   └─ Called via Supabase Edge Function

2. SUPABASE SERVICES
   ├─ Authentication (Email/Password)
   ├─ PostgreSQL Database
   ├─ Vector Search (pgvector)
   ├─ Real-time Subscriptions
   ├─ File Storage
   ├─ Edge Functions (Chat)
   └─ RLS Policies

3. LOCAL STORAGE
   ├─ SharedPreferences (Session data)
   ├─ File system (Downloads)
   └─ Image picker cache

4. SYSTEM SERVICES
   ├─ image_picker - Camera/Gallery
   ├─ file_picker - File browser
   └─ uuid - ID generation
```

---

## State Management Flow

```
┌───────────────────────────────────────────────────────┐
│             PROVIDER STATE FLOW                       │
└───────────────────────────────────────────────────────┘

AuthProvider:
┌─────────────────────────────────┐
│ State:                          │
│ • _currentUser: UserModel?      │
│ • _isLoading: bool              │
│ • _sessionChecked: bool         │
│                                 │
│ Listeners:                      │
│ • MaterialApp (routes)          │
│ • UI screens (loading state)    │
│                                 │
│ Notifies when:                  │
│ ✓ Login success/failure         │
│ ✓ Logout                        │
│ ✓ Session restored             │
└─────────────────────────────────┘
           │
           ├─ Affects: AuthScreen → Dashboard routing
           │
           └─ Watch: isLoggedIn, isMentor, isStudent


ChatProvider:
┌─────────────────────────────────┐
│ State:                          │
│ • _currentConversation          │
│ • _messages: List<MessageModel> │
│ • _conversations: List<...>     │
│ • _isTyping, _isLoading: bool   │
│                                 │
│ Listeners:                      │
│ • Chat screens (message list)   │
│ • Real-time updates             │
│                                 │
│ Notifies when:                  │
│ ✓ New message received          │
│ ✓ Conversation created          │
│ ✓ AI response arrived           │
└─────────────────────────────────┘
           │
           ├─ Affects: ChatScreen (UI refresh)
           │
           └─ Watch: messages, isTyping
```

---

## Error Handling & Recovery

```
┌─────────────────────────────────────────────────────┐
│     ERROR HANDLING STRATEGY                         │
└─────────────────────────────────────────────────────┘

LOGIN ERRORS:
├─ invalid_credentials → Show error, suggest register
├─ network_error → Retry button
├─ unknown_error → Generic error message

CHAT ERRORS:
├─ RATE_LIMIT → "AI overloaded, try later"
├─ NETWORK_ERROR → Offline indicator
├─ NOT_FOUND → "Edge function not deployed"
├─ CONFIG_ERROR → "API keys not set"
└─ MISSING_API_KEY → Admin notification

DOCUMENT UPLOAD:
├─ file_too_large → Show size limit
├─ invalid_type → Show supported formats
├─ upload_failed → Retry option
└─ embedding_error → Graceful fallback

DATABASE:
├─ connection_error → Retry with backoff
├─ fk_violation → Input validation
├─ vector_error → Index recreation
└─ timeout → Increase timeout
```

---

## Security Architecture

```
┌─────────────────────────────────────────────────────┐
│        SECURITY LAYERS                              │
└─────────────────────────────────────────────────────┘

1. CLIENT LAYER:
   ├─ Password never stored locally
   ├─ Session token in SharedPreferences
   ├─ SSL/TLS for all network calls
   └─ Input validation before send

2. TRANSPORT LAYER:
   ├─ HTTPS only
   ├─ Supabase CDN
   └─ Encrypted connections

3. BACKEND LAYER:
   ├─ Supabase Auth (JWT tokens)
   ├─ Row-Level Security (RLS) policies
   ├─ API key in server env vars
   ├─ Database encryption at rest
   └─ Edge Function sandbox

4. DATABASE LAYER:
   ├─ Foreign key constraints
   ├─ Unique constraints (roll_number)
   ├─ Password hashing (bcrypt)
   ├─ Audit logging (created_at)
   └─ Cascade delete for integrity

5. API SECURITY:
   ├─ Rate limiting (per user)
   ├─ Request timeout (60s)
   ├─ Error message sanitization
   └─ API key rotation capability
```

---

**Architecture Documentation**  
**Generated:** May 2026  
**Version:** 1.0
