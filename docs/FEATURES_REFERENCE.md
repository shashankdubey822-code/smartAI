# 🎯 Quick Reference: Features Breakdown

## 📱 LOGIN PAGE - Detailed Explanation

### Login Kaise Kaam Karta Hai:

```
┌─────────────────────────────────────────┐
│        LOGIN FLOW DIAGRAM               │
└─────────────────────────────────────────┘

USER INTERFACE:
┌────────────────────────────────┐
│   LOGIN                        │
├────────────────────────────────┤
│ Email:  [____________]         │
│ Password: [__________]  👁️    │ ← Show/Hide password toggle
│                                │
│      [LOGIN BUTTON]            │
│                                │
│ Not registered? Sign up ➜      │
└────────────────────────────────┘

BACKEND FLOW:
Step 1: User enters email & password
         ↓
Step 2: Validate input (not empty)
         ↓
Step 3: Send to SupabaseService.login()
         ↓
Step 4: Supabase checks:
        - Email exists? YES
        - Password matches? YES
        ↓
Step 5: Return UserModel with:
        - user_id
        - email
        - name
        - role (student/mentor)
        - roll_number (if student)
        ↓
Step 6: AuthProvider saves to memory
         ↓
Step 7: Save session to SharedPreferences
         (Phone memory - persists after restart)
         ↓
Step 8: Navigate to Dashboard
        - If mentor → MentorDashboard
        - If student → StudentDashboard
         ↓
Step 9: Load user data in dashboard
```

### Login Error Handling:

```
Error Type              →  User sees              →  Next step
─────────────────────────────────────────────────────────────
Invalid Email           →  "Invalid email"        →  Fix email
Wrong Password          →  "Incorrect password"   →  Try again
User Not Found          →  "User not found"       →  Suggest Sign Up
Network Error           →  "Check internet"       →  Retry
Server Down             →  "Server unavailable"   →  Try later
```

---

## 📝 REGISTRATION PAGE - Detailed Explanation

### Student Registration:

```
Tab 1: REGISTER (with Student selection)

Fields to Fill:
┌─────────────────────────────────────┐
│ Full Name:        [________________] │
│ Email:            [________________] │
│ Password:         [________________] │
│ Confirm Password: [________________] │
│                                     │
│ Program:    [Dropdown - B.Tech]     │
│ Branch:     [Dropdown - CS]         │
│ Semester:   [Dropdown - 4]          │
│                                     │
│ Roll Number: [________________] ⭐ │ REQUIRED
│ Mentor Email: [________________]    │ Optional
│                                     │
│         [SIGN UP BUTTON]            │
└─────────────────────────────────────┘

⭐ Roll Number:
  Why required?
  - Database uses it as foreign key
  - Links student to attendance records
  - Links to academic results
  - Links to schedule/timetable
  Format: E.g., "21CS001", "22IT045"
```

### Mentor Registration:

```
Tab 1: REGISTER (with Mentor selection)

Fields to Fill:
┌─────────────────────────────────────┐
│ Full Name:        [________________] │
│ Email:            [________________] │
│ Password:         [________________] │
│ Confirm Password: [________________] │
│                                     │
│ Designation:  [________________]    │
│               (Prof, Asst Prof, etc)│
│                                     │
│ Expertise: [Select Multiple] ✓      │
│  ✓ Data Structures               │
│  ☐ Web Development               │
│  ☐ Machine Learning              │
│  ☐ System Design                 │
│                                     │
│ Office Location: [________________] │
│ Office Hours:    [________________] │
│  (E.g., "Mon-Fri 10AM-2PM")      │
│                                     │
│         [SIGN UP BUTTON]            │
└─────────────────────────────────────┘
```

### Registration Validation:

```
Field               Validation Rule
────────────────────────────────────────────
Name                • Not empty
                    • Min 3 characters
                    • Max 100 characters

Email               • Valid format (xxx@yyy.zz)
                    • Must be unique
                    • Check if already registered

Password            • Min 8 characters
                    • Uppercase (A-Z)
                    • Lowercase (a-z)
                    • Numbers (0-9)
                    • Special chars (!@#$%)

Confirm Password    • Must match password

Roll Number         • Unique (students)
(Student)           • Format: 2[0-9]{1}[A-Z]{2}[0-9]{3}
                    • Example: 21CS001, 22IT045

Mentor Email        • Valid format OR empty
(Student)           • Must be existing mentor email
```

---

## 💬 STUDENT CHAT - Feature Breakdown

### Chat Screen Features:

```
┌──────────────────────────────────────┐
│ AI ACADEMIC ASSISTANT 🎓             │
├──────────────────────────────────────┤
│ [Earlier messages...]                │
│                                      │
│ 10:30 AM - You:                     │
│ "How do I write a binary tree?"     │
│                                      │
│ 10:31 AM - AI:                      │
│ "A binary tree is a data structure  │
│  where each node has at most two    │
│  children..."                       │
│  [Source: CS101 Lecture]            │
│                                      │
│ 10:35 AM - You:                     │
│ "Can you explain in-order traversal"│
│                                      │
│ 10:36 AM - AI:                      │
│ ⏳ Typing...                         │
│                                      │
├──────────────────────────────────────┤
│ [📎] [Message box........] [Send ▶️]  │
│       ↑                              │
│       Attach file/image              │
└──────────────────────────────────────┘

Features Available:
✓ Send text messages
✓ Attach files/images
✓ Markdown formatting (bold, code)
✓ View AI thinking indicator
✓ Message history
✓ Copy message
✓ Search messages
✗ Delete messages (not yet)
✗ Pin important messages (not yet)
✗ Message reactions (not yet)
```

### RAG (Smart Context) How Works:

```
Question: "What is Binary Search Tree?"

Step 1: System creates embedding of question
Step 2: Searches student's uploaded documents
Step 3: Finds relevant sections:
        - DSA lecture notes (page 45)
        - Assignment about BST (page 12)
        - Previous chat about trees

Step 4: AI reads all this context
Step 5: Provides personalized answer that:
        - References student's materials
        - Matches teaching style
        - Fills knowledge gaps

Student gets:
✓ Context-aware answer
✓ References from their materials
✓ Personalized explanations
✓ Study resource links
```

---

## 📄 DOCUMENTS UPLOAD - Feature Breakdown

### How to Upload:

```
┌───────────────────────────────────────┐
│ MY DOCUMENTS                          │
├───────────────────────────────────────┤
│                                       │
│ [+ Upload Document]  [📁 Browse]     │
│                                       │
│ Documents:                           │
│                                       │
│ 1. DSA_Lecture_Week1.pdf             │
│    Uploaded: May 10 | Size: 2.4 MB   │
│    Status: ✅ Embedded (45 chunks)   │
│    [Delete] [Preview]                │
│                                       │
│ 2. Assignment_Answers.pdf            │
│    Uploaded: May 8 | Size: 1.8 MB    │
│    Status: ✅ Embedded (32 chunks)   │
│    [Delete] [Preview]                │
│                                       │
│ 3. Notes_Chapter5.jpg                │
│    Uploaded: May 5 | Size: 3.2 MB    │
│    Status: ✅ Embedded (12 chunks)   │
│    [Delete] [Preview]                │
│                                       │
└───────────────────────────────────────┘
```

### What Happens After Upload:

```
User uploads "DSA_Lecture.pdf"
         ↓
1. File validation:
   ✓ Check file size (max 10 MB)
   ✓ Check file type (PDF, JPG, PNG)
   ✓ Scan for virus (future)
         ↓
2. Upload to Supabase Storage:
   Location: /students/{user_id}/documents/
         ↓
3. Create database entry:
   INSERT INTO student_documents
   (student_id, file_name, file_path, created_at)
         ↓
4. Process file:
   ├─ Read content
   ├─ Split into chunks (500 chars each)
   ├─ For each chunk:
   │  ├─ Create embedding (Gemini API)
   │  ├─ Store in database
   │  └─ Index for search
   └─ Takes ~30 seconds for 50 chunks
         ↓
5. Now AI can reference this:
   Question: "What's in DSA lecture?"
   AI: "Based on your DSA_Lecture.pdf..."
```

### Supported Formats:

```
Format       Support    Why
──────────────────────────────────────
PDF          ✅ Full    Most lecture notes
JPG/PNG      ✅ Full    Handwritten notes
TXT          ✅ Full    Plain text notes
DOCX         ⚠️  Partial Word documents
XLSX         ⚠️  Partial Excel sheets
PPT          ❌ Not yet Presentations
Video        ❌ Not yet Audio transcripts
```

---

## 🚨 ISSUE REPORT - Feature Breakdown

### How to Report Issue:

```
┌───────────────────────────────────────┐
│ REPORT AN ISSUE                       │
├───────────────────────────────────────┤
│                                       │
│ Issue Title:                         │
│ [___________________________]         │
│                                       │
│ Priority:                            │
│ ☐ Low  ☐ Medium  ☐ High  ☐ Critical │
│                                       │
│ Subject Area:                        │
│ [Dropdown: DSA, DBMS, OOP, ...]      │
│                                       │
│ Description:                         │
│ [.................................]   │
│ [.................................]   │
│ [.................................]   │
│                                       │
│ Attachments:                         │
│ [+ Add File]                         │
│                                       │
│ Can mentor help? [Toggle: Yes/No]    │
│                                       │
│ [SUBMIT] [CANCEL]                    │
└───────────────────────────────────────┘
```

### Issue Lifecycle:

```
Created by Student
      ↓
Status: 🔴 NEW
      ↓
Mentor reviews
      ↓
Status: 🟡 IN REVIEW
      ↓
Mentor responds with solution
      ↓
Status: 🔵 RESOLVED
      ↓
Student confirms
      ↓
Status: 🟢 CLOSED
```

### Issue Tracking:

```
Current Issues:
│
├─ 🔴 Need help with recursion
│   Priority: High
│   Created: 2 days ago
│   Mentor assigned: Dr. Sharma
│
├─ 🟡 Binary search tree implementation
│   Priority: Medium
│   Created: 1 day ago
│   Under review...
│
└─ 🟢 Stack vs Queue confusion
    Priority: Medium
    Created: 3 days ago
    ✓ Resolved by mentor
```

---

## 👨‍🏫 MENTOR DASHBOARD - Feature Breakdown

### Dashboard View:

```
┌──────────────────────────────────────┐
│ MENTOR DASHBOARD                     │
│ Welcome, Dr. Sharma! 👋              │
├──────────────────────────────────────┤
│                                      │
│ QUICK STATS:                        │
│ ┌──────────┬──────────┬────────────┐│
│ │ Students │ Issues   │ Pending    ││
│ │   145    │   23     │    7       ││
│ └──────────┴──────────┴────────────┘│
│                                      │
│ MY STUDENTS:                        │
│ ┌──────────────────────────────────┐│
│ │ Name        │ Status  │ Last chat ││
│ ├──────────────────────────────────┤│
│ │ Raj Kumar   │ Active  │ 2 hrs ago ││
│ │ Priya Singh │ Active  │ 30 min ago││
│ │ Amit Verma  │ Idle    │ 2 days ago││
│ │ Neha Patel  │ Active  │ Just now  ││
│ └──────────────────────────────────┘│
│                                      │
│ PENDING INTERVENTIONS:              │
│ 1. Raj Kumar - Struggling with DSA  │
│    Action: Send practice problems   │
│ 2. Priya Singh - Low attendance    │
│    Action: Schedule meeting        │
│                                      │
│ [View All Students] [View Issues]   │
└──────────────────────────────────────┘
```

### Mentor Capabilities:

```
✅ View assigned students
✅ See student chat history
✅ Analyze student performance
✅ Generate intervention strategies
✅ Send messages to students
✅ Track issue resolutions
✅ Generate progress reports
✅ View attendance patterns
✅ Track academic performance
✅ Schedule meetings

⏳ Planned features:
- Automated intervention alerts
- Predictive analytics
- Batch messaging
- File sharing with students
- Schedule management
- Student feedback forms
```

---

## 🔌 API Integration Points

### Gemini API (AI Responses):

```
Model           Use Case            Capability
────────────────────────────────────────────────
2.5-flash-lite  Chat responses      Fast, efficient
2.5-flash       Fallback 1          Higher quality
2.5-pro         Fallback 2          Best quality
embedding-001   Document search     Vector creation
```

### Supabase Edge Functions:

```
Function: "chat"
Purpose:  Handle AI requests securely

Flow:
Frontend → Sends query to Edge Function
         ↓
Edge Function:
  • Validates user token
  • Retrieves API key from secrets
  • Calls Gemini API
  • Returns response
         ↓
Frontend → Displays response to user

Benefits:
✓ API keys hidden from frontend
✓ Rate limiting on server
✓ Request validation
✓ Logging & monitoring
```

---

## 📊 Database Tables Quick Reference

```
TABLE           ROWS    PURPOSE
──────────────────────────────────────────
users           ~200    Student/Mentor profiles
conversations   ~5000   Chat sessions
messages        ~50000  Individual messages
documents       ~500    Uploaded files
chunks          ~5000   Document pieces
attendance      ~2000   Class attendance
results         ~3000   Exam scores
schedules       ~500    Class timetable
issues          ~200    Bug/help requests
interventions   ~100    Mentor actions
```

---

## ⚡ Performance Metrics

```
Operation                Time        Target
────────────────────────────────────────────
User Login               <1s         <2s ✅
Load Chat History        <2s         <3s ✅
Generate Response        5-10s       <15s ✅
Upload Document          3-5s        <10s ✅
Vector Search            <1s         <2s ✅
Load Dashboard           2-3s        <5s ✅

Network Optimization:
• Compress messages
• Cache frequently used data
• Lazy load older messages
• Batch API requests
```

---

**Quick Reference Guide**  
**Generated:** May 2026  
**Keep this for developers & users**
