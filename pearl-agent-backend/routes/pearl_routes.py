"""
Enhanced API Routes for PEARL Agent
Implements module-based learning with checkpoints with persistent database storage
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict
from database import SupabaseHelper
from services.pearl_agent import pearl
from services.enhanced_rag_service import enhanced_rag
from services.geminiai_service import GeminiService
from config import get_settings
import json
import uuid
from datetime import datetime

router = APIRouter()
db = SupabaseHelper()
ai = GeminiService()
settings = get_settings()


# ============================================
# REQUEST/RESPONSE MODELS
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
# DATABASE HELPER METHODS
# ============================================

class PEARLDatabaseHelper:
    """Database persistence for PEARL learning paths"""
    
    @staticmethod
    def save_learning_paths(session_id: str, user_id: str, learning_paths: Dict) -> bool:
        """Save complete learning paths to session"""
        try:
            db.client.table('ai_agent_sessions').update({
                'jd_parsed': {
                    'learning_paths': learning_paths,
                    'updated_at': datetime.now().isoformat()
                }
            }).eq('id', session_id).execute()
            return True
        except Exception as e:
            print(f"[ERROR] Failed to save learning paths: {e}")
            return False
    
    @staticmethod
    def save_module_progress(session_id: str, user_id: str, skill: str, module_id: int, 
                            module_data: Dict) -> Optional[str]:
        """Save or update module progress"""
        try:
            # Check if exists
            existing = db.client.table('ai_module_progress').select('id').eq(
                'session_id', session_id
            ).eq('skill', skill).eq('module_id', module_id).execute()
            
            module_progress_data = {
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
                # Update
                result = db.client.table('ai_module_progress').update(module_progress_data).eq(
                    'id', existing.data[0]['id']
                ).execute()
                return existing.data[0]['id']
            else:
                # Insert
                result = db.client.table('ai_module_progress').insert(module_progress_data).execute()
                return result.data[0]['id'] if result.data else None
        
        except Exception as e:
            print(f"[ERROR] Failed to save module progress: {e}")
            return None
    
    @staticmethod
    def save_action_completion(module_progress_id: str, action_index: int, 
                              action_type: str, completion_data: Dict) -> bool:
        """Save action completion record"""
        try:
            db.client.table('ai_action_completions').insert({
                'module_progress_id': module_progress_id,
                'action_index': action_index,
                'action_type': action_type,
                'completion_data': completion_data,
                'completed_at': datetime.now().isoformat()
            }).execute()
            return True
        except Exception as e:
            print(f"[ERROR] Failed to save action completion: {e}")
            return False
    
    @staticmethod
    def save_checkpoint_result(module_progress_id: str, user_id: str, skill: str, 
                              module_id: int, questions: List, answers: List[int], 
                              score: float, passed: bool) -> bool:
        """Save checkpoint quiz result"""
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
            
            # Update user skill confidence if passed
            if passed:
                PEARLDatabaseHelper.update_skill_confidence(user_id, skill, score / 100.0)
            
            return True
        except Exception as e:
            print(f"[ERROR] Failed to save checkpoint result: {e}")
            return False
    
    @staticmethod
    def update_skill_confidence(user_id: str, skill: str, score: float) -> bool:
        """Update user's skill confidence based on checkpoint performance"""
        try:
            # Get existing skill record
            existing = db.client.table('user_skill_memory').select('*').eq(
                'user_id', user_id
            ).eq('skill_name', skill).execute()
            
            new_confidence = min(1.0, score + 0.1)  # Increment confidence
            
            if existing.data:
                # Update
                db.client.table('user_skill_memory').update({
                    'confidence_score': new_confidence,
                    'last_practiced_at': datetime.now().isoformat(),
                    'practice_count': existing.data[0].get('practice_count', 0) + 1,
                    'updated_at': datetime.now().isoformat()
                }).eq('id', existing.data[0]['id']).execute()
            else:
                # Insert new skill record
                db.client.table('user_skill_memory').insert({
                    'user_id': user_id,
                    'skill_name': skill,
                    'confidence_score': new_confidence,
                    'practice_count': 1,
                    'last_practiced_at': datetime.now().isoformat()
                }).execute()
            
            return True
        except Exception as e:
            print(f"[ERROR] Failed to update skill confidence: {e}")
            return False
    
    @staticmethod
    def get_session_learning_paths(session_id: str) -> Optional[Dict]:
        """Retrieve learning paths from session"""
        try:
            result = db.client.table('ai_agent_sessions').select('jd_parsed').eq(
                'id', session_id
            ).single().execute()
            
            if result.data:
                parsed = result.data.get('jd_parsed', {})
                return parsed.get('learning_paths')
            return None
        except Exception as e:
            print(f"[ERROR] Failed to retrieve learning paths: {e}")
            return None
    
    @staticmethod
    def get_module_progress(session_id: str, skill: str, module_id: int) -> Optional[str]:
        """Get module progress record ID"""
        try:
            result = db.client.table('ai_module_progress').select('id').eq(
                'session_id', session_id
            ).eq('skill', skill).eq('module_id', module_id).single().execute()
            
            return result.data['id'] if result.data else None
        except Exception as e:
            print(f"[ERROR] Failed to get module progress: {e}")
            return None


# ============================================
# ENDPOINT 1: Initialize Career Path
# ============================================

@router.post("/start-journey")
async def start_career_journey(req: CareerGoalRequest):
    """
    Start a new learning journey from a career goal
    Breaks down into skills and creates learning paths
    Persists to database
    """
    try:
        print(f"[PEARL] Starting journey: {req.goal}")
        
        # Create session
        session = db.create_session(req.user_id, req.jd_text or req.goal)
        session_id = session['id']
        
        # Parse goal into skills
        if req.jd_text:
            required_skills = await _extract_skills_from_goal(req.jd_text)
            target_role = req.goal
        else:
            target_role = req.goal
            required_skills = await _extract_skills_from_goal(req.goal)
        
        # Get user's current skill levels
        try:
            user_skills = db.get_user_skills(req.user_id)
            skill_dict = {s['skill_name']: float(s['confidence_score']) for s in user_skills}
        except:
            skill_dict = {skill: 0.0 for skill in required_skills}
        
        # Analyze gaps and prioritize
        gap_analysis = {
            "gaps": [
                {
                    "skill": skill,
                    "current_level": skill_dict.get(skill, 0.0),
                    "target_level": 1.0,
                    "priority": i + 1
                }
                for i, skill in enumerate(required_skills)
            ]
        }
        
        # Create learning paths for top 3 priority skills
        priority_skills = gap_analysis['gaps'][:3]
        
        learning_paths = {}
        for skill_gap in priority_skills:
            skill = skill_gap['skill']
            current_conf = skill_gap['current_level']
            
            # Create module-based learning path
            path = pearl.create_learning_path(skill, current_conf)
            
            # Enhance with real external resources
            for module in path['modules']:
                for action in module['actions']:
                    if action['type'] in ['byte', 'course', 'taiken']:
                        real_resources = enhanced_rag.retrieve_resources(
                            skill,
                            action['type'],
                            count=1
                        )
                        if real_resources:
                            action['external_resource'] = real_resources[0]
            
            learning_paths[skill] = path
            
            # Save each module progress to database
            for module in path['modules']:
                PEARLDatabaseHelper.save_module_progress(
                    session_id, req.user_id, skill, module['module_id'], module
                )
        
        # Save complete learning paths to session
        PEARLDatabaseHelper.save_learning_paths(session_id, req.user_id, learning_paths)
        
        print(f"[PEARL] Journey created: {len(learning_paths)} skills. Session: {session_id}")
        
        return {
            "session_id": session_id,
            "target_role": target_role,
            "skills_to_learn": list(learning_paths.keys()),
            "learning_paths": learning_paths,
            "gap_analysis": gap_analysis,
            "next_action": pearl.get_next_action(learning_paths[list(learning_paths.keys())[0]]) if learning_paths else None
        }
    
    except Exception as e:
        print(f"[ERROR] Journey start failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 2: Get Current Module & Action
# ============================================

@router.get("/current-action/{session_id}")
async def get_current_action(session_id: str):
    """
    Get the user's current action to complete
    Retrieves from database
    """
    try:
        # Retrieve session and learning paths from database
        session = db.client.table('ai_agent_sessions').select('*').eq('id', session_id).single().execute()
        
        if not session.data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        parsed = session.data.get('jd_parsed', {})
        learning_paths = parsed.get('learning_paths', {})
        
        if not learning_paths:
            raise HTTPException(status_code=404, detail="Learning paths not found")
        
        # Get current skill (first incomplete skill)
        current_skill = None
        for skill, path in learning_paths.items():
            if path['current_module'] <= path['total_modules']:
                current_skill = skill
                break
        
        if not current_skill:
            return {"message": "All skills completed"}
        
        learning_path = learning_paths[current_skill]
        next_action = pearl.get_next_action(learning_path)
        
        return {
            "session_id": session_id,
            "current_skill": current_skill,
            "next_action": next_action,
            "learning_path": learning_path
        }
    
    except Exception as e:
        print(f"[ERROR] Get current action failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 3: Complete Action & Advance
# ============================================

@router.post("/complete-action")
async def complete_action(req: ModuleActionRequest):
    """
    Mark an action as complete and get next action
    Persists to database
    """
    try:
        print(f"[PEARL] Completing action: Module {req.module_id}, Action {req.action_index}")
        
        # Retrieve session
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
            return {
                "success": False,
                "message": "Use /submit-checkpoint endpoint for quizzes"
            }
        
        # Find and mark action as complete
        for module in learning_path['modules']:
            if module['module_id'] == req.module_id:
                if req.action_index < len(module['actions']):
                    module['actions'][req.action_index]['completed'] = True
                    
                    # Save action completion to database
                    module_progress_id = PEARLDatabaseHelper.get_module_progress(
                        req.session_id, req.skill, req.module_id
                    )
                    
                    if module_progress_id:
                        PEARLDatabaseHelper.save_action_completion(
                            module_progress_id,
                            req.action_index,
                            action_type,
                            req.completion_data
                        )
                    
                    # Update module progress in database
                    PEARLDatabaseHelper.save_module_progress(
                        req.session_id, req.user_id, req.skill, req.module_id, module
                    )
                    
                    # Save updated learning paths
                    PEARLDatabaseHelper.save_learning_paths(req.session_id, req.user_id, learning_paths)
                    
                    # Get next action
                    next_action = pearl.get_next_action(learning_path)
                    
                    print(f"[PEARL] Action completed successfully")
                    
                    return {
                        "success": True,
                        "message": "Action completed! Ready for next step.",
                        "next_action": next_action
                    }
        
        return {
            "success": False,
            "message": "Module or action not found"
        }
    
    except Exception as e:
        print(f"[ERROR] Complete action failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 4: Submit Checkpoint Quiz
# ============================================

@router.post("/submit-checkpoint")
async def submit_checkpoint(req: CheckpointSubmission):
    """
    Submit checkpoint quiz answers
    Validates and determines if user can advance to next module
    Persists results to database
    """
    try:
        print(f"[PEARL] Evaluating checkpoint: Module {req.module_id}")
        
        # Retrieve session
        session = db.client.table('ai_agent_sessions').select('*').eq('id', req.session_id).single().execute()
        
        if not session.data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        parsed = session.data.get('jd_parsed', {})
        learning_paths = parsed.get('learning_paths', {})
        learning_path = learning_paths.get(req.skill)
        
        if not learning_path:
            raise HTTPException(status_code=404, detail="Skill not found")
        
        # Find checkpoint dataf
        checkpoint_data = None
        for module in learning_path['modules']:
            if module['module_id'] == req.module_id:
                for action in module['actions']:
                    if action['type'] == 'checkpoint':
                        checkpoint_data = action
                        break
        
        if not checkpoint_data:
            raise HTTPException(status_code=404, detail="Checkpoint not found")
        
        # Evaluate using checkpoint system
        result = pearl.checkpoint.evaluate_checkpoint(checkpoint_data, req.answers)
        
        # Get module progress ID
        module_progress_id = PEARLDatabaseHelper.get_module_progress(
            req.session_id, req.skill, req.module_id
        )
        
        # Save checkpoint result to database
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
            # Mark checkpoint as complete and advance
            for module in learning_path['modules']:
                if module['module_id'] == req.module_id:
                    for idx, action in enumerate(module['actions']):
                        if action['type'] == 'checkpoint':
                            action['completed'] = True
            
            # Advance progress
            advance_result = pearl.advance_progress(learning_path, req.module_id, 0)
            
            # Update module progress in database
            current_module = learning_path['modules'][req.module_id - 1]
            PEARLDatabaseHelper.save_module_progress(
                req.session_id, req.user_id, req.skill, req.module_id, current_module
            )
            
            # Unlock next module if exists
            if req.module_id < learning_path['total_modules']:
                next_module = learning_path['modules'][req.module_id]
                PEARLDatabaseHelper.save_module_progress(
                    req.session_id, req.user_id, req.skill, req.module_id + 1, next_module
                )
            
            # Save updated learning paths
            PEARLDatabaseHelper.save_learning_paths(req.session_id, req.user_id, learning_paths)
            
            print(f"[PEARL] Checkpoint passed! Advancing.")
            
            return {
                "session_id": req.session_id,
                "checkpoint_result": result,
                "skill": req.skill,
                "module_id": req.module_id,
                "advance_result": advance_result
            }
        else:
            print(f"[PEARL] Checkpoint failed. Review required.")
            
            return {
                "session_id": req.session_id,
                "checkpoint_result": result,
                "skill": req.skill,
                "module_id": req.module_id
            }
    
    except Exception as e:
        print(f"[ERROR] Checkpoint evaluation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 5: Get Skill Progress
# ============================================

@router.get("/progress/{session_id}/{skill}")
async def get_skill_progress(session_id: str, skill: str):
    """
    Get detailed progress for a specific skill
    Retrieves from database
    """
    try:
        # Retrieve session
        session = db.client.table('ai_agent_sessions').select('*').eq('id', session_id).single().execute()
        
        if not session.data:
            raise HTTPException(status_code=404, detail="Session not found")
        
        parsed = session.data.get('jd_parsed', {})
        learning_paths = parsed.get('learning_paths', {})
        learning_path = learning_paths.get(skill)
        
        if not learning_path:
            raise HTTPException(status_code=404, detail="Skill not found")
        
        # Get module progress from database
        module_records = db.client.table('ai_module_progress').select('*').eq(
            'session_id', session_id
        ).eq('skill', skill).execute()
        
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
        
        progress_percentage = (completed_actions / total_actions * 100) if total_actions > 0 else 0
        
        return {
            "session_id": session_id,
            "skill": skill,
            "total_modules": learning_path['total_modules'],
            "completed_modules": completed_modules,
            "current_module": learning_path['current_module'],
            "progress_percentage": round(progress_percentage, 1),
            "total_actions": total_actions,
            "completed_actions": completed_actions,
            "modules": modules_info
        }
    
    except Exception as e:
        print(f"[ERROR] Get progress failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# ENDPOINT 6: Generate Final Assessment
# ============================================

@router.post("/final-assessment/{session_id}/{skill}")
async def generate_final_assessment(session_id: str, skill: str):
    """
    Generate comprehensive final assessment for skill validation
    """
    try:
        print(f"[PEARL] Generating final assessment for: {skill}")
        
        if session_id not in learning_paths_store:
            raise HTTPException(status_code=404, detail="Session not found")
        
        prompt = f"""
Create a final skill assessment for {skill}.
Generate 10 questions covering all aspects.

Return ONLY valid JSON:
{{
    "skill": "{skill}",
    "assessment_type": "final",
    "total_questions": 10,
    "time_limit_minutes": 30,
    "pass_threshold": 75,
    "questions": [
        {{
            "question": "Question text",
            "options": ["A", "B", "C", "D"],
            "correct_index": 0,
            "difficulty": "medium",
            "explanation": "Detailed explanation"
        }}
    ]
}}
"""
        
        try:
            assessment = ai.model.generate_content(prompt)
            content = assessment.text.strip()
            
            import re
            content = re.sub(r'```json\s*', '', content)
            content = re.sub(r'```\s*', '', content).strip()
            
            parsed = json.loads(content)
        except:
            # Fallback assessment
            parsed = {
                "skill": skill,
                "assessment_type": "final",
                "total_questions": 5,
                "time_limit_minutes": 15,
                "pass_threshold": 70,
                "questions": [
                    {
                        "question": f"What is a key use case for {skill}?",
                        "options": ["Professional development", "Hobby projects", "Both", "Neither"],
                        "correct_index": 2,
                        "difficulty": "easy",
                        "explanation": f"{skill} can be used for both professional and personal projects"
                    },
                    {
                        "question": f"What is considered a best practice in {skill}?",
                        "options": ["Practice A", "Practice B", "Practice C", "All of the above"],
                        "correct_index": 3,
                        "difficulty": "medium",
                        "explanation": "Multiple practices are important in {skill}"
                    },
                    {
                        "question": f"How would you approach learning {skill} effectively?",
                        "options": ["Theory only", "Practice only", "Balance of theory and practice", "Neither"],
                        "correct_index": 2,
                        "difficulty": "medium",
                        "explanation": "Effective learning combines theory understanding with hands-on practice"
                    },
                    {
                        "question": f"What tool is commonly used for {skill}?",
                        "options": ["Tool A", "Tool B", "Tool C", "Any of the above"],
                        "correct_index": 3,
                        "difficulty": "easy",
                        "explanation": "Multiple tools exist for working with {skill}"
                    },
                    {
                        "question": f"How can you validate your {skill} knowledge?",
                        "options": ["Building projects", "Taking quizzes", "Both", "Neither"],
                        "correct_index": 2,
                        "difficulty": "medium",
                        "explanation": "Both practical projects and assessments validate your knowledge"
                    }
                ]
            }
        
        print(f"[PEARL] Final assessment generated: {len(parsed['questions'])} questions")
        
        return {
            "session_id": session_id,
            "assessment": parsed
        }
    
    except Exception as e:
        print(f"[ERROR] Assessment generation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# HELPER FUNCTIONS
# ============================================

async def _extract_skills_from_goal(goal: str) -> List[str]:
    """Extract skills from career goal using AI"""
    prompt = f"""
Extract 3-5 key technical skills needed for: {goal}

Return ONLY a JSON array of skills:
["skill1", "skill2", "skill3"]
"""
    
    try:
        model = ai.model
        response = model.generate_content(prompt)
        content = response.text.strip()
        
        import re
        content = re.sub(r'```json\s*', '', content)
        content = re.sub(r'```\s*', '', content).strip()
        
        skills = json.loads(content)
        return skills if isinstance(skills, list) else [skills]
    except:
        # Fallback skill mapping
        skill_map = {
            "backend": ["Python", "SQL", "REST APIs", "Git"],
            "frontend": ["JavaScript", "React", "CSS", "HTML"],
            "data": ["Python", "SQL", "Statistics", "Data Analysis"],
            "mobile": ["Flutter", "Dart", "Mobile UI", "REST APIs"],
            "machine learning": ["Python", "Machine Learning", "Data Analysis", "Statistics"],
            "devops": ["Docker", "Kubernetes", "Python", "Git"]
        }
        
        goal_lower = goal.lower()
        for key in skill_map:
            if key in goal_lower:
                return skill_map[key]
        
        return ["Programming", "Problem Solving", "Communication"]
