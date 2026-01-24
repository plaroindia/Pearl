# 🚀 Backend Services Quick Reference

## ✅ All Services Created and Integrated

### Files Created (7 total)

```
services/
  ✅ skill_gap_service.py      (600 lines) - Skill gap computation
  ✅ practice_service.py        (400 lines) - Practice generation
  ✅ rpg_progression_service.py (500 lines) - RPG mechanics
  ✅ feedback_service.py        (350 lines) - User reviews
  ✅ notification_service.py    (400 lines) - Smart notifications

routes/
  ✅ skill_gap_routes.py        (250 lines) - Skill gap APIs
  ✅ enhanced_routes.py         (350 lines) - Practice/RPG/Feedback/Notifications APIs

main.py - UPDATED with router integration
```

---

## 📊 API Endpoints by Feature

### Skill Gap Analysis (6 endpoints)
```
GET  /api/skill-gap                           Complete analysis
GET  /api/skill-gap/summary                   Quick metrics
GET  /api/skill-gap/skill/{skill_name}        Single skill
GET  /api/skill-gap/recommendations/{skill}   Recommendations
GET  /api/learning-context                    Learning data
GET  /api/skill-evidence/{skill_name}         Evidence detail
```

### Practice Sets (3 endpoints)
```
POST /api/practice/generate                   Generate questions
POST /api/practice/submit                     Submit + Score
GET  /api/practice/history                    Past attempts
```

### RPG System (3 endpoints)
```
GET  /api/rpg/stats                           Get RPG stats
POST /api/rpg/consume-energy                  Use energy
POST /api/rpg/award-xp/{amount}               Award XP
```

### Feedback & Reviews (4 endpoints)
```
POST /api/feedback/submit                     Submit feedback
POST /api/feedback/suggestion                 Submit suggestion
GET  /api/feedback/module/{id}/ratings        Module ratings
GET  /api/feedback/history                    User history
```

### Notifications (3 endpoints)
```
GET  /api/notifications                       Get notifications
POST /api/notifications/{id}/mark-read        Mark as read
GET  /api/notifications/summary               Get summary
```

---

## 🔑 Authentication

**All endpoints require:**
```
Authorization: Bearer <user_token>
```

**Extract user from token:**
```python
def get_user_from_token(authorization: str):
    # Validates Bearer token
    # Returns user object or 401 error
```

---

## 🎮 Gamification Constants

**Energy System:**
- Max: 100
- Regen: 5 per hour
- Costs: watch=5, course=15, practice=10, checkpoint=20, taiken=25, job=30

**XP System:**
- Base per level: 100 XP
- Multiplier: 1.5x (exponential scaling)
- Level-up bonus: +10 max energy

**Notification Types:**
- 🔓 module_unlock (learning)
- ✅ checkpoint_ready (assessment)
- 🎯 skill_mastery (achievement)
- 💼 job_match (opportunities)
- 🔥 streak_reminder (engagement)
- ⚡ energy_restored (rpg)
- 🆙 level_up (rpg)
- 💡 ai_tip (guidance)

---

## 🗄️ Database Tables (Required)

```sql
-- Skill Tracking
user_skill_memory
ai_checkpoint_results
ai_task_results
taiken_progress

-- Practice
practice_attempts

-- RPG
user_rpg_stats
xp_transactions
energy_transactions

-- Feedback
user_feedback
improvement_suggestions

-- Notifications
user_notifications
```

---

## 🧪 Quick Test Examples

### Test Skill Gap
```bash
curl -X GET "http://localhost:8000/api/skill-gap" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Generate Practice
```bash
curl -X POST "http://localhost:8000/api/practice/generate" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "skill": "Python",
    "topic": "Loops",
    "difficulty": "medium",
    "question_count": 5
  }'
```

### Submit Practice
```bash
curl -X POST "http://localhost:8000/api/practice/submit" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "skill": "Python",
    "topic": "Loops",
    "questions": [...],
    "answers": [0, 1, 2, 1],
    "time_taken_seconds": 300
  }'
```

### Get RPG Stats
```bash
curl -X GET "http://localhost:8000/api/rpg/stats" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Submit Feedback
```bash
curl -X POST "http://localhost:8000/api/feedback/submit" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "module_id": "module-123",
    "skill": "Python",
    "rating": 5,
    "feedback_text": "Great module!",
    "tags": ["clear", "practical"]
  }'
```

### Get Notifications
```bash
curl -X GET "http://localhost:8000/api/notifications" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🚀 Starting the Server

```bash
cd c:\Users\hp\StudioProjects\plaro_3\pearl-agent-backend
python main.py
```

**Server runs at:** http://localhost:8000

**Access:**
- API: http://localhost:8000/
- Docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

---

## 📝 Response Format

All endpoints return consistent JSON:

**Success:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Error:**
```json
{
  "detail": "Error message"
}
```

**Status Codes:**
- 200 - OK
- 400 - Bad Request
- 401 - Unauthorized
- 403 - Forbidden
- 404 - Not Found
- 500 - Server Error
- 503 - Service Unavailable

---

## 🔗 Service Imports

Use in your code:

```python
from services.skill_gap_service import skill_gap_service
from services.practice_service import practice_service
from services.rpg_progression_service import rpg_service
from services.feedback_service import feedback_service
from services.notification_service import notification_service
```

---

## ✨ Key Features

✅ Auto-update skills on completion
✅ AI-powered practice generation
✅ RPG progression with energy/XP
✅ User feedback collection
✅ Smart notifications
✅ Evidence aggregation
✅ Readiness scoring
✅ Error handling with fallbacks
✅ Bearer token authentication
✅ Type-hinted throughout

---

**Status:** 🟢 All systems operational
**Ready for:** Frontend integration & testing
