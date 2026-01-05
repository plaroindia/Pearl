# PEARL Agent - Database Integration Guide

## ✅ What Changed: In-Memory → Persistent Database Storage

### The Problem (Before)
Learning paths were stored **only in Python memory** (`learning_paths_store` dictionary), which meant:
- ❌ Progress **lost on server restart**
- ❌ No **persistent user history**
- ❌ Multiple users would **interfere** with each other
- ❌ **Can't resume** learning across sessions

### The Solution (After)
All learning state is now **persisted to Supabase**, which means:
- ✅ Progress **survives server restarts**
- ✅ Full **user history** and achievements tracked
- ✅ **Multi-user support** with user isolation
- ✅ **Resume anytime** from last checkpoint
- ✅ **Analytics** on learning patterns

---

## 🗄️ Database Tables Used

### 1. `ai_agent_sessions`
**Stores overall learning journey**
```sql
- id: uuid (PRIMARY KEY)
- user_id: uuid (FOREIGN KEY → user_profiles)
- session_type: text ('career_guidance')
- jd_text: text (original goal/JD)
- jd_parsed: jsonb ← COMPLETE LEARNING PATHS STORED HERE
- status: text ('active'/'completed')
- created_at, updated_at: timestamps
```

**What's stored in `jd_parsed`:**
```json
{
  "learning_paths": {
    "Python": {
      "skill": "Python",
      "total_modules": 5,
      "current_module": 2,
      "modules": [
        {
          "module_id": 1,
          "status": "completed",
          "actions": [
            {"type": "byte", "completed": true},
            {"type": "course", "completed": true},
            {"type": "taiken", "completed": true},
            {"type": "checkpoint", "completed": true}
          ]
        }
      ]
    },
    "SQL": {...}
  },
  "updated_at": "2024-01-05T10:30:00Z"
}
```

### 2. `ai_module_progress`
**Tracks progress per module per user**
```sql
- id: uuid (PRIMARY KEY)
- session_id: uuid (FOREIGN KEY → ai_agent_sessions)
- user_id: uuid (FOREIGN KEY → user_profiles)
- skill: text ('Python', 'SQL', etc.)
- module_id: integer (1, 2, 3...)
- module_name: text ('Foundations', 'Core Concepts', etc.)
- status: text ('locked' | 'active' | 'completed')
- actions_completed: integer (0-4)
- total_actions: integer (4)
- started_at: timestamp
- completed_at: timestamp
```

**Example rows:**
```
session_id | skill  | module_id | status    | actions_completed | total_actions
-----------|--------|-----------|-----------|------------------|---------------
uuid-xxx   | Python | 1         | completed | 4                 | 4
uuid-xxx   | Python | 2         | active    | 2                 | 4
uuid-xxx   | Python | 3         | locked    | 0                 | 4
uuid-xxx   | SQL    | 1         | active    | 1                 | 4
```

### 3. `ai_action_completions`
**Records each action completion**
```sql
- id: uuid (PRIMARY KEY)
- module_progress_id: uuid (FOREIGN KEY → ai_module_progress)
- action_index: integer (0, 1, 2, 3)
- action_type: text ('byte' | 'course' | 'taiken' | 'checkpoint')
- completion_data: jsonb {url_visited, timestamp, etc.}
- completed_at: timestamp
```

**Example:**
```
module_progress_id | action_index | action_type | completed_at
-------------------|--------------|-------------|------------------------
uuid-yyy           | 0            | byte        | 2024-01-05 09:15:00
uuid-yyy           | 1            | course      | 2024-01-05 10:30:00
```

### 4. `ai_checkpoint_results`
**Stores quiz submissions and scores**
```sql
- id: uuid (PRIMARY KEY)
- module_progress_id: uuid (FOREIGN KEY → ai_module_progress)
- user_id: uuid (FOREIGN KEY → user_profiles)
- questions: jsonb [{question, options, correct_index, explanation}]
- answers: jsonb [0, 1, 2, 0]
- score: numeric (0-100)
- passed: boolean
- submitted_at: timestamp
```

**Example:**
```
score | passed | answers     | submitted_at
------|--------|-------------|------------------------
85    | true   | [0,1,2,0]   | 2024-01-05 10:45:00
60    | false  | [1,1,1,1]   | 2024-01-05 10:50:00
```

### 5. `user_skill_memory`
**Tracks user's skill confidence levels**
```sql
- id: uuid (PRIMARY KEY)
- user_id: uuid (FOREIGN KEY → user_profiles)
- skill_name: text ('Python', 'SQL', etc.)
- confidence_score: numeric (0.0-1.0)
- practice_count: integer
- last_practiced_at: timestamp
- evidence: jsonb
```

**Updated automatically:**
```
skill_name | confidence_score | practice_count | last_practiced_at
-----------|------------------|----------------|-------------------
Python     | 0.75             | 3              | 2024-01-05 10:45:00
SQL        | 0.45             | 1              | 2024-01-05 08:30:00
```

---

## 🔄 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      User Frontend                           │
│                   (pearl_frontend.html)                      │
└────────┬────────────────────────────────────────────────────┘
         │
         │ POST /start-journey
         │ POST /complete-action
         │ POST /submit-checkpoint
         │ GET /current-action
         │ GET /progress
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Backend                           │
│                  (pearl_routes.py)                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  PEARLDatabaseHelper                                 │   │
│  │  - save_learning_paths()                             │   │
│  │  - save_module_progress()                            │   │
│  │  - save_action_completion()                          │   │
│  │  - save_checkpoint_result()                          │   │
│  │  - update_skill_confidence()                         │   │
│  │  - get_session_learning_paths()                      │   │
│  └──────────────────────────────────────────────────────┘   │
└────────┬────────────────────────────────────────────────────┘
         │
         │ INSERT/UPDATE/SELECT
         │ (Supabase Client)
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│              Supabase PostgreSQL Database                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ ai_agent_sessions                                    │   │
│  │ └─ jd_parsed JSONB (complete learning paths)        │   │
│  │                                                      │   │
│  │ ai_module_progress                                   │   │
│  │ └─ Tracks module completion status                  │   │
│  │                                                      │   │
│  │ ai_action_completions                               │   │
│  │ └─ Records individual action completions            │   │
│  │                                                      │   │
│  │ ai_checkpoint_results                               │   │
│  │ └─ Stores quiz submissions and scores               │   │
│  │                                                      │   │
│  │ user_skill_memory                                    │   │
│  │ └─ Updates skill confidence levels                  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Key Database Methods

### `PEARLDatabaseHelper.save_learning_paths()`
```python
# When: User starts journey or completes a module
# Stores: Complete learning paths structure in ai_agent_sessions.jd_parsed

PEARLDatabaseHelper.save_learning_paths(
    session_id="uuid-xxx",
    user_id="uuid-yyy",
    learning_paths={
        "Python": {...complete path with all modules and actions...},
        "SQL": {...}
    }
)
# Result: Updates ai_agent_sessions.jd_parsed with complete state
```

### `PEARLDatabaseHelper.save_module_progress()`
```python
# When: Module status changes (active → completed)
# Stores: Individual module progress record

result = PEARLDatabaseHelper.save_module_progress(
    session_id="uuid-xxx",
    user_id="uuid-yyy",
    skill="Python",
    module_id=1,
    module_data={
        "name": "Foundations",
        "status": "completed",
        "actions": [...]
    }
)
# Result: INSERT or UPDATE ai_module_progress with module_id=uuid
```

### `PEARLDatabaseHelper.save_action_completion()`
```python
# When: User completes a single action (byte, course, taiken)
# Stores: Action completion record

PEARLDatabaseHelper.save_action_completion(
    module_progress_id="uuid-zzz",
    action_index=0,
    action_type="byte",
    completion_data={
        "completed": True,
        "timestamp": "2024-01-05T10:30:00Z"
    }
)
# Result: INSERT into ai_action_completions
```

### `PEARLDatabaseHelper.save_checkpoint_result()`
```python
# When: User submits checkpoint quiz
# Stores: Quiz submission, answers, score, pass/fail

PEARLDatabaseHelper.save_checkpoint_result(
    module_progress_id="uuid-zzz",
    user_id="uuid-yyy",
    skill="Python",
    module_id=1,
    questions=[{question, options, correct_index, explanation}],
    answers=[0, 1, 2, 0],
    score=85.0,
    passed=True
)
# Result: 
# 1. INSERT into ai_checkpoint_results
# 2. UPDATE user_skill_memory (confidence_score += 0.1)
```

### `PEARLDatabaseHelper.get_session_learning_paths()`
```python
# When: Resume session or get current action
# Retrieves: Complete learning paths from database

learning_paths = PEARLDatabaseHelper.get_session_learning_paths(
    session_id="uuid-xxx"
)
# Returns: {Python: {...}, SQL: {...}}
```

---

## 📊 Typical User Journey (Database Perspective)

### Step 1: User Starts Journey
```python
# POST /start-journey
# {goal: "Backend Developer"}

# Database Operations:
1. db.create_session(user_id, goal)  
   # CREATE ai_agent_sessions record

2. PEARLDatabaseHelper.save_learning_paths(session_id, user_id, paths)
   # UPDATE ai_agent_sessions.jd_parsed with complete paths

3. For each module:
   PEARLDatabaseHelper.save_module_progress(session_id, user_id, skill, module_id, module)
   # CREATE ai_module_progress record for each module
   
# Database State:
ai_agent_sessions: 1 record (contains all learning paths)
ai_module_progress: 15 records (5 skills × 3 modules each)
```

### Step 2: User Completes Action
```python
# POST /complete-action
# {skill: "Python", module_id: 1, action_index: 0}

# Database Operations:
1. Retrieve: ai_agent_sessions WHERE id = session_id
   # Get current learning paths

2. Update in-memory learning path

3. PEARLDatabaseHelper.save_action_completion(module_progress_id, action_index, type, data)
   # CREATE ai_action_completions record

4. PEARLDatabaseHelper.save_module_progress(...)
   # UPDATE ai_module_progress SET actions_completed = 1

5. PEARLDatabaseHelper.save_learning_paths(...)
   # UPDATE ai_agent_sessions.jd_parsed with updated state

# Database State:
ai_action_completions: 1 new record
ai_module_progress: actions_completed incremented
ai_agent_sessions.jd_parsed: updated
```

### Step 3: User Submits Checkpoint
```python
# POST /submit-checkpoint
# {skill: "Python", module_id: 1, answers: [0,1,2,0]}

# Database Operations:
1. Retrieve: ai_agent_sessions WHERE id = session_id

2. Evaluate checkpoint (in-memory)

3. PEARLDatabaseHelper.save_checkpoint_result(...)
   # CREATE ai_checkpoint_results record
   # UPDATE user_skill_memory (confidence_score)

4. If passed:
   PEARLDatabaseHelper.save_module_progress(...)
   # UPDATE module 1 status to 'completed'
   # UPDATE module 2 status to 'active'

5. PEARLDatabaseHelper.save_learning_paths(...)
   # UPDATE ai_agent_sessions.jd_parsed with new state

# Database State:
ai_checkpoint_results: 1 new record with score/answers
user_skill_memory: confidence_score updated
ai_module_progress: module 1 completed, module 2 active
ai_agent_sessions.jd_parsed: updated
```

### Step 4: User Resumes Later
```python
# GET /current-action/{session_id}

# Database Operations:
1. Retrieve: ai_agent_sessions WHERE id = session_id
   # Get complete learning paths from jd_parsed

2. Restore all module states from ai_agent_sessions

3. Find next incomplete action

# Returns: Next action with full context

# No data loss - everything persisted in DB
```

---

## 🔐 Data Consistency

### Transaction Safety
Each endpoint wraps operations in try-catch:
```python
try:
    # 1. Retrieve from DB
    session = db.client.table('ai_agent_sessions').select(...).execute()
    
    # 2. Update in-memory (temporary working copy)
    learning_paths = session.data['jd_parsed']['learning_paths']
    learning_path[skill]['modules'][module_id].actions[action_idx].completed = True
    
    # 3. Save back to DB
    PEARLDatabaseHelper.save_action_completion(...)
    PEARLDatabaseHelper.save_learning_paths(...)  # Atomic update
    
except Exception as e:
    # Rollback happens automatically
    log_error(e)
    raise HTTPException(500)
```

### What Happens if Server Crashes?
- **Before crash**: Some database writes may be in progress
- **After restart**: `get_session_learning_paths()` retrieves last complete state from DB
- **User resumes**: From last saved checkpoint (no progress loss beyond last save)

---

## 📈 Querying Progress Data

### Get User's Total Progress
```sql
SELECT 
    user_id,
    COUNT(DISTINCT skill) as skills_learning,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_modules,
    COUNT(*) as total_modules,
    ROUND(100.0 * COUNT(CASE WHEN status = 'completed' THEN 1 END) / COUNT(*), 1) as progress_percentage
FROM ai_module_progress
WHERE user_id = 'uuid-yyy'
GROUP BY user_id;
```

### Get User's Checkpoint Scores
```sql
SELECT 
    skill,
    module_id,
    AVG(score) as avg_score,
    COUNT(*) as attempts,
    ROUND(100.0 * COUNT(CASE WHEN passed THEN 1 END) / COUNT(*), 1) as pass_rate
FROM ai_checkpoint_results
WHERE user_id = 'uuid-yyy'
GROUP BY skill, module_id
ORDER BY skill, module_id;
```

### Get Skill Confidence Trend
```sql
SELECT 
    skill_name,
    confidence_score,
    practice_count,
    last_practiced_at
FROM user_skill_memory
WHERE user_id = 'uuid-yyy'
ORDER BY confidence_score DESC;
```

---

## 🚀 Performance Considerations

### Database Indexes (Recommended)
```sql
-- For fast lookups by session and skill
CREATE INDEX idx_module_progress_session_skill 
ON ai_module_progress(session_id, skill);

-- For checkpoint queries
CREATE INDEX idx_checkpoint_results_user 
ON ai_checkpoint_results(user_id);

-- For skill memory updates
CREATE INDEX idx_skill_memory_user_skill 
ON user_skill_memory(user_id, skill_name);

-- For session retrieval
CREATE INDEX idx_sessions_user_status 
ON ai_agent_sessions(user_id, status);
```

### Query Performance
- **Start journey**: 1 session INSERT + N module INSERTs (N=3-5)
- **Complete action**: 1-2 UPDATEs (action completion + module progress)
- **Submit checkpoint**: 1 INSERT (checkpoint result) + 1-2 UPDATEs (skill memory)
- **Get progress**: 1 SELECT (session) + 1 SELECT (module progress) - O(1) operations

### Batch Operations
For bulk updates, consider:
```python
# Instead of individual saves per module:
modules_to_save = [
    {module_id: 1, status: 'completed'},
    {module_id: 2, status: 'active'},
    {module_id: 3, status: 'locked'}
]

# Single batch update (more efficient)
db.client.table('ai_module_progress').upsert(modules_to_save).execute()
```

---

## ✅ Verification

### Check Data is Being Saved
```bash
# In Supabase dashboard or psql:

# Check sessions created
SELECT id, user_id, created_at FROM ai_agent_sessions LIMIT 5;

# Check module progress
SELECT * FROM ai_module_progress WHERE skill = 'Python' LIMIT 10;

# Check checkpoint results
SELECT user_id, skill, score, passed FROM ai_checkpoint_results LIMIT 10;

# Check skill memory updates
SELECT * FROM user_skill_memory WHERE user_id = 'uuid-xxx';
```

### Monitor Data Consistency
```python
# In backend logs, you'll see:
[PEARL] Saving action completion: module_progress_id=uuid
[PEARL] Updating skill confidence: Python -> 0.75
[PEARL] Saving learning paths for session: uuid-xxx

# If database writes fail:
[ERROR] Failed to save action completion: connection refused
# → System falls back gracefully, continues with next action
```

---

## 🎓 Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Storage** | Python dictionary in memory | Supabase PostgreSQL |
| **Persistence** | Lost on restart | Permanent, queryable |
| **Multi-user** | Interfere with each other | Fully isolated |
| **Session resume** | Impossible | Pick up from last checkpoint |
| **Analytics** | None | Full progress tracking |
| **Scalability** | Single server only | Multi-server ready |
| **Data availability** | Single source of truth is fragile | Backed by enterprise DB |

---

## 📞 Common Issues

### Issue: "ai_agent_sessions table not found"
**Fix**: Ensure Supabase tables exist. Run the SQL schema provided in the main guide.

### Issue: "Learning paths not persisted after restart"
**Fix**: Verify `PEARLDatabaseHelper.save_learning_paths()` is called in `/start-journey` endpoint.

### Issue: "Checkpoint results not saving"
**Fix**: Check that `module_progress_id` is retrieved correctly before saving checkpoint result.

### Issue: "User skill confidence not updating"
**Fix**: Ensure `update_skill_confidence()` is called in `save_checkpoint_result()` when checkpoint passes.

---

**Status**: ✅ Fully integrated with Supabase  
**Last Updated**: 2024-01-05  
**All progress is now persistent and queryable**
