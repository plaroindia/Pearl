"""
Onboarding Service - Handles user onboarding flow
"""
from typing import Dict, List, Optional
from config import get_settings
import google.generativeai as genai
import json
from database import EnhancedSupabaseHelper

settings = get_settings()
genai.configure(api_key=settings.GEMINI_API_KEY)
db = EnhancedSupabaseHelper()


class OnboardingService:
    """Handles user onboarding and initialization"""
    
    @staticmethod
    def process_onboarding(user_id: str, onboarding_data: Dict) -> Dict:
        """
        Process onboarding data and initialize user profile
        """
        print(f"[ONBOARDING] Processing onboarding for user: {user_id}")
        
        try:
            # Save onboarding data
            success = db.save_onboarding(user_id, onboarding_data)
            if not success:
                return {
                    "success": False,
                    "error": "Failed to save onboarding data"
                }
            
            # Extract skills from career goal
            career_goal = onboarding_data.get('primary_career_goal', '')
            target_role = onboarding_data.get('target_role', '')
            
            skills = OnboardingService._extract_skills_from_goal(
                career_goal, target_role, onboarding_data
            )
            
            # Initialize user skills
            for skill in skills:
                db.update_skill_confidence(user_id, skill, confidence_delta=0.0)
            
            # Create initial AI session
            session = db.create_agent_session(
                user_id=user_id,
                jd_text=career_goal,
                onboarding_id=user_id  # Using user_id as onboarding reference
            )
            
            # Generate personalized welcome
            welcome_message = OnboardingService._generate_welcome_message(
                user_id, onboarding_data, skills
            )
            
            print(f"[ONBOARDING] ✅ Onboarding complete for {user_id}")
            
            return {
                "success": True,
                "session_id": session.get('id') if session else None,
                "initial_skills": skills,
                "welcome_message": welcome_message,
                "next_step": "skill_assessment"
            }
            
        except Exception as e:
            print(f"[ONBOARDING ERROR] {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    @staticmethod
    def _extract_skills_from_goal(career_goal: str, target_role: str, 
                                 onboarding_data: Dict) -> List[str]:
        """Extract skills from career goal using AI"""
        try:
            # Build prompt for skill extraction
            prompt = f"""
            Extract 5-7 core technical skills needed for this career goal:
            
            Career Goal: {career_goal}
            Target Role: {target_role}
            
            User Background:
            - Current Status: {onboarding_data.get('current_status', 'student')}
            - Learning Preference: {onboarding_data.get('learning_preference', 'mixed')}
            - Time Availability: {onboarding_data.get('time_availability', '5-10 hours/week')}
            
            Return ONLY a JSON array of skill names:
            ["Skill 1", "Skill 2", "Skill 3"]
            """
            
            model = genai.GenerativeModel('gemini-2.5-flash')
            response = model.generate_content(prompt)
            
            # Parse response
            content = response.text.strip()
            if content.startswith('[') and content.endswith(']'):
                skills = json.loads(content)
            else:
                # Fallback skills based on role
                skills = OnboardingService._get_fallback_skills(target_role)
            
            return skills[:7]  # Limit to 7 skills
            
        except Exception as e:
            print(f"[ONBOARDING] Skill extraction failed: {e}")
            return OnboardingService._get_fallback_skills(target_role)
    
    @staticmethod
    def _get_fallback_skills(target_role: str) -> List[str]:
        """Get fallback skills based on role keywords"""
        role_lower = target_role.lower()
        
        skill_mappings = {
            'backend': ['Python', 'SQL', 'REST APIs', 'Git', 'Docker'],
            'frontend': ['JavaScript', 'React', 'CSS', 'HTML', 'TypeScript'],
            'fullstack': ['JavaScript', 'Python', 'React', 'Node.js', 'SQL'],
            'data': ['Python', 'SQL', 'Statistics', 'Data Analysis', 'Pandas'],
            'machine learning': ['Python', 'Machine Learning', 'Statistics', 'TensorFlow', 'Scikit-learn'],
            'devops': ['Docker', 'Kubernetes', 'AWS', 'CI/CD', 'Linux'],
            'mobile': ['Flutter', 'React Native', 'Swift', 'Kotlin', 'Mobile UI'],
            'designer': ['Figma', 'UI/UX Design', 'Prototyping', 'User Research', 'Wireframing']
        }
        
        for keyword, skills in skill_mappings.items():
            if keyword in role_lower:
                return skills
        
        # Default generic skills
        return ['Communication', 'Problem Solving', 'Critical Thinking', 'Teamwork', 'Adaptability']
    
    @staticmethod
    def _generate_welcome_message(user_id: str, onboarding_data: Dict, 
                                 skills: List[str]) -> Dict:
        """Generate personalized welcome message"""
        username = db.get_user_profile(user_id).get('username', 'Learner')
        career_goal = onboarding_data.get('primary_career_goal', 'your goal')
        
        welcome_text = f"""
        Welcome to PEARL, {username}!
        
        I'm excited to help you on your journey to become {career_goal}.
        
        Based on your profile, I've identified {len(skills)} key skills to focus on:
        {', '.join(skills[:3])}...
        
        Here's what's next:
        1. **Skill Assessment**: Quick check on your current knowledge
        2. **Personalized Roadmap**: Custom learning path based on your goals
        3. **First Learning Module**: Start with bite-sized content
        
        Ready to begin? Let's take the first step together!
        """
        
        return {
            "title": "Welcome to Your Learning Journey!",
            "message": welcome_text,
            "cta_text": "Start Skill Assessment",
            "cta_action": "/assessment/start"
        }
    
    @staticmethod
    def get_onboarding_status(user_id: str) -> Dict:
        """Get user onboarding status"""
        onboarding_data = db.get_onboarding_data(user_id)
        profile = db.get_user_profile(user_id)
        
        if not onboarding_data:
            return {
                "completed": False,
                "step": 0,
                "total_steps": 5,
                "next_step": "basic_info"
            }
        
        # Determine current step
        steps_completed = 0
        if onboarding_data.get('primary_career_goal'):
            steps_completed += 1
        if onboarding_data.get('skills'):
            steps_completed += 1
        if onboarding_data.get('time_availability'):
            steps_completed += 1
        if onboarding_data.get('learning_preference'):
            steps_completed += 1
        if profile and profile.get('onboarding_complete'):
            steps_completed += 1
        
        return {
            "completed": steps_completed >= 5,
            "step": steps_completed,
            "total_steps": 5,
            "next_step": OnboardingService._get_next_step(steps_completed),
            "onboarding_data": onboarding_data
        }
    
    @staticmethod
    def _get_next_step(current_step: int) -> str:
        """Get next onboarding step"""
        steps = [
            "basic_info",
            "career_goal",
            "skills_assessment",
            "preferences",
            "confirmation"
        ]
        return steps[current_step] if current_step < len(steps) else "complete"


# Global instance
onboarding_service = OnboardingService()