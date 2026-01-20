"""
Authentication Service for PEARL Agent
Handles Supabase Auth (OAuth + Email/Password)
"""

from supabase import create_client, Client
from config import get_settings
from typing import Optional, Dict
import jwt
from datetime import datetime, timedelta

settings = get_settings()


class AuthService:
    """Handles user authentication via Supabase"""
    
    def __init__(self):
        self.client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    
    def sign_up_email(self, email: str, password: str, username: str) -> Dict:
        """
        Sign up with email and password
        Creates user profile automatically
        """
        try:
            # Sign up user
            auth_response = self.client.auth.sign_up({
                "email": email,
                "password": password,
                "options": {
                    "data": {
                        "username": username
                    }
                }
            })
            
            if auth_response.user:
                user_id = auth_response.user.id
                
                # Create user profile
                profile_data = {
                    "user_id": user_id,
                    "username": username,
                    "email": email,
                    "role": "learner",
                    "streak_count": 0,
                    "followers_count": 0,
                    "following_count": 0
                }
                
                self.client.table('user_profiles').insert(profile_data).execute()
                
                return {
                    "success": True,
                    "user": {
                        "id": user_id,
                        "email": email,
                        "username": username
                    },
                    "session": auth_response.session
                }
            
            return {
                "success": False,
                "error": "Sign up failed"
            }
            
        except Exception as e:
            print(f"[ERROR] Sign up failed: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def sign_in_email(self, email: str, password: str) -> Dict:
        """Sign in with email and password"""
        try:
            auth_response = self.client.auth.sign_in_with_password({
                "email": email,
                "password": password
            })
            
            if auth_response.user:
                # Get user profile
                profile = self.client.table('user_profiles').select('*').eq(
                    'user_id', auth_response.user.id
                ).single().execute()
                
                return {
                    "success": True,
                    "user": {
                        "id": auth_response.user.id,
                        "email": auth_response.user.email,
                        "username": profile.data.get('username') if profile.data else None,
                        "profile": profile.data
                    },
                    "session": auth_response.session
                }
            
            return {
                "success": False,
                "error": "Invalid credentials"
            }
            
        except Exception as e:
            print(f"[ERROR] Sign in failed: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def sign_in_oauth(self, provider: str) -> Dict:
        """
        Initiate OAuth sign in
        Providers: google, github, etc.
        """
        try:
            auth_response = self.client.auth.sign_in_with_oauth({
                "provider": provider,
                "options": {
                    "redirect_to": f"{settings.FRONTEND_URL}/auth/callback"
                }
            })
            
            return {
                "success": True,
                "url": auth_response.url
            }
            
        except Exception as e:
            print(f"[ERROR] OAuth failed: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def sign_out(self, access_token: str) -> Dict:
        """Sign out user"""
        try:
            self.client.auth.sign_out()
            return {"success": True}
        except Exception as e:
            print(f"[ERROR] Sign out failed: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def get_user_from_token(self, access_token: str) -> Optional[Dict]:
        """Get user from access token"""
        try:
            user = self.client.auth.get_user(access_token)
            
            if user:
                # Get full profile
                profile = self.client.table('user_profiles').select('*').eq(
                    'user_id', user.id
                ).single().execute()
                
                return {
                    "id": user.id,
                    "email": user.email,
                    "profile": profile.data if profile.data else None
                }
            
            return None
            
        except Exception as e:
            print(f"[ERROR] Get user failed: {e}")
            return None
    
    def update_profile(self, user_id: str, updates: Dict) -> Dict:
        """Update user profile"""
        try:
            allowed_fields = ['username', 'bio', 'study', 'location', 'profile_pic', 'role']
            filtered_updates = {k: v for k, v in updates.items() if k in allowed_fields}
            filtered_updates['updated_at'] = datetime.now().isoformat()
            
            result = self.client.table('user_profiles').update(
                filtered_updates
            ).eq('user_id', user_id).execute()
            
            return {
                "success": True,
                "profile": result.data[0] if result.data else None
            }
            
        except Exception as e:
            print(f"[ERROR] Update profile failed: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def get_user_profile(self, user_id: str) -> Optional[Dict]:
        """Get complete user profile with skills"""
        try:
            # Get profile
            profile = self.client.table('user_profiles').select('*').eq(
                'user_id', user_id
            ).single().execute()
            
            if not profile.data:
                return None
            
            # Get skills
            skills = self.client.table('user_skill_memory').select('*').eq(
                'user_id', user_id
            ).order('confidence_score', desc=True).execute()
            
            # Get active sessions
            sessions = self.client.table('ai_agent_sessions').select('*').eq(
                'user_id', user_id
            ).eq('status', 'active').order('created_at', desc=True).limit(5).execute()
            
            return {
                "profile": profile.data,
                "skills": skills.data if skills.data else [],
                "active_sessions": sessions.data if sessions.data else []
            }
            
        except Exception as e:
            print(f"[ERROR] Get profile failed: {e}")
            return None


# Global instance
auth_service = AuthService()
