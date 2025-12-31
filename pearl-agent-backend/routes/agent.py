from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from database import SupabaseHelper
from services.geminiai_service import GeminiService
from services.rag_service import rag
from config import get_settings
import json
import traceback

router = APIRouter()
db = SupabaseHelper()
ai = GeminiService()
settings = get_settings()

# ============================================
# REQUEST MODELS
# ============================================
class JDAnalysisRequest(BaseModel):
    jd_text: str
    user_id: str = settings.DEMO_USER_ID

class TaskSubmissionRequest(BaseModel):
    task_id: str
    submission: str
    user_id: str = settings.DEMO_USER_ID

# ============================================
# ENDPOINT 1: Start Session + Parse JD
# ============================================
@router.post("/analyze-jd")
async def analyze_job_description(req: JDAnalysisRequest):
    try:
        print(f"[INFO] Starting JD analysis for user: {req.user_id}")
        print(f"[INFO] JD text length: {len(req.jd_text)} chars")
        
        # Step 1: Create session
        print("[INFO] Creating session...")
        session = db.create_session(req.user_id, req.jd_text)
        print(f"[INFO] Session created: {session['id']}")
        
        # Step 2: Parse JD with AI
        print("[INFO] Parsing JD with OpenAI...")
        parsed_jd = ai.parse_jd(req.jd_text)
        print(f"[INFO] Parsed JD: {parsed_jd}")
        
        # Validate parsed_jd has required fields
        if not isinstance(parsed_jd, dict):
            raise ValueError(f"Expected dict, got {type(parsed_jd)}")
        
        if "role" not in parsed_jd:
            print("[WARNING] 'role' missing in parsed_jd, using fallback")
            parsed_jd["role"] = "Backend Developer"
        
        if "required_skills" not in parsed_jd or not parsed_jd["required_skills"]:
            print("[WARNING] 'required_skills' missing, using fallback")
            parsed_jd["required_skills"] = ["Python", "APIs", "SQL"]
        
        # Step 3: Get user's current skills
        print("[INFO] Fetching user skills...")
        user_skills = db.get_user_skills(req.user_id)
        skill_dict = {s['skill_name']: float(s['confidence_score']) for s in user_skills}
        print(f"[INFO] User has {len(skill_dict)} skills")
        
        # Step 4: Analyze skill gaps
        print("[INFO] Analyzing skill gaps...")
        gap_analysis = ai.analyze_skill_gap(
            parsed_jd['required_skills'], 
            skill_dict
        )
        print(f"[INFO] Gap analysis: {len(gap_analysis.get('gaps', []))} gaps found")
        
        # Step 5: Update session with parsed data
        print("[INFO] Updating session...")
        db.update_session(session['id'], {
            'jd_parsed': parsed_jd
        })
        
        response_data = {
            "session_id": session['id'],
            "parsed_jd": parsed_jd,
            "skill_gaps": gap_analysis,
            "user_skills": skill_dict
        }
        
        print("[SUCCESS] JD analysis complete")
        return response_data
    
    except Exception as e:
        print(f"[ERROR] JD analysis failed: {str(e)}")
        print(f"[ERROR] Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=500, 
            detail={
                "error": str(e),
                "type": type(e).__name__,
                "message": "Failed to analyze job description. Check server logs."
            }
        )

# ============================================
# ENDPOINT 2: Generate Roadmap with RAG
# ============================================
@router.post("/generate-roadmap/{session_id}")
async def generate_roadmap(session_id: str):
    try:
        print(f"[INFO] Generating roadmap for session: {session_id}")
        
        # Get session data
        supabase = db.client
        session = supabase.table('ai_agent_sessions') \
            .select('*') \
            .eq('id', session_id) \
            .single() \
            .execute()
        
        if not session.data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        parsed_jd = session.data.get('jd_parsed', {})
        user_id = session.data['user_id']
        
        print(f"[INFO] Target role: {parsed_jd.get('role')}")
        
        # Get skill gaps
        user_skills = db.get_user_skills(user_id)
        skill_dict = {s['skill_name']: float(s['confidence_score']) for s in user_skills}
        gap_analysis = ai.analyze_skill_gap(
            parsed_jd.get('required_skills', []), 
            skill_dict
        )
        
        # Generate roadmap
        print("[INFO] Generating roadmap with AI...")
        roadmap = ai.generate_roadmap(
            target_role=parsed_jd.get('role', 'Backend Developer'),
            skill_gaps=gap_analysis.get('gaps', []),
            user_name="Student"
        )
        
        # RAG: Retrieve learning resources for each week
        print("[INFO] Retrieving learning resources...")
        for week in roadmap.get('weeks', []):
            query = f"{' '.join(week.get('skills_focus', []))} learning resources"
            retrieved = rag.retrieve(query, top_k=3)
            
            # Save retrievals to database
            for resource in retrieved:
                try:
                    supabase.table('ai_retrieval_sources').insert({
                        'session_id': session_id,
                        'source_type': resource['type'],
                        'source_title': resource['title'],
                        'source_url': resource.get('url', '#'),
                        'relevance_score': resource['relevance_score']
                    }).execute()
                except Exception as db_error:
                    print(f"[WARNING] Failed to save retrieval: {db_error}")
            
            # Add to roadmap
            week['retrieved_resources'] = retrieved
        
        # Save roadmap
        print("[INFO] Saving roadmap to database...")
        saved_roadmap = db.save_roadmap(
            session_id=session_id,
            user_id=user_id,
            target_role=parsed_jd.get('role', 'Backend Developer'),
            roadmap_data=roadmap
        )
        
        # Save milestones
        for week_data in roadmap.get('weeks', []):
            try:
                supabase.table('ai_roadmap_milestones').insert({
                    'roadmap_id': saved_roadmap['id'],
                    'week_number': week_data.get('week', 1),
                    'title': week_data.get('title', ''),
                    'description': week_data.get('milestone', ''),
                    'skills_to_learn': week_data.get('skills_focus', []),
                    'resources': week_data.get('learning_resources', [])
                }).execute()
            except Exception as milestone_error:
                print(f"[WARNING] Failed to save milestone: {milestone_error}")
        
        print("[SUCCESS] Roadmap generation complete")
        return {
            "roadmap_id": saved_roadmap['id'],
            "roadmap": roadmap
        }
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"[ERROR] Roadmap generation failed: {str(e)}")
        print(f"[ERROR] Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=500, 
            detail={
                "error": str(e),
                "message": "Failed to generate roadmap. Check server logs."
            }
        )

# ============================================
# ENDPOINT 3: Generate Practice Task
# ============================================
@router.post("/next-task/{session_id}")
async def generate_practice_task(session_id: str):
    try:
        print(f"[INFO] Generating task for session: {session_id}")
        
        supabase = db.client
        session = supabase.table('ai_agent_sessions') \
            .select('*') \
            .eq('id', session_id) \
            .single() \
            .execute()
        
        if not session.data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        parsed_jd = session.data.get('jd_parsed', {})
        user_id = session.data['user_id']
        
        # Pick highest priority skill gap
        user_skills = db.get_user_skills(user_id)
        skill_dict = {s['skill_name']: float(s['confidence_score']) for s in user_skills}
        
        # Find lowest confidence required skill
        target_skill = "Python"  # Default
        lowest_conf = 1.0
        required_skills = parsed_jd.get('required_skills', ['Python', 'SQL'])
        
        for req_skill in required_skills:
            conf = skill_dict.get(req_skill, 0.0)
            if conf < lowest_conf:
                lowest_conf = conf
                target_skill = req_skill
        
        print(f"[INFO] Target skill: {target_skill} (confidence: {lowest_conf})")
        
        # Generate task
        print("[INFO] Generating task with AI...")
        task = ai.generate_practice_task(target_skill, difficulty="medium")
        
        # Save task
        print("[INFO] Saving task to database...")
        saved_task = db.save_practice_task(
            session_id=session_id,
            user_id=user_id,
            task_data=task
        )
        
        print("[SUCCESS] Task generation complete")
        return {
            "task_id": saved_task['id'],
            "task": task
        }
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"[ERROR] Task generation failed: {str(e)}")
        print(f"[ERROR] Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=500,
            detail={
                "error": str(e),
                "message": "Failed to generate task. Check server logs."
            }
        )

# ============================================
# ENDPOINT 4: Submit & Evaluate Task
# ============================================
@router.post("/submit-task")
async def submit_task(req: TaskSubmissionRequest):
    try:
        print(f"[INFO] Evaluating submission for task: {req.task_id}")
        
        supabase = db.client
        
        # Get task
        task = supabase.table('ai_practice_tasks') \
            .select('*') \
            .eq('id', req.task_id) \
            .single() \
            .execute()
        
        if not task.data:
            raise HTTPException(status_code=404, detail="Task not found")
        
        # Evaluate with AI
        print("[INFO] Evaluating with OpenAI...")
        evaluation = ai.evaluate_submission(
            task_description=task.data['task_description'],
            submission=req.submission,
            skill=task.data['skill_focus']
        )
        
        # Save result
        print("[INFO] Saving evaluation result...")
        result = db.save_task_result(
            task_id=req.task_id,
            user_id=req.user_id,
            result_data={
                'submission': req.submission,
                'score': float(evaluation.get('score', 0)),
                'feedback': evaluation.get('feedback', 'Good effort!'),
                'skill_improvement': {
                    'delta': float(evaluation.get('skill_confidence_delta', 0))
                }
            }
        )
        
        # Update user skill confidence (REFLECTION)
        print("[INFO] Updating skill confidence (reflection)...")
        try:
            current_skill = supabase.table('user_skill_memory') \
                .select('*') \
                .eq('user_id', req.user_id) \
                .eq('skill_name', task.data['skill_focus']) \
                .single() \
                .execute()
            
            if current_skill.data:
                delta = float(evaluation.get('skill_confidence_delta', 0))
                new_confidence = min(1.0, max(0.0, 
                    float(current_skill.data['confidence_score']) + delta
                ))
                
                db.update_skill_confidence(
                    user_id=req.user_id,
                    skill_name=task.data['skill_focus'],
                    new_confidence=new_confidence
                )
                print(f"[INFO] Skill confidence updated: {current_skill.data['confidence_score']} -> {new_confidence}")
        except Exception as skill_error:
            print(f"[WARNING] Skill update failed: {skill_error}")
        
        print("[SUCCESS] Task submission complete")
        return {
            "result_id": result['id'],
            "evaluation": evaluation,
            "skill_updated": True
        }
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"[ERROR] Task submission failed: {str(e)}")
        print(f"[ERROR] Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=500,
            detail={
                "error": str(e),
                "message": "Failed to submit task. Check server logs."
            }
        )

# ============================================
# ENDPOINT 5: Get Session Summary
# ============================================
@router.get("/session/{session_id}")
async def get_session_summary(session_id: str):
    try:
        print(f"[INFO] Fetching session summary: {session_id}")
        
        supabase = db.client
        
        # Get session
        session = supabase.table('ai_agent_sessions') \
            .select('*') \
            .eq('id', session_id) \
            .single() \
            .execute()
        
        if not session.data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        # Get roadmap
        roadmap = supabase.table('ai_roadmap') \
            .select('*') \
            .eq('session_id', session_id) \
            .execute()
        
        # Get tasks
        tasks = supabase.table('ai_practice_tasks') \
            .select('*') \
            .eq('session_id', session_id) \
            .execute()
        
        return {
            "session": session.data,
            "roadmap": roadmap.data,
            "tasks": tasks.data
        }
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"[ERROR] Session fetch failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))