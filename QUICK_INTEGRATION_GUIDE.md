# Quick Integration Reference

## Current Status

✅ **Phase 1-2 COMPLETE** - Backend prep + Frontend API layer ready

## What's Ready to Use

### 1. API Service
```typescript
import { apiService } from '@/services/api.service';

// Authentication
await apiService.signup(email, password, username);
await apiService.signin(email, password);
await apiService.signout();
await apiService.getCurrentUser();

// Learning
await apiService.parseCareerGoal(goal, jdText);
await apiService.getModules(skill, difficulty);
await apiService.submitModuleAction(sessionId, skill, moduleId, actionIndex, data);
await apiService.submitCheckpoint(sessionId, skill, moduleId, answers);

// Jobs & Content
await apiService.getJobRecommendations(skills, location);
await apiService.getContentForSkill(skill, difficulty, type);
await apiService.getLearningRoadmap(skill, secondarySkills);
```

### 2. Auth Service
```typescript
import { authService } from '@/services/auth.service';

// Methods
await authService.signup(email, password, username);
await authService.signin(email, password);
await authService.signout();
await authService.loadCurrentUser();
await authService.updateProfile(updates);

// State
const state = authService.getState();
// { user, isAuthenticated, isLoading, error, token }

// Subscribe to changes
const unsubscribe = authService.subscribe((newState) => {
  console.log('Auth state changed:', newState);
});
```

### 3. Learning Service
```typescript
import { learningService } from '@/services/learning.service';

// Methods
await learningService.startCareerJourney(goal, jobDescription);
await learningService.loadModulesForSkill(skill, difficulty);
await learningService.submitModuleAction(moduleId, actionIndex, data);
await learningService.submitCheckpoint(moduleId, answers);
learningService.selectSkill(skill);
learningService.selectModule(module);

// State
const state = learningService.getState();
// { careerGoal, sessionId, skillsIdentified, modules, progress, ... }

// Subscribe to changes
const unsubscribe = learningService.subscribe((newState) => {
  console.log('Learning state changed:', newState);
});

// Utilities
learningService.getSkillProgress(skill);        // 0-100
learningService.getCompletedSkills();           // string[]
```

## Backend Endpoints

### Authentication
- `POST /auth/signup` - Register user
- `POST /auth/signin` - Login user
- `POST /auth/signout` - Logout user
- `GET /auth/me` - Get current user
- `GET /auth/profile/{user_id}` - Get user profile
- `POST /auth/profile/{user_id}` - Update profile

### Learning Paths
- `POST /agent/parse-jd` - Parse career goal (Agent 1)
- `GET /agent/modules/{skill}` - Get learning modules
- `GET /agent/session/{session_id}` - Get session data
- `POST /agent/module-action` - Complete module action
- `POST /agent/checkpoint` - Submit checkpoint
- `POST /agent/optimize-path` - Optimize learning path (Agent 4)

### Jobs & Content
- `GET /agent/jobs/recommendations` - Get job recommendations
- `GET /agent/content-providers/{skill}` - Get learning content
- `GET /agent/learning-roadmap/{skill}` - Get structured roadmap

## Running the Project

### Backend
```bash
cd pearl-agent-backend
python main.py
# Runs on http://localhost:8000
# API docs: http://localhost:8000/docs
```

### Frontend
```bash
cd pearl-agent-backend/pearl-agent
npm install  # Install dependencies including axios
npm run dev
# Runs on http://localhost:3000 or 5173
```

## Key Files

### Backend
- `main.py` - FastAPI app with CORS
- `routes/auth_routes.py` - Auth endpoints
- `routes/pearl_routes.py` - Learning endpoints
- `routes/response_models.py` - Standard responses
- `services/pearl_agent.py` - 4 AI agents
- `config.py` - Configuration

### Frontend
- `src/services/api.service.ts` - HTTP client
- `src/services/auth.service.ts` - Auth logic
- `src/services/learning.service.ts` - Learning logic
- `taiken-story-lab/` - Gamified practice component

## Error Handling

All services handle errors gracefully:

```typescript
try {
  const success = await authService.signin(email, password);
  if (success) {
    // User logged in
  } else {
    const error = authService.getState().error;
    console.error(error);  // "Invalid email or password"
  }
} catch (error) {
  console.error('Network error:', error);
}
```

## Data Persistence

### Frontend (localStorage)
- `pearl_auth_token` - JWT access token
- `pearl_refresh_token` - Refresh token
- `pearl_auth_state` - Auth state
- `pearl_learning_state` - Learning state

### Backend (Supabase)
- `user_profiles` - User data
- `ai_agent_sessions` - Learning sessions
- `ai_module_progress` - Module progress
- `user_skill_memory` - User skills

## Environment Variables

### Frontend (`.env` in `pearl-agent/`)
```
VITE_API_URL=http://localhost:8000
```

### Backend (`.env` in `pearl-agent-backend/`)
```
SUPABASE_URL=...
SUPABASE_KEY=...
GEMINI_API_KEY=...
ADZUNA_APP_ID=...
ADZUNA_APP_KEY=...
DEMO_USER_ID=...
ENVIRONMENT=development
```

## What's Next: Phase 3

### To Build:
1. Login component
2. Signup component
3. Auth guard
4. User dropdown

### Time: 2 hours
### Files: 4 new component files

---

## Common Patterns

### Using Auth in Components
```typescript
import { authService } from '@/services/auth.service';
import { useEffect, useState } from 'react';

export function MyComponent() {
  const [authState, setAuthState] = useState(authService.getState());

  useEffect(() => {
    const unsubscribe = authService.subscribe((newState) => {
      setAuthState(newState);
    });
    return unsubscribe;
  }, []);

  if (!authState.isAuthenticated) {
    return <div>Please log in</div>;
  }

  return <div>Welcome, {authState.user?.username}</div>;
}
```

### Using Learning Service
```typescript
import { learningService } from '@/services/learning.service';
import { useEffect, useState } from 'react';

export function LearningComponent() {
  const [state, setState] = useState(learningService.getState());

  useEffect(() => {
    return learningService.subscribe(setState);
  }, []);

  return (
    <div>
      <p>Goal: {state.careerGoal}</p>
      <p>Skills: {state.skillsIdentified.length}</p>
      <p>Progress: {state.progress[state.currentSkill]}%</p>
    </div>
  );
}
```

---

**Ready to proceed with Phase 3?** 
Next: Build authentication UI components (Login, Signup, Auth Guard)
