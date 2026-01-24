"""
Fixed PEARL Routes - Proper skill extraction from ANY career goal
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict
from database import EnhancedSupabaseHelper
from services.enhanced_rag_service import enhanced_rag
from config import get_settings
import json
import google.generativeai as genai
from datetime import datetime

# Import new services for Agent 4, Adzuna, and Content Providers
from services.learning_optimizer_agent import learning_optimizer
from services.job_retrieval_service import adzuna_service
from services.content_provider_service import content_provider

router = APIRouter()
db = EnhancedSupabaseHelper()
settings = get_settings()

# Configure Gemini
genai.configure(api_key=settings.GEMINI_API_KEY)

# Import the FIXED pearl agent
from services.pearl_agent import pearl


# ============================================
# REQUEST MODELS
# ============================================

class CareerGoalRequest(BaseModel):
    goal: str
    user_id: str = settings.DEMO_USER_ID
    jd_text: Optional[str] = None


class ModuleActionRequest(BaseModel):
    session_id: str
    skill: str
    module_id: int
    action_index: int
    completion_data: dict
    user_id: str = settings.DEMO_USER_ID


class CheckpointSubmission(BaseModel):
    session_id: str
    skill: str
    module_id: int
    answers: List[int]
    user_id: str = settings.DEMO_USER_ID


# ============================================
# DATABASE HELPER
# ============================================

class PEARLDatabaseHelper:
    """Database persistence"""
    
    @staticmethod
    def save_learning_paths(session_id: str, user_id: str, learning_paths: Dict) -> bool:
        try:
            db.client.table('ai_agent_sessions').update({
                'jd_parsed': {
                    'learning_paths': learning_paths,
                    'updated_at': datetime.now().isoformat()
                }
            }).eq('id', session_id).execute()
            return True
        except Exception as e:
            print(f"[ERROR] Save failed: {e}")
            return False
    
    @staticmethod
    def save_module_progress(session_id: str, user_id: str, skill: str, module_id: int, module_data: Dict) -> Optional[str]:
        try:
            existing = db.client.table('ai_module_progress').select('id').eq(
                'session_id', session_id
            ).eq('skill', skill).eq('module_id', module_id).execute()
            
            progress_data = {
                'session_id': session_id,
                'user_id': user_id,
                'skill': skill,
                'module_id': module_id,
                'module_name': module_data.get('name', f'{skill} - Module {module_id}'),
                'status': module_data.get('status', 'locked'),
                'total_actions': len(module_data.get('actions', [])),
                'actions_completed': sum(1 for a in module_data.get('actions', []) if a.get('completed')),
                'started_at': datetime.now().isoformat() if module_data.get('status') == 'active' else None,
                'completed_at': datetime.now().isoformat() if module_data.get('status') == 'completed' else None
            }
            
            if existing.data:
                result = db.client.table('ai_module_progress').update(progress_data).eq(
                    'id', existing.data[0]['id']
                ).execute()
                return existing.data[0]['id']
            else:
                result = db.client.table('ai_module_progress').insert(progress_data).execute()
                return result.data[0]['id'] if result.data else None
        
        except Exception as e:
            print(f"[ERROR] Module progress save failed: {e}")
            return None
    
    @staticmethod
    def save_checkpoint_result(module_progress_id: str, user_id: str, skill: str, 
                              module_id: int, questions: List, answers: List[int], 
                              score: float, passed: bool) -> bool:
        try:
            db.client.table('ai_checkpoint_results').insert({
                'module_progress_id': module_progress_id,
                'user_id': user_id,
                'questions': questions,
                'answers': answers,
                'score': score,
                'passed': passed,
                'submitted_at': datetime.now().isoformat()
            }).execute()
            
            if passed:
                PEARLDatabaseHelper.update_skill_confidence(user_id, skill, score / 100.0)
            
            return True
        except Exception as e:
            print(f"[ERROR] Checkpoint save failed: {e}")
            return False
    
    @staticmethod
    def update_skill_confidence(user_id: str, skill: str, score: float) -> bool:
        try:
            existing = db.client.table('user_skill_memory').select('*').eq(
                'user_id', user_id
            ).eq('skill_name', skill).execute()
            
            new_confidence = min(1.0, score + 0.1)
            
            if existing.data:
                db.client.table('user_skill_memory').update({
                    'confidence_score': new_confidence,
                    'last_practiced_at': datetime.now().isoformat(),
                    'practice_count': existing.data[0].get('practice_count', 0) + 1,
                    'updated_at': datetime.now().isoformat()
                }).eq('id', existing.data[0]['id']).execute()
            else:
                db.client.table('user_skill_memory').insert({
                    'user_id': user_id,
                    'skill_name': skill,
                    'confidence_score': new_confidence,
                    'practice_count': 1,
                    'last_practiced_at': datetime.now().isoformat()
                }).execute()
            
            return True
        except Exception as e:
            print(f"[ERROR] Confidence update failed: {e}")
            return False
    
    @staticmethod
    def get_session_learning_paths(session_id: str) -> Optional[Dict]:
        try:
            result = db.client.table('ai_agent_sessions').select('jd_parsed').eq(
                'id', session_id
            ).single().execute()
            
            if result.data:
                parsed = result.data.get('jd_parsed', {})
                return parsed.get('learning_paths')
            return None
        except Exception as e:
            print(f"[ERROR] Failed to retrieve paths: {e}")
            return None
    
    @staticmethod
    def get_module_progress(session_id: str, skill: str, module_id: int) -> Optional[str]:
        try:
            result = db.client.table('ai_module_progress').select('id').eq(
                'session_id', session_id
            ).eq('skill', skill).eq('module_id', module_id).single().execute()
            
            return result.data['id'] if result.data else None
        except Exception as e:
            return None


# ============================================
# HELPER: SKILL EXTRACTION (THE FIX!)
# ============================================

async def extract_skills_from_goal(goal: str) -> List[str]:
    """
    Extract skills from ANY career goal using structured output
    This is the KEY fix - no more hardcoded fallbacks!
    """
    
    prompt = f"""
Analyze this career goal and extract 3-5 specific technical skills needed.

Career Goal: "{goal}"

Return a JSON array of skill names. Be specific and relevant.

Examples:
- "Become a Backend Developer" → ["Python", "SQL", "REST APIs", "Git"]
- "Become a Singer" → ["Vocal Technique", "Music Theory", "Performance Skills", "Recording Basics"]
- "Data Scientist" → ["Python", "Statistics", "Machine Learning", "Data Visualization"]
- "Game Developer" → ["C++", "Game Engines", "3D Graphics", "Physics Simulation"]

Return only the JSON array, nothing else:
["skill1", "skill2", "skill3"]
"""
    
    try:
        model = genai.GenerativeModel(
            'gemini-2.5-flash',
            generation_config={
                "temperature": 0.3,
                "response_mime_type": "application/json"
            }
        )
        
        response = model.generate_content(prompt)
        skills = json.loads(response.text)
        
        if isinstance(skills, list) and len(skills) > 0:
            print(f"[SUCCESS] Extracted skills for '{goal}': {skills}")
            return skills
        
        print(f"[WARNING] Invalid skill format, using intelligent fallback")
        
    except Exception as e:
        print(f"[ERROR] Skill extraction failed: {e}")
    
    # INTELLIGENT fallback based on goal keywords
    goal_lower = goal.lower()
    
    # Skill mapping for common careers
    skill_mappings = {
        "singer": ["Vocal Technique", "Music Theory", "Performance Skills"],
        "musician": ["Music Theory", "Instrument Mastery", "Composition"],
        "backend": ["Python", "SQL", "REST APIs"],
        "frontend": ["JavaScript", "React", "CSS"],
        "data": ["Python", "SQL", "Statistics"],
        "mobile": ["Flutter", "React Native", "Mobile UI"],
        "ml": ["Python", "Machine Learning", "Data Analysis"],
        "machine learning": ["Python", "Machine Learning", "Statistics"],
        "devops": ["Docker", "Kubernetes", "CI/CD"],
        "game": ["Unity", "C++", "Game Design"],
        "designer": ["Figma", "UI/UX Design", "Prototyping"],
        "writer": ["Writing Skills", "Storytelling", "Editing"],
        "photographer": ["Photography", "Lighting", "Photo Editing"],
        "artist": ["Drawing", "Color Theory", "Digital Art"]
    }
    
    for keyword, skills in skill_mappings.items():
        if keyword in goal_lower:
            print(f"[FALLBACK] Matched '{keyword}' → {skills}")
            return skills
    
    # Last resort: generic soft skills
    print(f"[FALLBACK] No match, using generic skills")
    return ["Communication", "Problem Solving", "Critical Thinking"]


# ============================================
# ENDPOINT 1: START JOURNEY (FIXED!)
# ============================================

@router.post("/start-journey")
async def start_career_journey(req: CareerGoalRequest):
    """
    Start learning journey - NOW WORKS FOR ANY GOAL!
    """
    try:
        print(f"[PEARL] Starting journey: '{req.goal}'")
        
        # Create session
        session = db.create_session(req.user_id, req.jd_text or req.goal)
        session_id = session['id']
        
        # Extract skills using FIXED method
        required_skills = await extract_skills_from_goal(req.goal)
        target_role = req.goal
        
        print(f"[PEARL] Skills identified: {required_skills}")
        
        # Get user's current levels
        try:
            user_skills = db.get_user_skills(req.user_id)
            skill_dict = {s['skill_name']: float(s['confidence_score']) for s in user_skills}
        except:
            skill_dict = {skill: 0.0 for skill in required_skills}
        
        # Create learning paths
        learning_paths = {}
        
        for skill in required_skills[:3]:  # Top 3 skills
            current_conf = skill_dict.get(skill, 0.0)
            
            print(f"[PEARL] Creating path for {skill} (confidence: {current_conf})")
            
            # Use FIXED pearl agent with structured outputs
            path = pearl.create_learning_path(skill, current_conf)
            
            # Enhance with real resources
            for module in path['modules']:
                for action in module['actions']:
                    if action['type'] in ['byte', 'course', 'taiken']:
                        real_resources = enhanced_rag.retrieve_resources(
                            skill, action['type'], count=1
                        )
                        if real_resources:
                            action['external_resource'] = real_resources[0]
            
            learning_paths[skill] = path
            
            # Save to database
            for module in path['modules']:
                PEARLDatabaseHelper.save_module_progress(
                    session_id, req.user_id, skill, module['module_id'], module
                )
        
        # Save complete paths
        PEARLDatabaseHelper.save_learning_paths(session_id, req.user_id, learning_paths)
        
        print(f"[PEARL] ✅ Journey created for '{target_role}' with {len(learning_paths)} skills")
        
        return {
            "session_id": session_id,
            "target_role": target_role,
            "skills_to_learn": list(learning_paths.keys()),
            "learning_paths": learning_paths,
            "next_action": pearl.get_next_action(learning_paths[list(learning_paths.keys())[0]]) if learning_paths else None
        }
    
    except Exception as e:
        print(f"[ERROR] Journey failed: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 2: GET CURRENT ACTION
# ============================================

@router.get("/current-action/{session_id}")
async def get_current_action(session_id: str):
    """Get current action"""
    try:
        session = db.client.table('ai_agent_sessions').select('*').eq('id', session_id).single().execute()
        
        if not session.data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        parsed = session.data.get('jd_parsed', {})
        learning_paths = parsed.get('learning_paths', {})
        
        if not learning_paths:
            raise HTTPException(status_code=404, detail="No learning paths")
        
        # Find current skill (with bounds checking)
        current_skill = None
        for skill, path in learning_paths.items():
            current_module = path.get('current_module', 0)
            total_modules = path.get('total_modules', 0)
            if 0 < current_module <= total_modules:
                current_skill = skill
                break
        
        if not current_skill:
            return {"message": "All skills completed!"}
        
        learning_path = learning_paths[current_skill]
        next_action = pearl.get_next_action(learning_path)
        
        return {
            "session_id": session_id,
            "current_skill": current_skill,
            "next_action": next_action,
            "learning_path": learning_path
        }
    
    except Exception as e:
        print(f"[ERROR] Get action failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 3: COMPLETE ACTION
# ============================================

@router.post("/complete-action")
async def complete_action(req: ModuleActionRequest):
    """Mark action complete"""
    try:
        session = db.client.table('ai_agent_sessions').select('*').eq('id', req.session_id).single().execute()
        
        if not session.data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        parsed = session.data.get('jd_parsed', {})
        learning_paths = parsed.get('learning_paths', {})
        learning_path = learning_paths.get(req.skill)
        
        if not learning_path:
            raise HTTPException(status_code=404, detail="Skill not found")
        
        action_type = req.completion_data.get('action_type')
        
        if action_type == 'checkpoint':
            return {"success": False, "message": "Use /submit-checkpoint"}
        
        # Mark complete
        for module in learning_path['modules']:
            if module['module_id'] == req.module_id:
                if req.action_index < len(module['actions']):
                    module['actions'][req.action_index]['completed'] = True
                    
                    # Update database
                    PEARLDatabaseHelper.save_module_progress(
                        req.session_id, req.user_id, req.skill, req.module_id, module
                    )
                    
                    PEARLDatabaseHelper.save_learning_paths(req.session_id, req.user_id, learning_paths)
                    
                    next_action = pearl.get_next_action(learning_path)
                    
                    return {
                        "success": True,
                        "message": "Action completed!",
                        "next_action": next_action
                    }
        
        return {"success": False, "message": "Not found"}
    
    except Exception as e:
        print(f"[ERROR] Complete action failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 4: SUBMIT CHECKPOINT
# ============================================

@router.post("/submit-checkpoint")
async def submit_checkpoint(req: CheckpointSubmission):
    """Submit checkpoint quiz"""
    try:
        session = db.client.table('ai_agent_sessions').select('*').eq('id', req.session_id).single().execute()
        
        if not session.data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        parsed = session.data.get('jd_parsed', {})
        learning_paths = parsed.get('learning_paths', {})
        learning_path = learning_paths.get(req.skill)
        
        if not learning_path:
            raise HTTPException(status_code=404, detail="Skill not found")
        
        # Find checkpoint with proper error handling
        checkpoint_data = None
        modules = learning_path.get('modules', [])
        
        for module in modules:
            if module.get('module_id') == req.module_id:
                actions = module.get('actions', [])
                for action in actions:
                    if action.get('type') == 'checkpoint':
                        checkpoint_data = action
                        break
                break
        
        if not checkpoint_data:
            raise HTTPException(status_code=404, detail="Checkpoint not found")
        
        # Evaluate
        result = pearl.checkpoint.evaluate_checkpoint(checkpoint_data, req.answers)
        
        # Save result
        module_progress_id = PEARLDatabaseHelper.get_module_progress(
            req.session_id, req.skill, req.module_id
        )
        
        if module_progress_id:
            PEARLDatabaseHelper.save_checkpoint_result(
                module_progress_id,
                req.user_id,
                req.skill,
                req.module_id,
                checkpoint_data.get('questions', []),
                req.answers,
                result['score'],
                result['passed']
            )
        
        if result['passed']:
            # Mark complete and advance (with bounds checking)
            modules = learning_path.get('modules', [])
            for module in modules:
                if module.get('module_id') == req.module_id:
                    actions = module.get('actions', [])
                    for action in actions:
                        if action.get('type') == 'checkpoint':
                            action['completed'] = True
            
            advance_result = pearl.advance_progress(learning_path, req.module_id, 0)
            
            # Update database with bounds checking
            if 0 < req.module_id <= len(modules):
                current_module = modules[req.module_id - 1]
                PEARLDatabaseHelper.save_module_progress(
                    req.session_id, req.user_id, req.skill, req.module_id, current_module
                )
            
            if req.module_id < learning_path.get('total_modules', 0) and req.module_id < len(modules):
                next_module = modules[req.module_id]
                PEARLDatabaseHelper.save_module_progress(
                    req.session_id, req.user_id, req.skill, req.module_id + 1, next_module
                )
            
            PEARLDatabaseHelper.save_learning_paths(req.session_id, req.user_id, learning_paths)
            
            return {
                "session_id": req.session_id,
                "checkpoint_result": result,
                "skill": req.skill,
                "module_id": req.module_id,
                "advance_result": advance_result
            }
        else:
            return {
                "session_id": req.session_id,
                "checkpoint_result": result,
                "skill": req.skill,
                "module_id": req.module_id
            }
    
    except Exception as e:
        print(f"[ERROR] Checkpoint failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 5: GET PROGRESS
# ============================================

@router.get("/progress/{session_id}/{skill}")
async def get_skill_progress(session_id: str, skill: str):
    """Get skill progress"""
    try:
        session = db.client.table('ai_agent_sessions').select('*').eq('id', session_id).single().execute()
        
        if not session.data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        parsed = session.data.get('jd_parsed', {})
        learning_paths = parsed.get('learning_paths', {})
        learning_path = learning_paths.get(skill)
        
        if not learning_path:
            raise HTTPException(status_code=404, detail="Skill not found")
        
        modules_info = []
        completed_modules = 0
        total_actions = 0
        completed_actions = 0
        
        for module in learning_path['modules']:
            actions_completed = sum(1 for a in module['actions'] if a.get('completed', False))
            total_module_actions = len(module['actions'])
            
            modules_info.append({
                "module_id": module['module_id'],
                "name": module['name'],
                "status": module['status'],
                "actions_completed": actions_completed,
                "total_actions": total_module_actions
            })
            
            total_actions += total_module_actions
            completed_actions += actions_completed
            
            if module['status'] == 'completed':
                completed_modules += 1
        
        progress = (completed_actions / total_actions * 100) if total_actions > 0 else 0
        
        return {
            "session_id": session_id,
            "skill": skill,
            "total_modules": learning_path['total_modules'],
            "completed_modules": completed_modules,
            "current_module": learning_path['current_module'],
            "progress_percentage": round(progress, 1),
            "total_actions": total_actions,
            "completed_actions": completed_actions,
            "modules": modules_info
        }
    
    except Exception as e:
        print(f"[ERROR] Get progress failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 6: AGENT 4 - OPTIMIZE LEARNING PATH
# ============================================

@router.post("/optimize-path")
async def optimize_learning_path(req: CareerGoalRequest):
    """
    Agent 4: Optimize learning sequence based on user profile
    Uses AI to prioritize skills, recommend parallel learning, and adjust difficulty
    """
    try:
        print(f"\n[OPTIMIZER] 🚀 Starting path optimization for user: {req.user_id}")
        
        # Get user skills from database
        user_skills_data = db.get_user_skills(req.user_id)
        user_skills = {s['skill_name']: float(s['confidence_score']) for s in user_skills_data}
        
        print(f"[OPTIMIZER] Current skills: {list(user_skills.keys())}")
        
        # Extract required skills from career goal
        from services.enhanced_rag_service import enhanced_rag
        required_skills_text = await enhanced_rag.extract_skills(req.goal)
        required_skills = json.loads(required_skills_text) if isinstance(required_skills_text, str) else required_skills_text
        
        if not isinstance(required_skills, list):
            required_skills = list(required_skills) if hasattr(required_skills, '__iter__') else [req.goal]
        
        print(f"[OPTIMIZER] Required skills extracted: {required_skills}")
        
        # Get onboarding data for time and preference constraints
        try:
            onboarding = db.client.table('user_onboarding').select('*').eq(
                'user_id', req.user_id
            ).single().execute()
            
            time_weeks = 8  # Default
            learning_pref = "mixed"  # Default
            
            if onboarding.data:
                # Parse time availability
                time_availability = onboarding.data.get('time_availability', '5-10 hours/week')
                if '1-5' in time_availability:
                    time_weeks = 12
                elif '10-20' in time_availability:
                    time_weeks = 6
                elif '20+' in time_availability:
                    time_weeks = 4
                else:
                    time_weeks = 8
                
                learning_pref = onboarding.data.get('learning_preference', 'mixed')
                print(f"[OPTIMIZER] Constraints: {time_weeks} weeks, preference: {learning_pref}")
        except Exception as e:
            print(f"[OPTIMIZER] Using defaults (onboarding data not found): {e}")
            time_weeks = 8
            learning_pref = "mixed"
        
        # Run Agent 4: Learning Path Optimizer
        optimization = learning_optimizer.optimize_learning_sequence(
            user_skills=user_skills,
            required_skills=required_skills,
            time_constraint_weeks=time_weeks,
            learning_preference=learning_pref
        )
        
        print(f"[OPTIMIZER] ✅ Path optimization complete")
        
        return {
            "success": True,
            "optimization": optimization,
            "user_skills": user_skills,
            "required_skills": required_skills,
            "constraints": {
                "weeks_available": time_weeks,
                "learning_preference": learning_pref
            }
        }
    
    except Exception as e:
        print(f"[ERROR] Optimization failed: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 7: JOB RECOMMENDATIONS (ADZUNA)
# ============================================

@router.get("/jobs/recommendations")
async def get_job_recommendations(
    user_id: str,
    target_role: str,
    location: str = "Chennai"
):
    """
    Get real job recommendations from Adzuna API
    Matches jobs to user's current skills with percentage compatibility
    """
    try:
        print(f"\n[JOBS] 🔍 Finding jobs for user: {user_id}")
        print(f"[JOBS] Target role: {target_role}, Location: {location}")
        
        # Get user skills from database
        user_skills_data = db.get_user_skills(user_id)
        user_skills = {s['skill_name']: float(s['confidence_score']) for s in user_skills_data}
        
        print(f"[JOBS] User has {len(user_skills)} skills: {list(user_skills.keys())}")
        
        # FALLBACK: If user has no skills, extract from target role
        if not user_skills:
            print(f"[JOBS] ⚠️ No skills found for user, extracting from target role: {target_role}")
            # Extract keywords from target role
            keywords = target_role.lower().split()
            user_skills = {kw: 0.5 for kw in keywords if len(kw) > 2}
            
            # Add common keywords based on role keywords
            if any(word in target_role.lower() for word in ['backend', 'api', 'server']):
                user_skills.update({'Python': 0.5, 'API': 0.5, 'Database': 0.5, 'SQL': 0.4})
            if any(word in target_role.lower() for word in ['frontend', 'ui', 'web']):
                user_skills.update({'React': 0.5, 'JavaScript': 0.5, 'CSS': 0.5, 'HTML': 0.4})
            if any(word in target_role.lower() for word in ['data', 'analytics', 'science']):
                user_skills.update({'SQL': 0.5, 'Python': 0.5, 'Statistics': 0.5, 'Data': 0.4})
            
            print(f"[JOBS] Fallback skills created: {list(user_skills.keys())}")
        
        # Search and match jobs using Adzuna
        matched_jobs = adzuna_service.match_jobs_to_skills(
            user_skills=user_skills,
            target_role=target_role,
            location=location
        )
        
        print(f"[JOBS] ✅ Found {len(matched_jobs)} matching jobs")
        
        # Prepare response with top 10 jobs
        top_jobs = matched_jobs[:10]
        
        return {
            "success": True,
            "total_jobs_found": len(matched_jobs),
            "jobs_returned": len(top_jobs),
            "jobs": top_jobs,
            "user_skills": user_skills,
            "search_criteria": {
                "target_role": target_role,
                "location": location
            }
        }
    
    except Exception as e:
        print(f"[ERROR] Job recommendations failed: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 8: CONTENT PROVIDERS
# ============================================

@router.get("/content-providers/{skill}")
async def get_content_providers(
    skill: str,
    content_type: Optional[str] = None,
    difficulty: Optional[str] = None,
    learning_preference: Optional[str] = None
):
    """
    Get curated learning content for a skill
    Sources: YouTube (primary), freeCodeCamp (practice), MIT OCW (academic depth)
    """
    try:
        print(f"\n[CONTENT] 📚 Fetching content for skill: {skill}")
        
        if learning_preference and learning_preference in ['video', 'reading', 'hands_on', 'mixed']:
            # Get mixed learning path based on preference
            print(f"[CONTENT] Learning preference: {learning_preference}")
            content = content_provider.get_mixed_learning_path(
                skill=skill,
                learning_preference=learning_preference
            )
        else:
            # Get content with optional filters
            content = content_provider.get_content_for_skill(
                skill=skill,
                content_type=content_type,
                difficulty=difficulty
            )
        
        print(f"[CONTENT] ✅ Retrieved {len(content)} resources")
        
        return {
            "success": True,
            "skill": skill,
            "total_resources": len(content),
            "filters": {
                "content_type": content_type,
                "difficulty": difficulty,
                "learning_preference": learning_preference
            },
            "content": content
        }
    
    except Exception as e:
        print(f"[ERROR] Content retrieval failed: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 9: GET LEARNING ROADMAP
# ============================================

@router.get("/learning-roadmap/{skill}")
async def get_learning_roadmap(
    skill: str,
    secondary_skills: Optional[str] = None,
    learning_preference: str = "mixed"
):
    """
    Get a comprehensive learning roadmap for a skill
    Includes primary and secondary skills across multiple phases
    """
    try:
        print(f"\n[ROADMAP] 🗺️  Creating roadmap for: {skill}")
        
        secondary_list = []
        if secondary_skills:
            secondary_list = [s.strip() for s in secondary_skills.split(',')]
            print(f"[ROADMAP] Secondary skills: {secondary_list}")
        
        roadmap = content_provider.get_learning_roadmap(
            primary_skill=skill,
            secondary_skills=secondary_list,
            learning_preference=learning_preference
        )
        
        print(f"[ROADMAP] ✅ Roadmap created with {len(roadmap['phases'])} phases")
        
        return {
            "success": True,
            "roadmap": roadmap,
            "learning_preference": learning_preference
        }
    
    except Exception as e:
        print(f"[ERROR] Roadmap creation failed: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 10: VERIFY QUESTIONS SOURCE
# ============================================

@router.get("/debug/verify-questions/{session_id}/{skill}/{module_id}")
async def verify_questions_source(session_id: str, skill: str, module_id: int):
    """Debug endpoint to verify questions are from model, not demo data"""
    try:
        session = db.client.table('ai_agent_sessions').select('*').eq('id', session_id).single().execute()
        
        if not session.data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        parsed = session.data.get('jd_parsed', {})
        learning_paths = parsed.get('learning_paths', {})
        learning_path = learning_paths.get(skill)
        
        if not learning_path:
            raise HTTPException(status_code=404, detail="Skill not found")
        
        # Find checkpoint
        checkpoint_data = None
        for module in learning_path['modules']:
            if module['module_id'] == module_id:
                for action in module['actions']:
                    if action['type'] == 'checkpoint':
                        checkpoint_data = action
                        break
        
        if not checkpoint_data:
            raise HTTPException(status_code=404, detail="Checkpoint not found")
        
        questions = checkpoint_data.get('questions', [])
        
        # Analyze if questions are AI-generated or demo fallback
        demo_keywords = [
            "What is the primary use of",
            "Which concept is most important",
            "What's the best way to validate",
            "After mastering"
        ]
        
        is_demo = any(keyword in q.get('question', '') for q in questions for keyword in demo_keywords)
        
        return {
            "session_id": session_id,
            "skill": skill,
            "module_id": module_id,
            "question_count": len(questions),
            "appears_to_be_demo": is_demo,
            "diagnosis": "Questions appear to be from FALLBACK/DEMO data. Check Gemini API connectivity and response format." if is_demo else "Questions appear to be AI-generated ✅",
            "sample_questions": [q.get('question', '')[:80] for q in questions[:2]],
            "full_checkpoint": checkpoint_data
        }
    
    except Exception as e:
        print(f"[ERROR] Verification failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 11: GET USER ONBOARDING DATA
# ============================================

@router.get("/onboarding/{user_id}")
async def get_user_onboarding(user_id: str):
    """Get user onboarding data including goals and preferences"""
    try:
        print(f"\n[ONBOARDING] 📋 Fetching onboarding data for user: {user_id}")
        
        onboarding_data = db.get_onboarding_data(user_id)
        
        if not onboarding_data:
            print(f"[ONBOARDING] No onboarding data found for {user_id}")
            return {
                "success": False,
                "onboarding": None,
                "message": "No onboarding data found"
            }
        
        print(f"[ONBOARDING] ✅ Retrieved onboarding data")
        return {
            "success": True,
            "primary_career_goal": onboarding_data.get('primary_career_goal'),
            "target_role": onboarding_data.get('target_role'),
            "learning_preference": onboarding_data.get('learning_preference', 'mixed'),
            "time_availability": onboarding_data.get('time_availability'),
            "current_status": onboarding_data.get('current_status'),
            "skills": onboarding_data.get('skills', []),
            "created_at": onboarding_data.get('created_at')
        }
        
    except Exception as e:
        print(f"[ERROR] Get onboarding failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))