# Angular Frontend to FastAPI Backend Integration Roadmap

## Executive Summary
The Angular frontend (Taiken Story Lab) is a Vite+React+TypeScript application, while the backend is FastAPI+Supabase. This roadmap outlines the changes needed to properly integrate them.

**Current Status:** React frontend, Python FastAPI backend
**Target:** Proper API integration with type-safe calls

---

## Part 1: Backend Analysis

### Current Backend Architecture

#### API Routes (`routes/pearl_routes.py` - 961 lines)
**Endpoints:**
1. `POST /agent/parse-jd` - Parse job description
2. `POST /agent/modules` - Generate learning modules
3. `POST /agent/checkpoint` - Submit checkpoint
4. `POST /agent/module-action` - Complete module action
5. `GET /agent/session/{session_id}` - Get session data
6. `POST /agent/optimize-path` - Optimize learning path (Agent 4)
7. `GET /agent/jobs/recommendations` - Get job recommendations (Adzuna)
8. `GET /agent/content-providers/{skill}` - Get content resources
9. `GET /agent/learning-roadmap/{skill}` - Get learning roadmap

#### Auth Routes (`routes/auth_routes.py` - 484 lines)
**Endpoints:**
1. `POST /auth/signup` - User registration
2. `POST /auth/signin` - User login
3. `POST /auth/signout` - User logout
4. `GET /auth/me` - Get current user
5. `GET /auth/profile/{user_id}` - Get user profile
6. `POST /auth/profile/{user_id}` - Update profile
7. `POST /auth/verify-email` - Email verification

#### Core Services
1. **pearl_agent.py** (610 lines) - 4 Agentic AI tools:
   - Agent 1: JD Parser (extracts skills from job descriptions)
   - Agent 2: Module Decomposer (breaks skills into modules)
   - Agent 3: Checkpoint Generator (creates assessment questions)
   - Agent 4: Learning Path Optimizer

2. **job_retrieval_service.py** (222 lines) - Adzuna API integration
3. **content_provider_service.py** (500+ lines) - YouTube, freeCodeCamp, MIT OCW content
4. **learning_optimizer_agent.py** (180 lines) - Path optimization with fallback

#### Database (Supabase)
**Key Tables:**
- `user_profiles` - User info, streak, followers
- `ai_agent_sessions` - Learning sessions
- `ai_module_progress` - Module completion tracking
- `user_skill_memory` - User skills and confidence scores

#### Configuration
- `config.py` - Settings from .env
- `.env` - API keys (Supabase, Gemini, Adzuna)

---

## Part 2: Frontend Analysis

### Current Frontend Architecture

#### Project Structure
- **Type:** Vite + React + TypeScript
- **Location:** `pearl-agent/` folder
- **Special:** Contains `taiken-story-lab/` (gamified practice component)

#### Key Files
1. **types.ts** - Type definitions
2. **game.service.ts** - State management with Angular signals/computed
3. **app.component.ts** - Main app layout
4. **main-content.component.ts** - Content router
5. **story-view.component.ts** - Story display
6. **practice-session.component.ts** - Practice mode
7. **constants.ts** - Story questions and practice sets

#### Frontend Features
- **Taiken Story Lab** - Interactive coding practice with episodes
- **Game State Management** - Using Angular signals
- **Theme Support** - Dark/light mode
- **Local Storage** - State persistence

#### Frontend Dependencies
```json
{
  "recharts": "^3.7.0",
  "react": "^19.2.3",
  "react-dom": "^19.2.3"
}
```

---

## Part 3: Integration Gap Analysis

### Critical Mismatches

| Aspect | Backend | Frontend | Issue |
|--------|---------|----------|-------|
| **Framework** | FastAPI (Python) | React (TypeScript) | Different languages/frameworks |
| **Authentication** | Supabase Auth endpoints | No auth integration | Frontend missing login/signup UI |
| **API Calls** | Defined endpoints | No HTTP client | Frontend can't call backend |
| **State Management** | Supabase database | LocalStorage only | No persistence to backend |
| **Type Safety** | Python Pydantic | TypeScript interfaces | No API contract matching |
| **Build System** | None (FastAPI runs directly) | Vite + build step | Separate deployments needed |
| **CORS** | Enabled for all origins | Not configured | May have CORS issues |
| **Error Handling** | HTTPException (500) | Basic try-catch | Inconsistent error flow |

### Missing Features in Frontend

1. ❌ **API Service** - No HTTP client to call backend
2. ❌ **Authentication** - No login/signup screens
3. ❌ **Career Goal Input** - Missing job description parser
4. ❌ **Learning Roadmap** - No module display from Agent 2
5. ❌ **Job Integration** - No job recommendations (Agent + Adzuna)
6. ❌ **Content Integration** - No content provider display
7. ❌ **Session Persistence** - All data in localStorage, not backend
8. ❌ **User Dashboard** - No profile or progress tracking

---

## Part 4: Implementation Roadmap

### Phase 1: Backend Preparation (2 hours)
#### Step 1.1: Add HTTP Response Models
**File:** `routes/pearl_routes.py`
- Create standardized response models
- Add OpenAPI documentation
- Ensure all endpoints return consistent JSON

#### Step 1.2: Add CORS Configuration
**File:** `main.py`
- Update CORS to allow Angular frontend origin
- Add proper headers for auth tokens

#### Step 1.3: Add API Key/Token Validation
**File:** `routes/auth_routes.py`
- Ensure token validation is robust
- Add error messages for debugging

---

### Phase 2: Frontend Setup (1 hour)
#### Step 2.1: Create API Service
**New File:** `pearl-agent/src/services/api.service.ts`
- HTTP client configuration
- Base URL setup
- Request/response interceptors
- Error handling

#### Step 2.2: Update Types
**File:** `pearl-agent/types.ts`
- Add API response types
- Match backend Pydantic models
- Add session/module types

#### Step 2.3: Add HTTP Client Library
**Update:** `pearl-agent/package.json`
- Add `axios` or `@angular/common/http`
- Update dependencies

---

### Phase 3: Authentication Flow (2 hours)
#### Step 3.1: Create Auth Service
**New File:** `pearl-agent/src/services/auth.service.ts`
- signup() method
- signin() method
- logout() method
- getToken() method
- Token storage

#### Step 3.2: Create Login Component
**New File:** `pearl-agent/src/components/login.component.ts`
- Email/password form
- Sign-up form
- Error display
- Loading states

#### Step 3.3: Create Auth Guard
**New File:** `pearl-agent/src/guards/auth.guard.ts`
- Protect routes
- Redirect to login if needed
- Token refresh logic

---

### Phase 4: Core Feature Integration (4 hours)
#### Step 4.1: Career Goal Component
**New File:** `pearl-agent/src/components/career-goal.component.ts`
- Text input for job description
- Call `POST /agent/parse-jd` backend endpoint
- Display parsed skills

#### Step 4.2: Learning Roadmap Component
**New File:** `pearl-agent/src/components/learning-roadmap.component.ts`
- Display modules from backend
- Show progress from database
- Call `GET /agent/modules` endpoint

#### Step 4.3: Job Recommendations Component
**Update:** `pearl-agent/src/components/jobs.component.ts`
- Call `GET /agent/jobs/recommendations` endpoint
- Display matching jobs
- Link to Adzuna job pages

#### Step 4.4: Content Integration
**New File:** `pearl-agent/src/components/content-view.component.ts`
- Call `GET /agent/content-providers/{skill}` endpoint
- Display YouTube, freeCodeCamp, MIT OCW content
- Track content completion

---

### Phase 5: State Management (2 hours)
#### Step 5.1: Create Global Store
**New File:** `pearl-agent/src/store/app.store.ts`
- User state
- Learning path state
- Job state
- Session state

#### Step 5.2: Persist to Backend
**File:** `pearl-agent/src/services/session.service.ts`
- Save session to backend
- Load session from backend
- Sync local state with server

#### Step 5.3: Add Auto-Save
**File:** `pearl-agent/src/interceptors/auto-save.interceptor.ts`
- Intercept state changes
- Call backend to persist
- Handle conflicts

---

### Phase 6: Taiken Integration (1 hour)
#### Step 6.1: Backend Questions
**File:** `pearl-agent/src/components/taiken-story-lab/`
- Load practice questions from backend
- Post answers to backend
- Track progress in database

#### Step 6.2: Sync Progress
**File:** `pearl-agent/src/services/practice.service.ts`
- Save checkpoint submissions
- Retrieve user progress
- Calculate scores on backend

---

### Phase 7: Testing & Deployment (2 hours)
#### Step 7.1: API Testing
**File:** `tests/test_integration.py`
- Test all frontend-backend interactions
- Mock frontend requests
- Validate responses

#### Step 7.2: Frontend Testing
**File:** `pearl-agent/src/__tests__/`
- Unit tests for services
- Integration tests for components
- Mock API responses

#### Step 7.3: E2E Testing
- Full user flow testing
- Multi-step workflows
- Error scenarios

---

## Part 5: Detailed Implementation Plan

### Files to Create (14 files)
```
pearl-agent/src/
├── services/
│   ├── api.service.ts          [NEW] HTTP client & config
│   ├── auth.service.ts         [NEW] Authentication logic
│   ├── session.service.ts      [NEW] Session persistence
│   ├── practice.service.ts     [NEW] Practice submission
│   └── job.service.ts          [NEW] Job search
├── components/
│   ├── login.component.ts      [NEW] Auth UI
│   ├── career-goal.component.ts [NEW] JD parser UI
│   ├── learning-roadmap.component.ts [NEW] Modules display
│   ├── jobs.component.ts       [UPDATE] Backend integration
│   ├── content-view.component.ts [NEW] Content display
│   └── dashboard.component.ts  [NEW] Progress tracking
├── guards/
│   └── auth.guard.ts           [NEW] Route protection
├── interceptors/
│   ├── auth.interceptor.ts     [NEW] Token injection
│   └── error.interceptor.ts    [NEW] Error handling
├── store/
│   └── app.store.ts            [NEW] Global state
└── __tests__/
    └── integration.spec.ts     [NEW] API tests
```

### Files to Update (6 files)
```
Backend:
- main.py                        [UPDATE] CORS, docs
- routes/pearl_routes.py        [UPDATE] Response models
- routes/auth_routes.py         [UPDATE] Error messages
- config.py                     [UPDATE] Add frontend URL

Frontend:
- pearl-agent/package.json      [UPDATE] Add axios/http
- pearl-agent/types.ts          [UPDATE] API types
```

---

## Part 6: API Contract Specification

### Authentication Endpoints

#### 1. POST /auth/signup
**Request:**
```typescript
{
  email: string;
  password: string;
  username: string;
}
```

**Response:**
```typescript
{
  success: boolean;
  user: {
    id: string;
    email: string;
    username: string;
  };
  access_token: string;
  requires_verification: boolean;
}
```

#### 2. POST /auth/signin
**Request:**
```typescript
{
  email: string;
  password: string;
}
```

**Response:**
```typescript
{
  success: boolean;
  user: {
    id: string;
    email: string;
    username: string;
  };
  access_token: string;
  requires_onboarding: boolean;
}
```

#### 3. GET /auth/me
**Headers:** `Authorization: Bearer {token}`

**Response:**
```typescript
{
  success: boolean;
  user: {
    id: string;
    email: string;
    username: string;
  };
}
```

---

### Career & Learning Endpoints

#### 1. POST /agent/parse-jd
**Request:**
```typescript
{
  goal: string;           // Job description or career goal
  user_id: string;        // Optional
  jd_text?: string;       // Optional: full JD text
}
```

**Response:**
```typescript
{
  success: boolean;
  session_id: string;
  skills: string[];
  learning_paths: {
    [skill]: {
      modules: Module[];
      estimated_weeks: number;
    };
  };
}
```

#### 2. GET /agent/modules/{skill}
**Response:**
```typescript
{
  skill: string;
  modules: Module[];
  total_hours: number;
}
```

#### 3. POST /agent/module-action
**Request:**
```typescript
{
  session_id: string;
  skill: string;
  module_id: number;
  action_index: number;
  completion_data: Record<string, any>;
}
```

**Response:**
```typescript
{
  success: boolean;
  progress: number;  // 0-100
  next_action?: string;
}
```

#### 4. POST /agent/checkpoint
**Request:**
```typescript
{
  session_id: string;
  skill: string;
  module_id: number;
  answers: number[];  // Selected option indices
}
```

**Response:**
```typescript
{
  success: boolean;
  score: number;     // Percentage correct
  explanation: string;
  passed: boolean;
  rewards: {
    points: number;
    badges?: string[];
  };
}
```

---

### Job & Content Endpoints

#### 1. GET /agent/jobs/recommendations
**Query:** `?skills=Python,SQL&location=Chennai`

**Response:**
```typescript
{
  jobs: Job[];
  total_matches: number;
}

interface Job {
  id: string;
  title: string;
  company: string;
  location: string;
  match_percentage: number;
  matched_skills: string[];
  missing_skills: string[];
  salary_min?: number;
  salary_max?: number;
  url: string;
}
```

#### 2. GET /agent/content-providers/{skill}
**Query:** `?difficulty=intermediate&type=video`

**Response:**
```typescript
{
  skill: string;
  content: ContentResource[];
}

interface ContentResource {
  id: string;
  provider: 'youtube' | 'freecodecamp' | 'mit_ocw';
  title: string;
  url: string;
  duration_minutes: number;
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  tags: string[];
}
```

#### 3. GET /agent/learning-roadmap/{skill}
**Response:**
```typescript
{
  skill: string;
  phases: Phase[];
  total_weeks: number;
}

interface Phase {
  phase_num: number;
  name: string;
  resources: ContentResource[];
  estimated_weeks: number;
  checkpoint: Question[];
}
```

---

## Part 7: Implementation Sequence

### Week 1: Foundation (16 hours)
- **Day 1:** Phase 1 (Backend prep) - 2 hours
- **Day 1:** Phase 2 (Frontend setup) - 1 hour
- **Day 2:** Phase 3 (Auth flow) - 2 hours
- **Day 3:** Phase 4 (Core features part 1) - 4 hours
- **Day 4:** Phase 4 (Core features part 2) - 4 hours
- **Day 5:** Phase 5 (State management) - 2 hours
- **Day 5:** Phase 6 (Taiken) - 1 hour

### Week 2: Integration & Testing (12 hours)
- **Day 1:** Fix integration issues - 3 hours
- **Day 2:** Testing & debugging - 3 hours
- **Day 3:** E2E testing - 3 hours
- **Day 4:** Documentation & deployment prep - 3 hours

---

## Part 8: Success Criteria

### Backend Requirements
- ✅ All endpoints return consistent JSON structure
- ✅ Error handling with proper HTTP status codes
- ✅ CORS configured for frontend origin
- ✅ API documentation (OpenAPI/Swagger)
- ✅ Input validation on all endpoints

### Frontend Requirements
- ✅ API service with centralized configuration
- ✅ Auth flow working (signup, signin, token management)
- ✅ Career goal → Learning roadmap flow
- ✅ Job recommendations displayed
- ✅ Content resources linked
- ✅ State persisted to backend
- ✅ Taiken questions loaded from backend

### Integration Testing
- ✅ Full user signup → learning → practice flow
- ✅ Token refresh working
- ✅ Error recovery
- ✅ Offline → online sync
- ✅ Performance (< 2s for API calls)

---

## Part 9: Risk & Mitigation

### Risks
1. **CORS Issues** - Misconfigured origins
   - *Mitigation:* Test with Postman first

2. **Auth Token Expiry** - Tokens expiring mid-session
   - *Mitigation:* Implement refresh token logic

3. **Database Connection** - Supabase connection issues
   - *Mitigation:* Add retry logic with exponential backoff

4. **Type Mismatches** - Frontend/backend type conflicts
   - *Mitigation:* Use OpenAPI spec generation

5. **Performance** - Slow API calls
   - *Mitigation:* Add caching, pagination, pagination

---

## Part 10: Testing Strategy

### Unit Tests
- API service methods
- Auth service methods
- State management reducers

### Integration Tests
- Auth flow end-to-end
- Career goal parsing
- Module progression
- Job matching

### E2E Tests
- User signup → learning path creation
- Module completion → checkpoint
- Job application flow

---

## Next Steps

1. ✅ **Understand Backend** (COMPLETED)
2. ✅ **Understand Frontend** (COMPLETED)
3. 📋 **Approve Roadmap** (WAITING)
4. 🔧 **Begin Phase 1** (Backend prep)
5. 🔧 **Begin Phase 2** (Frontend setup)
6. ...continue through all phases

---

**Estimated Total Time:** 28 hours (4-5 working days)
**Priority:** High - Critical for MVP
**Owner:** Dev Team
**Status:** Ready for implementation
