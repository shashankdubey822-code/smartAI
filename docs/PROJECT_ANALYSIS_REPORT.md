# 🎓 AI ChatBot Project - Comprehensive Analysis Report

**Project Date:** May 2026  
**Version:** 1.0.0+1  
**Status:** ✅ Active Development

---

## 📋 Executive Summary

Yeh ek **AI Academic Mentor Chatbot** project hai jo students aur mentors ke liye designed hai. Project mein RAG (Retrieval Augmented Generation) technology use hoti hai taake students ko personalized academic guidance mil sake. Yeh Flutter framework mein bana hai jo web, mobile (Android/iOS), aur desktop platforms pe chalता है।

---

## 🏗️ Project Architecture

### Technology Stack
```
Frontend:      Flutter + Dart 3.0+
Backend:       Supabase (PostgreSQL + Edge Functions)
AI Engine:     Google Gemini API (2.5-flash-lite)
Auth:          Supabase Authentication
State Mgmt:    Provider (GetIt-based)
Database:      PostgreSQL with Vector Extension
Storage:       Supabase Storage + File Picker
```

### Platform Support
- ✅ **Web** (Flutter Web)
- ✅ **Android** (Native)
- ✅ **iOS** (Native)
- ✅ **Windows** (Desktop)
- ✅ **macOS** (Desktop)
- ✅ **Linux** (Desktop)

---

## 📱 Key Features & Functionality

### 1. **Authentication System (Login/Register)**

#### Page Ka Kaam:
- Dual-tab system: **Login** aur **Register**
- Dono students aur mentors ke liye alag registration flow

#### Login Flow:
```
User Email + Password 
    ↓
Supabase Authentication
    ↓
Session Saved (SharedPreferences)
    ↓
Dashboard (Student/Mentor)
```

#### Registration Fields (Students):
- Full Name
- Email (unique)
- Password
- Program (e.g., B.Tech)
- Branch (e.g., Computer Science)
- Semester
- **Roll Number** (UNIQUE - database ke liye required)
- Mentor Email (optional)

#### Registration Fields (Mentors):
- Full Name
- Email
- Password
- Designation
- Expertise (JSONB array)
- Office Location
- Office Hours

**Location:** `lib/screens/auth_screen.dart`

---

### 2. **Student Dashboard & Features**

#### Home Screen (`student_home_screen.dart`)
- Profile overview
- Ongoing conversations
- Academic stats quick-view
- Navigation to AI Chat

#### Sub-Modules:

**a) AI Chat Screen (`student_chat_screen.dart`)**
- Real-time conversation with AI mentor
- RAG-enabled responses (context-aware)
- Message history
- Markdown support (flutter_markdown)
- Features:
  - Send text messages
  - Get AI responses powered by Gemini 2.5-flash-lite
  - View previous conversations
  - Session persistence

**b) Documents Screen (`student_documents_screen.dart`)**
- Upload study materials
- File management (image_picker, file_picker)
- Document chunking for RAG
- Features:
  - Upload PDFs, images, documents
  - Auto-chunking for vector search
  - Embedding generation (Gemini Embedding Model)
  - Store chunks in database

**c) Issue Report Screen (`student_issue_screen.dart`)**
- Report academic problems
- Track issue status
- Communicate with mentors about issues
- Features:
  - Create new issue tickets
  - Add description and attachments
  - View mentor responses
  - Real-time status updates

---

### 3. **Mentor Dashboard & Features**

#### Dashboard (`mentor_dashboard_screen.dart`)
- Student list assigned to mentor
- Intervention metrics
- Performance analytics
- Quick access to student conversations

#### Sub-Modules:

**a) Mentor AI Chat (`mentor_ai_chat_screen.dart`)**
- Analyze student interactions
- Get AI recommendations for intervention
- Features:
  - View student chat history
  - Generate intervention strategies
  - Send personalized guidance

**b) Chat View Screen (`mentor_chat_view_screen.dart`)**
- Monitor individual student conversations
- Insert mentor messages
- Real-time collaboration

---

### 4. **Database Schema (v9 - Latest)**

#### Core Tables:

**a) USERS TABLE**
```sql
id (UUID Primary Key)
email (UNIQUE)
password_hash
name
role (student/mentor)
roll_number (UNIQUE for students - CRITICAL)
phone, department, profile_url
program, branch, semester
mentor_email (for students)
skills, hobbies, career_interests (JSONB)
designation, expertise, office_location (for mentors)
created_at, last_active
```

**b) CONVERSATIONS TABLE**
```sql
id (UUID)
student_id (REFERENCES users)
mentor_id (REFERENCES users - optional)
created_at
updated_at
topic
status
```

**c) MESSAGES TABLE**
```sql
id (UUID)
conversation_id
sender_id
content
role (user/assistant)
created_at
embedding (Vector)
```

**d) NEW TABLES (Normalized)**
```
ATTENDANCE:
- student_roll_no (FK to users.roll_number)
- subject_code, subject_name
- total_classes, attended_classes
- attendance_percentage (Auto-calculated)

ACADEMIC_RESULTS:
- student_roll_no (FK)
- semester, subject_code, subject_name
- marks_obtained, max_marks, grade

SCHEDULES/TIMETABLE:
- student_roll_no (FK)
- day_of_week, start_time, end_time
- class_name, room_location
```

**e) DOCUMENT MANAGEMENT**
```
STUDENT_DOCUMENTS:
- student_id, file_name, file_path
- created_at, file_type

DOCUMENT_CHUNKS:
- document_id
- chunk_text
- embedding (Vector - 3072 dims)
- page_number
```

**f) ISSUE TRACKING**
```
ISSUE_REPORTS:
- id, student_id, title, description
- status, priority, created_at, resolved_at
```

**g) MENTOR INTERVENTIONS**
```
MENTOR_INTERVENTIONS:
- id, student_id, mentor_id
- intervention_type, recommendation
- status, created_at
```

---

## 🔧 Core Services & Providers

### 1. **AuthProvider** (`lib/services/auth_provider.dart`)
**Responsibility:** User authentication aur session management

**Key Methods:**
```dart
login(email, password)         → User login
register(...)                  → New user registration
logout()                       → Clear session
_restoreSession()              → Session recovery from SharedPreferences
```

**State Management:**
- `_currentUser` - Logged-in user model
- `_isLoading` - Loading indicator
- `_sessionChecked` - Session validation flag

---

### 2. **ChatProvider** (`lib/services/chat_provider.dart`)
**Responsibility:** Chat conversations aur messaging

**Key Methods:**
```dart
startNewConversation()         → New chat session create
loadMessages()                 → Load message history
sendMessage(content)           → Send user message
getAIResponse()                → Get AI response
loadStudents()                 → Load assigned students (Mentor)
generateProgressReport()       → Student analytics (Mentor)
```

**Real-time Features:**
- Supabase Realtime Channels for live message updates
- Streaming responses from AI

---

### 3. **AIService** (`lib/services/ai_service.dart`)
**Responsibility:** Google Gemini API integration

**Key Methods:**
```dart
createEmbedding(text)          → Convert text to vector
createBatchEmbeddings(chunks)  → Batch embedding generation
generateResponse(query, context) → RAG-based response
retrieveRelevantChunks(query)  → Vector similarity search
```

**Models Used:**
- `gemini-2.5-flash-lite` - Main chat model
- `gemini-2.5-flash` - Fallback
- `gemini-2.5-pro` - Premium fallback
- `gemini-embedding-001` - Vector embeddings (3072 dims)

---

### 4. **SupabaseService** (`lib/services/supabase_service.dart`)
**Responsibility:** Database aur backend operations

**Key Methods:**
- `login()` - Authentication
- `register()` - User creation
- `uploadDocument()` - File upload
- `createConversation()` - New chat
- `sendMessage()` - Store message
- `vectorSearch()` - Query relevant documents
- `getAttendance()` - Fetch student attendance
- `getAcademicResults()` - Fetch grades

---

## 📊 RAG (Retrieval Augmented Generation) Flow

```
Student Query
    ↓
Create Embedding (Gemini)
    ↓
Vector Similarity Search (PostgreSQL)
    ↓
Retrieve Top K Relevant Document Chunks
    ↓
Build Context + Query
    ↓
Generate Response (Gemini 2.5-flash-lite)
    ↓
Stream Response to UI
    ↓
Save Message + Embedding
```

---

## 🎨 UI/UX Structure

### App Theme & Design
- Material Design 3
- Custom color scheme (Dark/Light modes)
- Google Fonts integration
- Responsive layout

### Navigation Flow
```
SplashScreen
    ↓
AuthScreen (Login/Register)
    ↓
├─ StudentHomeScreen (Students)
│   ├─ StudentChatScreen
│   ├─ StudentDocumentsScreen
│   └─ StudentIssueScreen
│
└─ MentorDashboardScreen (Mentors)
    ├─ MentorAIChatScreen
    └─ MentorChatViewScreen
```

---

## 🚀 Current Status - What's Working ✅

### Working Features:
1. ✅ **User Registration & Login**
   - Email validation
   - Password hashing
   - Role-based routing (Student/Mentor)
   - Session persistence

2. ✅ **AI Chat System**
   - Real-time messaging
   - Gemini API integration
   - Markdown rendering
   - Message history

3. ✅ **Database Integration**
   - Supabase PostgreSQL connected
   - Vector extension enabled
   - Schema v9 normalized

4. ✅ **Authentication Flow**
   - Dual role system
   - Email-based auth
   - Roll number validation

5. ✅ **State Management**
   - Provider pattern implemented
   - Multi-provider setup
   - Listener notifications

### Partially Working:
⚠️ **Document Upload & RAG**
- File picker integrated
- Embedding generation logic ready
- Vector search not fully tested
- Chunk storage might need verification

⚠️ **Mentor Dashboard**
- Layout designed
- Student list fetch needed
- Progress reports calculations pending

---

## ⚠️ Current Issues & TODOs

### Critical Issues:
1. **Roll Number Foreign Key**
   - `roll_number` must be UNIQUE for student FK references
   - Needs validation in register flow

2. **Edge Function Deployment**
   - Supabase Edge Function "chat" needs deployment
   - API keys must be stored in Supabase Secrets

3. **Vector Search**
   - Implementation partially complete
   - Similarity threshold needs tuning
   - K-nearest neighbors selection pending

### Performance TODOs:
- [ ] Add pagination for message history
- [ ] Optimize embedding batch processing
- [ ] Cache frequently accessed data
- [ ] Add request rate limiting

### Feature TODOs:
- [ ] Implement attendance tracking UI
- [ ] Add academic results display
- [ ] Build timetable/schedule view
- [ ] Complete issue resolution workflow
- [ ] Add notification system
- [ ] Implement mentor intervention alerts

---

## 🔐 Security Considerations

### Current Security Measures:
- ✅ Password hashing (Supabase)
- ✅ Email-based verification
- ✅ Row-level security (RLS) policies needed
- ✅ API keys in environment

### Recommended:
- [ ] Implement RLS policies for student data
- [ ] Add rate limiting on API endpoints
- [ ] Validate file uploads (virus scan)
- [ ] Add audit logging
- [ ] Implement 2FA for mentors

---

## 📦 Dependencies Summary

**Direct Dependencies:**
```
flutter                  - UI Framework
supabase_flutter: 2.3.4  - Backend + Auth
google_generative_ai     - Gemini API
flutter_markdown: 0.6.18 - Markdown rendering
provider: 6.1.2          - State management
shared_preferences       - Local storage
image_picker: 1.0.7      - Image upload
file_picker: 8.0.3       - File selection
google_fonts: 6.2.1      - Typography
http: 1.2.0              - HTTP client
uuid: 4.3.3              - ID generation
intl: 0.19.0             - Internationalization
```

---

## 🎯 Project Metrics

| Metric | Value |
|--------|-------|
| Total Dart Files | 4+ screens + 4 services + 1 models |
| Database Tables | 9+ normalized tables |
| Supported Platforms | 6 (Web, Android, iOS, Windows, macOS, Linux) |
| API Models | 3 (Chat + 2 Fallbacks) |
| Vector Dimensions | 3072 |
| Target Users | Students + Mentors |

---

## 💡 Key Insights

1. **RAG Architecture**: Project uses advanced vector-based retrieval for context-aware responses
2. **Multi-Role System**: Separate dashboards for students and mentors
3. **Scalable Schema**: v9 schema is normalized with proper relationships
4. **Cross-Platform**: Single codebase runs on all major platforms
5. **Real-time**: Supabase Realtime enables live collaboration

---

## 🔄 Next Steps (Priority Order)

### Phase 1 (High Priority):
1. Deploy Supabase Edge Function for chat
2. Set Gemini API keys in Supabase secrets
3. Test vector search functionality
4. Verify roll number FK constraints

### Phase 2 (Medium Priority):
1. Complete mentor dashboard features
2. Implement attendance UI
3. Add academic results display
4. Test document upload flow

### Phase 3 (Enhancement):
1. Add notification system
2. Implement issue resolution workflow
3. Create analytics dashboard
4. Add gamification features

---

## 📞 Contact & Support

**Project Type:** Flutter Educational Platform  
**Backend:** Supabase  
**AI Provider:** Google Gemini  
**Build Status:** ✅ Ready for development

---

**Report Generated:** May 2026  
**Last Updated:** May 11, 2026
