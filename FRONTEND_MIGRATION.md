================================================================================
                     FRONTEND MIGRATION TO REACT/ANGULAR
                           Complete Setup Guide
================================================================================

DATE: January 24, 2026
STATUS: ✅ Migration Complete
FROM: pearl_frontend.html (Static HTML)
TO: pearl-agent/ (React/TypeScript with Vite)

================================================================================
CHANGES MADE TO BACKEND (main.py)
================================================================================

1. FRONTEND SERVING LOCATION
   OLD: Served pearl_frontend.html from root directory
   NEW: Serves index.html from pearl-agent/ folder

2. STATIC FILES MOUNTING
   OLD: Mounted /Pearl folder for assets
   NEW: Mounts / to serve all pearl-agent assets (JS, CSS, images)

3. FALLBACK BEHAVIOR
   If pearl-agent folder not found → Falls back to pearl_frontend.html
   Ensures backward compatibility

4. ROUTER CONFIGURATION
   Still supports all backend API routes:
   - /auth/* (Authentication)
   - /agent/* (Pearl agent routes)
   - /api/* (General APIs)
   - /api/skill-gap/* (Skill gap analysis)
   - /api/practice/* (Practice sets)
   - /api/rpg/* (RPG mechanics)
   - /api/feedback/* (Feedback collection)
   - /api/notifications/* (Notifications)

================================================================================
PEARL-AGENT FOLDER STRUCTURE
================================================================================

pearl-agent/
├── index.html              ← Main entry point (served at /)
├── index.tsx               ← React entry point
├── App.tsx                 ← Main App component
├── index.css               ← Global styles (NEW)
├── .env                    ← Environment variables (NEW)
├── .env.local              ← Local overrides
├── vite.config.ts          ← Vite build configuration
├── tsconfig.json           ← TypeScript configuration
├── package.json            ← Dependencies
├── types.ts                ← TypeScript type definitions
├── metadata.json           ← App metadata
└── components/             ← React components
    ├── Navbar.tsx
    ├── Dashboard.tsx
    ├── Analytics.tsx
    ├── Jobs.tsx
    ├── Profile.tsx
    ├── Roadmap.tsx
    ├── Onboarding.tsx
    └── TaikenStory.tsx

================================================================================
FRONTEND SETUP INSTRUCTIONS
================================================================================

1. INSTALL DEPENDENCIES
   cd pearl-agent
   npm install

2. ENVIRONMENT CONFIGURATION
   Edit .env file:
   - VITE_API_BASE_URL: Backend API URL (default: http://localhost:8000)
   - VITE_SUPABASE_URL: Your Supabase URL
   - VITE_SUPABASE_ANON_KEY: Supabase public key

3. BUILD FOR DEVELOPMENT
   npm run dev
   Runs development server (usually on http://localhost:5173)

4. BUILD FOR PRODUCTION
   npm run build
   Creates optimized production build in dist/

5. PREVIEW BUILD
   npm run preview
   Test production build locally

================================================================================
BACKEND SETUP (UPDATED)
================================================================================

1. START BACKEND SERVER
   cd pearl-agent-backend
   python main.py

2. BACKEND RUNS ON
   http://localhost:8000

3. AVAILABLE ENDPOINTS
   - API Docs: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc
   - Health: http://localhost:8000/health
   - Status: http://localhost:8000/api-status

4. FRONTEND SERVED FROM BACKEND
   When pearl-agent is built, copy dist/ to public/ or use
   StaticFiles mount to serve from pearl-agent/

================================================================================
FRONTEND TECHNOLOGY STACK
================================================================================

Framework: React 19.2.3 with TypeScript
Build Tool: Vite (super fast bundler)
UI Components:
  - Recharts: Charts and analytics visualization
  - Tailwind CSS: Utility-first CSS
  - Custom components in TypeScript

Package.json scripts:
- dev: Start dev server (Vite)
- build: Build for production
- preview: Preview production build
- type-check: TypeScript checking

================================================================================
ENVIRONMENT VARIABLES
================================================================================

VITE_API_BASE_URL
  Description: Backend API URL
  Default: http://localhost:8000
  Usage: Fetch requests to API

VITE_API_TIMEOUT
  Description: API request timeout in milliseconds
  Default: 30000 (30 seconds)

VITE_SUPABASE_URL
  Description: Supabase project URL
  Required for: Authentication, real-time updates

VITE_SUPABASE_ANON_KEY
  Description: Supabase public API key
  Required for: Client-side auth and data access

VITE_ENABLE_NOTIFICATIONS
  Description: Enable notifications feature
  Default: true

VITE_ENABLE_RPG
  Description: Enable RPG gamification
  Default: true

VITE_ENABLE_PRACTICE
  Description: Enable practice sets
  Default: true

VITE_ENABLE_FEEDBACK
  Description: Enable feedback collection
  Default: true

VITE_ENABLE_SKILL_GAP
  Description: Enable skill gap analysis
  Default: true

================================================================================
FRONTEND API INTEGRATION POINTS
================================================================================

All frontend API calls should use:
  Base URL: process.env.VITE_API_BASE_URL || 'http://localhost:8000'

Example API Call:
```typescript
const apiUrl = process.env.VITE_API_BASE_URL;
const response = await fetch(`${apiUrl}/api/skill-gap`, {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});
const data = await response.json();
```

Available API Endpoints (see BACKEND_DOCUMENTATION.txt):
- GET /api/skill-gap
- POST /api/practice/generate
- POST /api/practice/submit
- GET /api/rpg/stats
- POST /api/feedback/submit
- GET /api/notifications

================================================================================
AUTHENTICATION FLOW
================================================================================

1. Frontend handles auth via Supabase
2. On login, get Bearer token
3. Include in all API requests: Authorization: Bearer <token>
4. Backend routes validate token and extract user_id
5. Token added to request headers automatically by frontend

Token Storage:
- localStorage: persist token across sessions
- sessionStorage: session-only token

Token Refresh:
- Implement Supabase token refresh logic
- Refresh token automatically before expiration
- Handle 401 errors by refreshing and retrying

================================================================================
COMPONENT COMMUNICATION
================================================================================

Components available in pearl-agent/components/:
- Navbar.tsx: Main navigation (horizontal)
- Dashboard.tsx: Main dashboard view
- Analytics.tsx: Analytics and progress
- Jobs.tsx: Job recommendations
- Profile.tsx: User profile
- Roadmap.tsx: Learning roadmap
- Onboarding.tsx: Onboarding flow
- TaikenStory.tsx: Story-based learning

State Management:
- Local component state (useState)
- Context API for global state (if needed)
- Props drilling for parent-child communication

API Integration:
- Fetch data in useEffect hooks
- Store in component state
- Update UI when data changes
- Handle loading and error states

================================================================================
GLOBAL STYLES INCLUDED
================================================================================

index.css provides:
✅ CSS Variables (colors, fonts)
✅ Typography styles (h1-h6, p)
✅ Button styles (.btn, .btn-primary, .btn-secondary)
✅ Card styles (.card)
✅ Form styles (input, textarea, select)
✅ Animations (fadeIn, slideInUp, pulse)
✅ Utility classes (flex, grid, spacing)
✅ Dark mode support
✅ Responsive design
✅ Custom scrollbar styling

================================================================================
DEVELOPMENT WORKFLOW
================================================================================

PHASE 1: Setup
✅ Install dependencies: npm install
✅ Configure environment: edit .env
✅ Verify backend running: http://localhost:8000

PHASE 2: Development
✅ Start dev server: npm run dev
✅ Frontend at: http://localhost:5173 (or Vite default)
✅ Backend at: http://localhost:8000
✅ API Docs at: http://localhost:8000/docs

PHASE 3: Testing
✅ Test API endpoints
✅ Test authentication flow
✅ Test skill gap analysis
✅ Test practice generation
✅ Test notifications

PHASE 4: Build
✅ Run build: npm run build
✅ Creates dist/ folder with optimized assets
✅ Ready for deployment

PHASE 5: Deployment (Future)
✅ Copy dist/ contents to server
✅ Configure backend to serve from dist/
✅ Deploy to production environment

================================================================================
MIGRATION SUMMARY
================================================================================

Before:
- Frontend: Static pearl_frontend.html
- Served by: main.py FileResponse
- Structure: Single HTML file with inline CSS/JS

After:
- Frontend: React TypeScript with Vite
- Served by: Vite dev server or static mounting
- Structure: Component-based architecture
- Benefits:
  ✅ Modern framework
  ✅ Hot module replacement (HMR)
  ✅ Component reusability
  ✅ Better tooling
  ✅ Easier maintenance
  ✅ Better performance
  ✅ TypeScript support
  ✅ Scalability

Backend Changes:
✅ Updated static file serving
✅ Added fallback for backward compatibility
✅ No changes to API routes
✅ All endpoints still functional
✅ Bearer token auth still required

Next Steps:
1. Install frontend dependencies: npm install
2. Configure .env with API URL
3. Start development server: npm run dev
4. Start backend: python main.py
5. Test integration at http://localhost:5173

================================================================================
TROUBLESHOOTING
================================================================================

Issue: Cannot find module 'react' or similar
Solution: Run npm install in pearl-agent/

Issue: API calls return 401 Unauthorized
Solution: Check Bearer token is valid and included in headers

Issue: Pearl-agent folder not found
Solution: Ensure folder exists and path is correct
  Backend falls back to pearl_frontend.html if not found

Issue: CSS not loading
Solution: Verify index.css exists in pearl-agent/ folder

Issue: Cross-origin errors
Solution: CORS is enabled on backend for all origins
  Check browser console for specific error

Issue: Build fails
Solution: Check tsconfig.json and vite.config.ts
  Run npm run type-check to validate TypeScript

================================================================================
ADDITIONAL RESOURCES
================================================================================

React: https://react.dev
Vite: https://vitejs.dev
TypeScript: https://www.typescriptlang.org
Tailwind CSS: https://tailwindcss.com
Recharts: https://recharts.org
Supabase: https://supabase.com

Backend API Documentation: BACKEND_DOCUMENTATION.txt
Quick API Reference: API_QUICK_REFERENCE.txt

================================================================================
STATUS: ✅ READY FOR DEVELOPMENT
================================================================================

Frontend Migration Complete
Backend Updated
All API Routes Functional
Ready to Start Coding

Start with:
1. cd pearl-agent && npm install
2. Configure .env
3. npm run dev
4. python main.py (in backend folder)
5. Visit http://localhost:5173
