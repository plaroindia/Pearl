"""
Resume Builder Service - Generates resumes based on user skills and achievements
"""
from typing import Dict, List, Optional
from datetime import datetime
from database import EnhancedSupabaseHelper
import google.generativeai as genai
import json
from config import get_settings

settings = get_settings()
genai.configure(api_key=settings.GEMINI_API_KEY)
db = EnhancedSupabaseHelper()


class ResumeService:
    """Handles resume generation and updates"""
    
    @staticmethod
    def generate_resume(user_id: str, target_role: Optional[str] = None) -> Dict:
        """Generate complete resume for user"""
        print(f"[RESUME] Generating resume for user: {user_id}")
        
        try:
            # Get user data
            profile = db.get_user_profile(user_id)
            onboarding = db.get_onboarding_data(user_id)
            skills = db.get_user_skills(user_id)
            sessions = db.get_active_sessions(user_id)
            taiken_progress = db.get_user_taiken_progress(user_id)
            
            if not profile:
                return {
                    "success": False,
                    "error": "User profile not found"
                }
            
            # Determine target role
            if not target_role and onboarding:
                target_role = onboarding.get('target_role', 'Professional')
            
            # Extract experiences
            experiences = ResumeService._extract_experiences(
                user_id, sessions, taiken_progress
            )
            
            # Generate resume sections using AI
            resume_data = ResumeService._generate_resume_sections(
                profile=profile,
                target_role=target_role,
                skills=skills,
                experiences=experiences,
                onboarding=onboarding
            )
            
            # Format for download
            formatted_resume = ResumeService._format_resume(resume_data)
            
            print(f"[RESUME] ✅ Resume generated for {user_id}")
            
            return {
                "success": True,
                "resume": resume_data,
                "formatted": formatted_resume,
                "download_url": ResumeService._create_download_link(resume_data)
            }
            
        except Exception as e:
            print(f"[RESUME ERROR] {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    @staticmethod
    def _extract_experiences(user_id: str, sessions: List[Dict], 
                            taiken_progress: List[Dict]) -> List[Dict]:
        """Extract learning experiences for resume"""
        experiences = []
        
        # Add completed modules as experiences
        for session in sessions:
            if session.get('jd_parsed'):
                parsed = session.get('jd_parsed', {})
                learning_paths = parsed.get('learning_paths', {})
                
                for skill, path in learning_paths.items():
                    completed_modules = [
                        m for m in path.get('modules', []) 
                        if m.get('status') == 'completed'
                    ]
                    
                    if completed_modules:
                        experiences.append({
                            'type': 'learning_project',
                            'skill': skill,
                            'modules_completed': len(completed_modules),
                            'total_hours': sum(m.get('estimated_hours', 0) 
                                             for m in completed_modules),
                            'description': f"Completed {len(completed_modules)} modules in {skill}",
                            'date': session.get('created_at', datetime.now().isoformat())
                        })
        
        # Add Taiken experiences
        for taiken in taiken_progress:
            if taiken.get('status') == 'completed':
                experiences.append({
                    'type': 'interactive_experience',
                    'title': 'Interactive Learning Scenario',
                    'description': f"Completed interactive scenario with {taiken.get('correct_answers', 0)} correct answers",
                    'skills_practiced': ['Problem Solving', 'Decision Making', 'Critical Thinking'],
                    'date': taiken.get('completed_at', datetime.now().isoformat())
                })
        
        return experiences
    
    @staticmethod
    def _generate_resume_sections(profile: Dict, target_role: str, 
                                 skills: List[Dict], experiences: List[Dict],
                                 onboarding: Optional[Dict]) -> Dict:
        """Generate resume sections using AI"""
        
        # Build prompt for AI
        prompt = f"""
        Generate a professional resume for a {target_role} position.
        
        Personal Information:
        - Name: {profile.get('username', 'Professional')}
        - Bio: {profile.get('bio', 'Passionate learner')}
        - Location: {profile.get('location', '')}
        - Study: {profile.get('study', '')}
        
        Target Role: {target_role}
        
        Skills (with confidence scores):
        {chr(10).join([f"- {s['skill_name']}: {s.get('confidence_score', 0)*100}%" for s in skills[:10]])}
        
        Learning Experiences:
        {chr(10).join([f"- {exp['description']}" for exp in experiences[:5]])}
        
        Onboarding Information:
        - Career Goal: {onboarding.get('primary_career_goal', '') if onboarding else ''}
        - Learning Preference: {onboarding.get('learning_preference', '') if onboarding else ''}
        
        Generate the resume in this JSON structure:
        {{
            "personal_info": {{
                "name": "Full Name",
                "title": "Professional Title",
                "summary": "2-3 sentence professional summary",
                "contact": {{
                    "email": "email",
                    "location": "location",
                    "linkedin": "optional",
                    "portfolio": "optional"
                }}
            }},
            "skills": [
                {{
                    "category": "Technical Skills",
                    "items": ["skill1", "skill2"]
                }}
            ],
            "experience": [
                {{
                    "title": "Experience Title",
                    "company": "Company/Project",
                    "duration": "Date",
                    "description": "Bullet point description",
                    "achievements": ["achievement1", "achievement2"]
                }}
            ],
            "projects": [
                {{
                    "title": "Project Title",
                    "description": "Project description",
                    "technologies": ["tech1", "tech2"],
                    "outcomes": ["outcome1", "outcome2"]
                }}
            ],
            "education": {{
                "degree": "Degree",
                "institution": "Institution",
                "year": "Year"
            }}
        }}
        """
        
        try:
            model = genai.GenerativeModel('gemini-2.5-flash')
            response = model.generate_content(prompt)
            
            # Parse JSON response
            content = response.text.strip()
            # Remove markdown code blocks
            content = content.replace('```json', '').replace('```', '').strip()
            
            resume_data = json.loads(content)
            
            # Enhance with actual data
            resume_data['verification'] = {
                'skills_verified': len([s for s in skills if s.get('confidence_score', 0) >= 0.7]),
                'total_skills': len(skills),
                'modules_completed': sum(1 for exp in experiences 
                                       if exp['type'] == 'learning_project'),
                'taikens_completed': sum(1 for exp in experiences 
                                        if exp['type'] == 'interactive_experience'),
                'generated_at': datetime.now().isoformat()
            }
            
            return resume_data
            
        except Exception as e:
            print(f"[RESUME] AI generation failed: {e}")
            # Return template resume
            return ResumeService._get_template_resume(profile, skills, experiences, target_role)
    
    @staticmethod
    def _get_template_resume(profile: Dict, skills: List[Dict], 
                            experiences: List[Dict], target_role: str) -> Dict:
        """Get template resume when AI fails"""
        technical_skills = [s['skill_name'] for s in skills if s.get('confidence_score', 0) >= 0.5]
        
        return {
            "personal_info": {
                "name": profile.get('username', 'Professional'),
                "title": f"Aspiring {target_role}",
                "summary": f"Passionate learner focused on becoming a {target_role}. "
                          f"Completed {len([e for e in experiences if e['type']=='learning_project'])} "
                          f"learning projects with demonstrated skills in {', '.join(technical_skills[:3])}.",
                "contact": {
                    "email": profile.get('email', ''),
                    "location": profile.get('location', ''),
                    "portfolio": f"pearl-agent.com/profile/{profile.get('user_id')}"
                }
            },
            "skills": [
                {
                    "category": "Technical Skills",
                    "items": technical_skills[:10]
                },
                {
                    "category": "Soft Skills",
                    "items": ["Communication", "Problem Solving", "Teamwork", "Adaptability"]
                }
            ],
            "experience": [
                {
                    "title": "Learning Projects",
                    "company": "PEARL Learning Platform",
                    "duration": "Recent",
                    "description": "Completed structured learning modules in relevant technologies",
                    "achievements": [
                        f"Mastered {len([s for s in skills if s.get('confidence_score', 0) >= 0.8])} technical skills",
                        f"Completed {len(experiences)} practical learning experiences",
                        "Demonstrated consistent learning progress"
                    ]
                }
            ],
            "projects": [
                {
                    "title": "Skill Development Portfolio",
                    "description": "Collection of completed learning modules and projects",
                    "technologies": technical_skills[:5],
                    "outcomes": [
                        "Built foundation in target role competencies",
                        "Demonstrated practical application of skills",
                        "Showcased continuous learning capability"
                    ]
                }
            ],
            "education": {
                "degree": "Ongoing Skill Development",
                "institution": "PEARL Platform",
                "year": "Present"
            },
            "verification": {
                'skills_verified': len([s for s in skills if s.get('confidence_score', 0) >= 0.7]),
                'total_skills': len(skills),
                'modules_completed': sum(1 for exp in experiences 
                                       if exp['type'] == 'learning_project'),
                'taikens_completed': sum(1 for exp in experiences 
                                        if exp['type'] == 'interactive_experience'),
                'generated_at': datetime.now().isoformat()
            }
        }
    
    @staticmethod
    def _format_resume(resume_data: Dict) -> Dict:
        """Format resume for different output types"""
        # HTML format
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 20px; }}
                .header {{ text-align: center; border-bottom: 2px solid #333; padding-bottom: 20px; margin-bottom: 30px; }}
                .name {{ font-size: 28px; font-weight: bold; color: #333; }}
                .title {{ font-size: 18px; color: #666; margin: 10px 0; }}
                .section {{ margin-bottom: 25px; }}
                .section-title {{ font-size: 20px; font-weight: bold; color: #333; border-bottom: 1px solid #ccc; padding-bottom: 5px; margin-bottom: 15px; }}
                .skill-category {{ margin-bottom: 15px; }}
                .skill-items {{ display: flex; flex-wrap: wrap; gap: 8px; }}
                .skill-tag {{ background: #f0f0f0; padding: 5px 10px; border-radius: 15px; font-size: 14px; }}
                .experience-item {{ margin-bottom: 20px; }}
                .experience-title {{ font-weight: bold; }}
                .experience-company {{ color: #666; }}
                .experience-duration {{ color: #999; font-size: 14px; }}
                .achievement-list {{ padding-left: 20px; }}
                .verification {{ background: #f8f9fa; padding: 15px; border-radius: 8px; margin-top: 30px; font-size: 14px; }}
            </style>
        </head>
        <body>
            <div class="header">
                <div class="name">{resume_data['personal_info']['name']}</div>
                <div class="title">{resume_data['personal_info']['title']}</div>
                <div>{resume_data['personal_info']['summary']}</div>
                <div style="margin-top: 10px;">
                    {resume_data['personal_info']['contact'].get('email', '')} | 
                    {resume_data['personal_info']['contact'].get('location', '')}
                </div>
            </div>
            
            <div class="section">
                <div class="section-title">Skills</div>
                {''.join([f'''
                <div class="skill-category">
                    <div style="font-weight: bold; margin-bottom: 8px;">{cat['category']}</div>
                    <div class="skill-items">
                        {''.join([f'<span class="skill-tag">{item}</span>' for item in cat['items'][:15]])}
                    </div>
                </div>
                ''' for cat in resume_data['skills']])}
            </div>
            
            <div class="section">
                <div class="section-title">Experience</div>
                {''.join([f'''
                <div class="experience-item">
                    <div class="experience-title">{exp['title']}</div>
                    <div class="experience-company">{exp['company']} | <span class="experience-duration">{exp['duration']}</span></div>
                    <div style="margin-top: 8px;">{exp['description']}</div>
                    <ul class="achievement-list">
                        {''.join([f'<li>{ach}</li>' for ach in exp.get('achievements', [])[:3]])}
                    </ul>
                </div>
                ''' for exp in resume_data['experience']])}
            </div>
            
            <div class="verification">
                <strong>Verified by PEARL Platform</strong><br>
                Skills Verified: {resume_data['verification']['skills_verified']}/{resume_data['verification']['total_skills']}<br>
                Modules Completed: {resume_data['verification']['modules_completed']}<br>
                Generated: {datetime.fromisoformat(resume_data['verification']['generated_at'].replace('Z', '+00:00')).strftime('%B %d, %Y')}
            </div>
        </body>
        </html>
        """
        
        # Plain text format
        text = f"""
        {resume_data['personal_info']['name']}
        {resume_data['personal_info']['title']}
        
        Summary:
        {resume_data['personal_info']['summary']}
        
        Contact:
        Email: {resume_data['personal_info']['contact'].get('email', '')}
        Location: {resume_data['personal_info']['contact'].get('location', '')}
        
        Skills:
        {chr(10).join([f"- {cat['category']}: {', '.join(cat['items'][:10])}" for cat in resume_data['skills']])}
        
        Experience:
        {chr(10).join([f"- {exp['title']} at {exp['company']} ({exp['duration']})" for exp in resume_data['experience']])}
        
        Verified by PEARL Platform:
        - Skills Verified: {resume_data['verification']['skills_verified']}/{resume_data['verification']['total_skills']}
        - Modules Completed: {resume_data['verification']['modules_completed']}
        - Generated: {datetime.fromisoformat(resume_data['verification']['generated_at'].replace('Z', '+00:00')).strftime('%B %d, %Y')}
        """
        
        return {
            "html": html,
            "text": text,
            "json": resume_data
        }
    
    @staticmethod
    def _create_download_link(resume_data: Dict) -> str:
        """Create download link for resume"""
        # This would typically generate a PDF and return a URL
        # For now, return a placeholder
        return f"https://pearl-agent.com/api/resume/download/{resume_data['verification']['generated_at']}"


# Global instance
resume_service = ResumeService()