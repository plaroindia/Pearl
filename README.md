# PEARL Agent - Agentic Career Mentor

An AI-powered career mentoring system that breaks down career goals into actionable, module-based learning paths with built-in progress tracking and checkpoint assessments.

## 🎯 Overview

PEARL (Personalized Educational Agentic Roadmap & Learning) Agent transforms abstract career goals into structured, bite-sized learning modules. Instead of overwhelming learners with lengthy roadmaps, PEARL decomposes skills into 4-6 granular modules, each containing specific actions:

- **Byte** 📱 - Quick 2-5 minute explainer videos
- **Course** 📚 - Structured 30-60 minute learning sessions
- **Taiken** ⚡ - Hands-on practice with real projects
- **Checkpoint** ✅ - Knowledge verification quizzes

## ✨ Key Features

### 🧠 Intelligent Module Decomposition
- Breaks complex skills into digestible 2-4 hour modules
- Progressive difficulty scaling based on user confidence
- Clear prerequisites and learning objectives

### 🎓 Multi-Modal Learning Actions
- **Byte Actions**: Quick explainers from curated sources (YouTube, articles)
- **Course Actions**: Comprehensive courses (freeCodeCamp, Coursera, Udemy)
- **Taiken Actions**: Interactive coding environments (Replit, CodePen, Kaggle)
- **Checkpoint Actions**: AI-generated quizzes to validate understanding

### 🔒 Progress Enforcement
- Modules unlock sequentially after checkpoint completion
- 70% pass threshold ensures comprehension before advancement
- Detailed feedback on quiz performance
- Skill confidence tracking

### 🗄️ Persistent Learning State
- All progress saved to Supabase database
- Module completion tracking
- Action-level progress monitoring
- Checkpoint results with detailed analytics

### 🎨 Interactive Frontend
- Clean, modern UI with visual progress indicators
- Real-time action completion tracking
- Dynamic module unlocking
- Comprehensive progress dashboard

## 🏗️ Architecture

```
┌─────────────────┐
│  User Input     │ Career Goal / Job Description
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Gemini AI      │ Parse Goal → Extract Skills
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  PEARL Agent    │ Decompose Skills → Create Modules
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Action Router  │ Generate Learning Actions
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  RAG Service    │ Attach Real External Resources
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Checkpoint     │ Generate & Evaluate Quizzes
│  System         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Supabase DB    │ Persist Learning State
└─────────────────┘
```

## 🛠️ Tech Stack

**Backend:**
- FastAPI - High-performance Python web framework
- Google Gemini AI - Natural language processing and content generation
- Supabase - PostgreSQL database with real-time capabilities
- Pydantic - Data validation and settings management

**Frontend:**
- Vanilla JavaScript - Lightweight, no framework dependencies
- Modern CSS - Responsive design with gradient themes
- HTML5 - Semantic markup

**Deployment:**
- Vercel - Serverless deployment platform
- Environment-based configuration

## 📦 Installation

### Prerequisites
- Python 3.12+
- Supabase account
- Google Gemini API key

### Setup

1. **Clone the repository**
```bash
git clone https://github.com/plaroindia/Pearl.git
cd Pearl
```

2. **Install dependencies**
```bash
pip install -r requirements.txt
```

3. **Configure environment variables**
```bash
cp .env.example .env
# Edit .env with your credentials
```

Required variables:
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_KEY=your_supabase_anon_key
GEMINI_API_KEY=your_gemini_api_key
DEMO_USER_ID=your_user_id
ENVIRONMENT=development
```

4. **Run locally**
```bash
uvicorn api.index:app --reload
```

Visit `http://localhost:8000/docs` for API documentation.

## 🚀 Deployment

### Vercel Deployment

1. **Push to GitHub**
```bash
git push origin main
```

2. **Import to Vercel**
- Connect your GitHub repository
- Framework: Other
- Root Directory: Leave empty
- Vercel auto-detects `api/index.py`

3. **Add Environment Variables**
In Vercel dashboard → Settings → Environment Variables:
- `SUPABASE_URL`
- `SUPABASE_KEY`
- `GEMINI_API_KEY`
- `DEMO_USER_ID`
- `ENVIRONMENT=production`

4. **Deploy**
Vercel automatically deploys on push to main branch.

## 📡 API Endpoints

### Core Endpoints

**Start Learning Journey**
```http
POST /agent/start-journey
{
  "goal": "Become a Backend Developer",
  "jd_text": "Optional job description",
  "user_id": "user123"
}
```

**Get Current Action**
```http
GET /agent/current-action/{session_id}
```

**Complete Action**
```http
POST /agent/complete-action
{
  "session_id": "uuid",
  "skill": "Python",
  "module_id": 1,
  "action_index": 0,
  "completion_data": {"completed": true}
}
```

**Submit Checkpoint**
```http
POST /agent/submit-checkpoint
{
  "session_id": "uuid",
  "skill": "Python",
  "module_id": 1,
  "answers": [0, 2, 1, 3]
}
```

**Get Progress**
```http
GET /agent/progress/{session_id}/{skill}
```

## 🗃️ Database Schema

### Key Tables
- `ai_agent_sessions` - Learning sessions and paths
- `ai_module_progress` - Module completion tracking
- `ai_action_completions` - Individual action records
- `ai_checkpoint_results` - Quiz results and scores
- `user_skill_memory` - User skill confidence levels

## 🎯 Use Cases

1. **Career Transitions**: Break down new role requirements into achievable steps
2. **Skill Gap Analysis**: Identify and address specific knowledge gaps
3. **Structured Learning**: Convert informal learning into organized paths
4. **Progress Validation**: Ensure comprehension through checkpoints
5. **Resource Curation**: Access vetted learning materials

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit changes with clear messages
4. Submit a pull request

## 📄 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

- Google Gemini AI for natural language processing
- Supabase for database infrastructure
- Free learning platforms (freeCodeCamp, YouTube, etc.)

## 📞 Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/plaroindia/Pearl/issues)
- Email: support@plaro.com

---

Built with ❤️ by the PLARO team
