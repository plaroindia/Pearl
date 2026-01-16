"""
Authentication API Routes
"""

from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel, EmailStr
from typing import Optional
from services.auth_service import auth_service
from database import SupabaseHelper

router = APIRouter()


# ============================================
# REQUEST MODELS
# ============================================

class SignUpRequest(BaseModel):
    email: EmailStr
    password: str
    username: str


class SignInRequest(BaseModel):
    email: EmailStr
    password: str


class OAuthRequest(BaseModel):
    provider: str  # google, github, etc.


class UpdateProfileRequest(BaseModel):
    username: Optional[str] = None
    bio: Optional[str] = None
    study: Optional[str] = None
    location: Optional[str] = None
    profile_pic: Optional[str] = None
    role: Optional[str] = None


# ============================================
# ENDPOINTS
# ============================================

@router.post("/signup")
async def signup(req: SignUpRequest):
    """Sign up with email and password"""
    result = auth_service.sign_up_email(req.email, req.password, req.username)
    
    if result['success']:
        return {
            "success": True,
            "user": result['user'],
            "access_token": result['session'].access_token if result.get('session') else None,
            "refresh_token": result['session'].refresh_token if result.get('session') else None
        }
    else:
        raise HTTPException(status_code=400, detail=result.get('error', 'Sign up failed'))


@router.post("/signin")
async def signin(req: SignInRequest):
    """Sign in with email and password"""
    result = auth_service.sign_in_email(req.email, req.password)
    
    if result['success']:
        return {
            "success": True,
            "user": result['user'],
            "access_token": result['session'].access_token if result.get('session') else None,
            "refresh_token": result['session'].refresh_token if result.get('session') else None
        }
    else:
        raise HTTPException(status_code=401, detail=result.get('error', 'Invalid credentials'))


@router.post("/oauth")
async def oauth_signin(req: OAuthRequest):
    """Initiate OAuth sign in"""
    result = auth_service.sign_in_oauth(req.provider)
    
    if result['success']:
        return {
            "success": True,
            "url": result['url']
        }
    else:
        raise HTTPException(status_code=400, detail=result.get('error', 'OAuth failed'))


@router.post("/signout")
async def signout(authorization: Optional[str] = Header(None)):
    """Sign out user"""
    if not authorization:
        raise HTTPException(status_code=401, detail="No authorization token")
    
    token = authorization.replace("Bearer ", "")
    result = auth_service.sign_out(token)
    
    return {"success": True, "message": "Signed out successfully"}


@router.get("/me")
async def get_current_user(authorization: Optional[str] = Header(None)):
    """Get current user from token"""
    if not authorization:
        raise HTTPException(status_code=401, detail="No authorization token")
    
    token = authorization.replace("Bearer ", "")
    user = auth_service.get_user_from_token(token)
    
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    return user


@router.get("/profile/{user_id}")
async def get_user_profile(user_id: str):
    """Get user profile with skills and sessions"""
    profile = auth_service.get_user_profile(user_id)
    
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    return profile


@router.put("/profile/{user_id}")
async def update_user_profile(
    user_id: str, 
    req: UpdateProfileRequest,
    authorization: Optional[str] = Header(None)
):
    """Update user profile"""
    if not authorization:
        raise HTTPException(status_code=401, detail="No authorization token")
    
    # Verify user owns this profile
    token = authorization.replace("Bearer ", "")
    current_user = auth_service.get_user_from_token(token)
    
    if not current_user or current_user['id'] != user_id:
        raise HTTPException(status_code=403, detail="Unauthorized")
    
    updates = req.dict(exclude_unset=True)
    result = auth_service.update_profile(user_id, updates)
    
    if result['success']:
        return result
    else:
        raise HTTPException(status_code=400, detail=result.get('error', 'Update failed'))


@router.get("/profile/{user_id}/skill-gap")
async def get_skill_gap_analysis(user_id: str):
    """
    Get skill gap analysis for user
    Shows current skills vs required skills from active sessions
    """
    try:
        profile = auth_service.get_user_profile(user_id)
        
        if not profile:
            raise HTTPException(status_code=404, detail="Profile not found")
        
        # Get current skills
        current_skills = {
            skill['skill_name']: float(skill['confidence_score'])
            for skill in profile.get('skills', [])
        }
        
        # Get required skills from active sessions
        db = SupabaseHelper()
        
        sessions = db.client.table('ai_agent_sessions').select('*').eq(
            'user_id', user_id
        ).eq('status', 'active').execute()
        
        required_skills = {}
        for session in sessions.data if sessions.data else []:
            parsed = session.get('jd_parsed', {})
            learning_paths = parsed.get('learning_paths', {})
            
            for skill, path in learning_paths.items():
                if skill not in required_skills:
                    required_skills[skill] = {
                        "target_level": 0.8,
                        "current_level": current_skills.get(skill, 0.0),
                        "gap": 0.8 - current_skills.get(skill, 0.0),
                        "modules_completed": 0,
                        "total_modules": path.get('total_modules', 0)
                    }
                
                # Count completed modules
                for module in path.get('modules', []):
                    if module.get('status') == 'completed':
                        required_skills[skill]['modules_completed'] += 1
        
        # Calculate overall readiness
        if required_skills:
            avg_current = sum(s['current_level'] for s in required_skills.values()) / len(required_skills)
            overall_readiness = min(1.0, avg_current / 0.8) * 100
        else:
            overall_readiness = 0
        
        return {
            "user_id": user_id,
            "current_skills": current_skills,
            "required_skills": required_skills,
            "overall_readiness": round(overall_readiness, 1),
            "skills_mastered": len([s for s in current_skills.values() if s >= 0.8]),
            "skills_in_progress": len([s for s in current_skills.values() if 0.3 <= s < 0.8]),
            "skills_to_learn": len([s for s in required_skills.keys() if s not in current_skills])
        }
        
    except Exception as e:
        print(f"[ERROR] Skill gap analysis failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
