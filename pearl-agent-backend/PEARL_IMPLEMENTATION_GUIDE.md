# PEARL Agent - Enhanced Integration Guide

## 🎯 Overview

This enhanced version transforms your career readiness platform into a fully agentic learning system with:

1. **Module Decomposition Engine** - Breaks skills into bite-sized, actionable modules
2. **Action Router** - Maps each module to specific action types with real external resources
3. **Checkpoint System** - Validates completion before progression
4. **Enhanced RAG** - Retrieves real YouTube, Coursera, interactive tools
5. **Agentic Loop** - Drives users through action → verify → advance cycle

---

## 📁 Files Created

### Backend Services

#### 1. `services/pearl_agent.py` (NEW)
**Core agentic orchestrator with:**
- `ModuleDecompositionEngine`: Breaks skills into 4-6 granular modules
- `ActionRouter`: Maps modules to 4 action types (Byte, Course, Taiken, Checkpoint)
- `CheckpointSystem`: Validates quiz completion and provides feedback
- `PEARLAgent`: Main orchestrator driving the learning loop

#### 2. `services/enhanced_rag_service.py` (NEW)
**Real external resource retrieval with:**
- Curated database of 7+ skills (Python, SQL, React, ML, etc.)
- Platform-specific resources (YouTube, Coursera, freeCodeCamp, Replit)
- Smart fallback for unavailable resources
- Easy resource management for hackathon updates

#### 3. `routes/pearl_routes.py` (NEW)
**Six new API endpoints:**
- `/start-journey` - Initialize career path with skill breakdown
- `/current-action/{session_id}` - Get user's next action
- `/complete-action` - Mark action complete and advance
- `/submit-checkpoint` - Validate checkpoint quiz
- `/progress/{session_id}/{skill}` - Get detailed skill progress
- `/final-assessment/{session_id}/{skill}` - Generate comprehensive assessment

### Frontend

#### 4. `pearl_frontend.html` (NEW)
**Action-driven UI with:**
- Career goal input with optional JD parsing
- Skill breakdown and module visualization
- Action-by-action guidance with real external links
- Checkpoint quiz interface
- Real-time progress tracking
- Result feedback and detailed explanations

### Configuration

#### 5. `main.py` (UPDATED)
Added import and router registration for `pearl_routes`

---

## 🚀 Getting Started

### 1. Verify Files Are Created

All files should exist:
```
pearl-agent-backend/
├── services/
│   ├── pearl_agent.py ✓
│   ├── enhanced_rag_service.py ✓
│   └── geminiai_service.py (existing)
├── routes/
│   ├── pearl_routes.py ✓
│   └── agent.py (existing)
├── main.py ✓ (updated)
└── pearl_frontend.html ✓
```

### 2. Start the Backend

```bash
cd pearl-agent-backend
python main.py
```

Server runs on `http://localhost:8000`

### 3. Access the Frontend

**New Agentic UI:**
```
http://localhost:8000/pearl_frontend.html
```

**Legacy UI (still works):**
```
http://localhost:8000/frontend.html
```

---

## 💡 How It Works

### User Journey Flow

1. **User enters career goal** → "Become a Backend Developer"
2. **System analyzes and extracts skills** → [Python, SQL, REST APIs]
3. **For each skill, creates module-based learning path:**
   - Module 1: Foundations (4 actions)
   - Module 2: Core Concepts (4 actions)
   - Module 3: Advanced Topics (4 actions)
   - etc.

4. **Each module has 4 actions:**
   - **Byte**: 2-5 min video explainer (YouTube)
   - **Course**: 30-60 min structured course (Coursera/freeCodeCamp)
   - **Taiken**: 60-90 min hands-on practice (Replit/CodePen)
   - **Checkpoint**: Quiz validation (PEARL Quiz)

5. **User completes actions sequentially**
6. **Checkpoint validates** → Pass: unlock next module | Fail: review and retry
7. **Progress tracked** → Action level → Module level → Skill level

### Action Types

| Type | Duration | Purpose | Platform |
|------|----------|---------|----------|
| **Byte** | 2-5 min | Quick intro | YouTube |
| **Course** | 30-60 min | Structured learning | Coursera/freeCodeCamp |
| **Taiken** | 60-90 min | Hands-on practice | Replit/CodePen |
| **Checkpoint** | 15 min | Knowledge validation | PEARL Quiz |

---

## 📊 API Endpoints

### 1. Start Journey
```bash
POST /agent/start-journey
Content-Type: application/json

{
  "goal": "Become a Backend Developer",
  "jd_text": "Optional job description..."
}

Response:
{
  "session_id": "uuid-xxx",
  "target_role": "Backend Developer",
  "skills_to_learn": ["Python", "SQL", "REST APIs"],
  "learning_paths": {
    "Python": {
      "skill": "Python",
      "total_modules": 5,
      "estimated_hours": 15,
      "current_module": 1,
      "modules": [...]
    }
  },
  "gap_analysis": {...},
  "next_action": {...}
}
```

### 2. Get Current Action
```bash
GET /agent/current-action/{session_id}

Response:
{
  "session_id": "uuid-xxx",
  "current_skill": "Python",
  "next_action": {
    "module": "Foundations",
    "module_id": 1,
    "action_index": 0,
    "action": {...},
    "instruction": "📱 Watch this 5-minute explainer: Python Basics"
  },
  "learning_path": {...}
}
```

### 3. Complete Action
```bash
POST /agent/complete-action
Content-Type: application/json

{
  "session_id": "uuid-xxx",
  "skill": "Python",
  "module_id": 1,
  "action_index": 0,
  "completion_data": {
    "completed": true,
    "action_type": "byte"
  }
}

Response:
{
  "success": true,
  "message": "Action completed! Ready for next step.",
  "next_action": {...}
}
```

### 4. Submit Checkpoint
```bash
POST /agent/submit-checkpoint
Content-Type: application/json

{
  "session_id": "uuid-xxx",
  "skill": "Python",
  "module_id": 1,
  "answers": [0, 1, 2, 0]
}

Response:
{
  "session_id": "uuid-xxx",
  "checkpoint_result": {
    "passed": true,
    "score": 85,
    "correct_count": 3,
    "total_questions": 4,
    "feedback_items": [...],
    "next_action": "advance",
    "message": "Great job! Module unlocked."
  },
  "skill": "Python",
  "module_id": 1,
  "advance_result": {...}
}
```

### 5. Get Progress
```bash
GET /agent/progress/{session_id}/{skill}

Response:
{
  "session_id": "uuid-xxx",
  "skill": "Python",
  "total_modules": 5,
  "completed_modules": 2,
  "current_module": 3,
  "progress_percentage": 40.0,
  "total_actions": 20,
  "completed_actions": 8,
  "modules": [
    {
      "module_id": 1,
      "name": "Foundations",
      "status": "completed",
      "actions_completed": 4,
      "total_actions": 4
    },
    ...
  ]
}
```

### 6. Final Assessment
```bash
POST /agent/final-assessment/{session_id}/{skill}

Response:
{
  "session_id": "uuid-xxx",
  "assessment": {
    "skill": "Python",
    "assessment_type": "final",
    "total_questions": 10,
    "time_limit_minutes": 30,
    "pass_threshold": 75,
    "questions": [
      {
        "question": "What is a decorator in Python?",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "correct_index": 0,
        "difficulty": "medium",
        "explanation": "..."
      }
    ]
  }
}
```

---

## 🛠️ Database Integration (Optional)

The system works without database for in-memory demo. For production, add:

```sql
CREATE TABLE ai_module_progress (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id uuid REFERENCES ai_agent_sessions(id),
    skill text,
    module_id integer,
    status text CHECK (status IN ('locked', 'active', 'completed')),
    actions_completed integer DEFAULT 0,
    total_actions integer DEFAULT 4,
    created_at timestamp DEFAULT now()
);

CREATE TABLE ai_checkpoint_results (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id uuid REFERENCES ai_agent_sessions(id),
    skill text,
    module_id integer,
    answers jsonb,
    score numeric,
    passed boolean,
    submitted_at timestamp DEFAULT now()
);
```

---

## 🎓 Key Features

### ✅ Agentic Architecture
- Not just recommending, but actively orchestrating the learning process
- Each response is a concrete, actionable next step
- Progress enforcement - modules unlock only after checkpoint passing

### ✅ Real External Resources
- YouTube links with specific videos
- Coursera courses and freeCodeCamp tutorials
- Replit projects, CodePen, LeetCode practice
- Smart fallback to search queries

### ✅ Progress Validation
- Checkpoint quizzes before module unlock
- Detailed feedback on answers
- Score tracking and retry capability
- Confidence level updates

### ✅ User-Friendly UI
- Clear module progression visualization
- Action-by-action guidance
- Real-time progress tracking
- Beautiful, responsive design

---

## 📝 Demo Script

### Presentation (5 minutes)

**Introduction (30s):**
> "PEARL is not just a recommendation engine—it's an agentic learning orchestrator. It breaks your career goal into skills, skills into modules, and modules into concrete actions. Today we'll show how."

**Goal Input (1 min):**
- Go to pearl_frontend.html
- Enter: "Become a Backend Developer"
- Click "Start Journey"
- Show skill breakdown: Python, SQL, REST APIs

**Module Walkthrough (2 min):**
- Click on Python skill
- Show 5 modules breaking down the skill
- Click Module 1 "Foundations"
- Show 4 actions:
  1. Byte: Click link → Opens YouTube "Python in 100 Seconds"
  2. Course: Click link → Opens freeCodeCamp
  3. Taiken: Click link → Opens Replit
  4. Checkpoint: Show quiz structure

**Checkpoint Demo (1 min):**
- Take 2-3 checkpoint questions
- Submit
- Show pass/fail + detailed feedback
- Demonstrate next module unlocking

**Closing:**
> "Notice how PEARL always knows what to do next. It validates mastery before progression. It's not just recommending—it's actively guiding your learning journey."

---

## 🐛 Troubleshooting

### Issue: "Module not found" when starting
**Fix:** Ensure all three service files exist in `services/`

### Issue: API returns 500 error
**Fix:** Check backend console for Gemini API key issues. Fallback systems will activate automatically.

### Issue: Frontend shows "Session not found"
**Fix:** Ensure backend CORS is enabled and API_URL matches (line 360 of HTML)

### Issue: External links not opening
**Fix:** The enhanced_rag database provides real URLs. Fallback search links will activate if resources unavailable.

### Issue: Checkpoint quiz not loading
**Fix:** Ensure JSON parsing is correct. Fallback quiz structure activates on error.

---

## 📚 Next Steps (Post-Hackathon)

### 1. Persistent Database
- Store learning_paths in Supabase tables
- Track user checkpoint attempts and scores
- Resume sessions across devices

### 2. Real-Time Mentoring
- WebSocket support for live mentor feedback
- Peer learning community integration
- Real-time progress notifications

### 3. API Integrations
- YouTube Data API for dynamic video recommendations
- Coursera/edX enrollment APIs
- GitHub integration for project validation

### 4. Internal Tool Integration
- Connect platform's Bytes when available
- Link to internal Taikens and quizzes
- Seamless fallback to external resources

### 5. Analytics Dashboard
- Completion rates by skill
- Average time per module
- Checkpoint pass rates
- User engagement metrics

---

## 🎯 Hackathon Pitch Points

✅ **Agentic, not assistive** - PEARL drives the process  
✅ **Action-first design** - Every response is a concrete task  
✅ **Progress enforcement** - Checkpoints validate before advancement  
✅ **Real external resources** - YouTube, Coursera, Replit (not placeholders)  
✅ **Platform-aware** - Mentions internal tools, routes externally when needed  
✅ **Modular architecture** - Easy to extend and integrate  
✅ **Production-ready patterns** - Clean code, error handling, fallbacks  

---

## 📞 Support

For issues or questions:
1. Check backend logs: `python main.py` output
2. Open browser DevTools: Network tab for API responses
3. Review this guide's troubleshooting section
4. Test individual endpoints with Postman

---

**Built for**: Career readiness at scale  
**Powered by**: Gemini 2.5 Flash, RAG, Agentic orchestration  
**Status**: Ready for demo & integration
