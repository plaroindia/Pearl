import google.generativeai as genai
from config import get_settings
import json
import re

settings = get_settings()
genai.configure(api_key=settings.GEMINI_API_KEY)

class GeminiService:
    def __init__(self):
        self.model = genai.GenerativeModel('gemini-2.5-flash')
    
    @staticmethod
    def parse_jd(jd_text: str) -> dict:
        """Parse job description with robust error handling"""
        prompt = f"""
Extract structured information from this job description.
You must return ONLY valid JSON with NO markdown, NO backticks, NO extra text.

Required structure:
{{
    "role": "job title here",
    "required_skills": ["skill1", "skill2", "skill3"],
    "experience_level": "entry",
    "soft_skills": ["communication", "teamwork"],
    "key_responsibilities": ["responsibility1", "responsibility2"]
}}

Job Description:
{jd_text}

Return JSON only:
"""
        
        try:
            model = genai.GenerativeModel(
                'gemini-2.5-flash',
                generation_config={
                    "temperature": 0.1,
                }
            )
            
            response = model.generate_content(prompt)
            content = response.text
            
            print(f"[DEBUG] Raw Gemini response: {content}")
            
            # Strip markdown code blocks if present
            content = re.sub(r'```json\s*', '', content)
            content = re.sub(r'```\s*', '', content)
            content = content.strip()
            
            parsed = json.loads(content)
            
            # Validate required fields
            required_fields = ["role", "required_skills", "experience_level"]
            for field in required_fields:
                if field not in parsed:
                    print(f"[WARNING] Missing field: {field}")
                    parsed[field] = "Not specified" if field == "role" else []
            
            # Ensure defaults
            parsed.setdefault("soft_skills", [])
            parsed.setdefault("key_responsibilities", [])
            
            print(f"[DEBUG] Parsed JD: {parsed}")
            return parsed
            
        except json.JSONDecodeError as e:
            print(f"[ERROR] JSON decode failed: {e}")
            print(f"[ERROR] Content was: {content}")
            # Return fallback structure
            return {
                "role": "Backend Developer",
                "required_skills": ["Python", "APIs", "SQL"],
                "experience_level": "entry",
                "soft_skills": ["communication"],
                "key_responsibilities": ["Build APIs", "Write code"]
            }
        except Exception as e:
            print(f"[ERROR] Gemini API failed: {e}")
            raise
    
    @staticmethod
    def analyze_skill_gap(required_skills: list, user_skills: dict) -> dict:
        """Analyze skill gaps with fallback handling"""
        try:
            # Build skill comparison
            skills_comparison = []
            for skill in required_skills:
                current = user_skills.get(skill, 0.0)
                skills_comparison.append(f"{skill}: current={current}")
            
            prompt = f"""
Analyze these skill gaps. Return ONLY valid JSON, no markdown.

Required skills vs Current levels:
{chr(10).join(skills_comparison)}

Return this exact structure:
{{
    "gaps": [
        {{
            "skill": "skill_name",
            "current_level": 0.5,
            "required_level": 0.8,
            "gap_severity": "medium",
            "learning_weeks": 3,
            "priority": 1
        }}
    ],
    "overall_readiness": 0.6
}}
"""
            
            model = genai.GenerativeModel(
                'gemini-2.5-flash',
                generation_config={
                    "temperature": 0.2,
                }
            )
            
            response = model.generate_content(prompt)
            content = response.text
            content = re.sub(r'```json\s*', '', content)
            content = re.sub(r'```\s*', '', content).strip()
            
            parsed = json.loads(content)
            
            # Validate structure
            if "gaps" not in parsed:
                parsed["gaps"] = []
            if "overall_readiness" not in parsed:
                parsed["overall_readiness"] = 0.5
            
            return parsed
            
        except Exception as e:
            print(f"[ERROR] Skill gap analysis failed: {e}")
            # Fallback: simple calculation
            gaps = []
            for i, skill in enumerate(required_skills[:5]):
                current = user_skills.get(skill, 0.0)
                gaps.append({
                    "skill": skill,
                    "current_level": float(current),
                    "required_level": 0.8,
                    "gap_severity": "high" if current < 0.4 else "medium" if current < 0.7 else "low",
                    "learning_weeks": int((0.8 - current) * 10),
                    "priority": i + 1
                })
            
            avg_readiness = sum(user_skills.get(s, 0) for s in required_skills) / len(required_skills) if required_skills else 0.5
            
            return {
                "gaps": gaps,
                "overall_readiness": float(avg_readiness)
            }
    
    @staticmethod
    def generate_roadmap(target_role: str, skill_gaps: list, user_name: str = "Student") -> dict:
        """Generate roadmap with fallback"""
        try:
            gaps_text = "\n".join([f"- {g['skill']}: {g['gap_severity']} gap, {g['learning_weeks']} weeks" for g in skill_gaps[:5]])
            
            prompt = f"""
Create a 4-week learning roadmap for {target_role}.

Skill gaps:
{gaps_text}

Return ONLY this JSON structure, no markdown:
{{
    "total_weeks": 4,
    "weeks": [
        {{
            "week": 1,
            "title": "Week 1: Foundations",
            "skills_focus": ["skill1", "skill2"],
            "learning_resources": [
                {{"type": "course", "title": "Python Basics", "duration": "3 hours"}},
                {{"type": "taiken", "title": "Practice Scenario"}}
            ],
            "milestone": "Complete basic tutorials"
        }}
    ]
}}
"""
            
            model = genai.GenerativeModel(
                'gemini-2.5-flash',
                generation_config={
                    "temperature": 0.6,
                }
            )
            
            response = model.generate_content(prompt)
            content = response.text
            content = re.sub(r'```json\s*', '', content)
            content = re.sub(r'```\s*', '', content).strip()
            
            parsed = json.loads(content)
            
            if "weeks" not in parsed:
                raise ValueError("Missing weeks field")
            
            return parsed
            
        except Exception as e:
            print(f"[ERROR] Roadmap generation failed: {e}")
            # Fallback roadmap
            return {
                "total_weeks": 4,
                "weeks": [
                    {
                        "week": i + 1,
                        "title": f"Week {i + 1}: {['Foundations', 'Core Skills', 'Advanced Topics', 'Projects'][i]}",
                        "skills_focus": [g['skill'] for g in skill_gaps[i:i+2]],
                        "learning_resources": [
                            {"type": "course", "title": f"Learn {g['skill']}", "duration": "3 hours"}
                            for g in skill_gaps[i:i+2]
                        ],
                        "milestone": f"Complete {['basics', 'intermediate', 'advanced', 'project'][i]} level"
                    }
                    for i in range(4)
                ]
            }
    
    @staticmethod
    def generate_practice_task(skill: str, difficulty: str = "medium") -> dict:
        """Generate practice task with fallback"""
        try:
            prompt = f"""
Generate a practice task for {skill} at {difficulty} level.

Return ONLY this JSON, no markdown:
{{
    "skill_focus": "{skill}",
    "task_type": "coding",
    "difficulty": "{difficulty}",
    "description": "Clear task description here",
    "expected_output": "What a good solution should have",
    "evaluation_criteria": ["criterion1", "criterion2"],
    "estimated_time": "30 minutes"
}}
"""
            
            model = genai.GenerativeModel(
                'gemini-2.5-flash',
                generation_config={
                    "temperature": 0.7,
                }
            )
            
            response = model.generate_content(prompt)
            content = response.text
            content = re.sub(r'```json\s*', '', content)
            content = re.sub(r'```\s*', '', content).strip()
            
            return json.loads(content)
            
        except Exception as e:
            print(f"[ERROR] Task generation failed: {e}")
            return {
                "skill_focus": skill,
                "task_type": "coding",
                "difficulty": difficulty,
                "description": f"Write a simple program that demonstrates {skill}. Include error handling and comments.",
                "expected_output": "Working code with proper structure",
                "evaluation_criteria": ["Code works", "Good structure", "Error handling"],
                "estimated_time": "30 minutes"
            }
    
    @staticmethod
    def evaluate_submission(task_description: str, submission: str, skill: str) -> dict:
        """Evaluate submission with fallback"""
        try:
            prompt = f"""
Evaluate this submission. Return ONLY JSON, no markdown.

Task: {task_description}
Submission: {submission}

Return:
{{
    "score": 75,
    "feedback": "Good effort. Here's what worked...",
    "strengths": ["strength1", "strength2"],
    "improvements": ["area1", "area2"],
    "skill_confidence_delta": 0.1
}}
"""
            
            model = genai.GenerativeModel(
                'gemini-2.5-flash',
                generation_config={
                    "temperature": 0.4,
                }
            )
            
            response = model.generate_content(prompt)
            content = response.text
            content = re.sub(r'```json\s*', '', content)
            content = re.sub(r'```\s*', '', content).strip()
            
            parsed = json.loads(content)
            
            # Ensure score is numeric
            if "score" in parsed:
                parsed["score"] = float(parsed["score"])
            
            return parsed
            
        except Exception as e:
            print(f"[ERROR] Evaluation failed: {e}")
            # Simple scoring
            score = min(100, len(submission) * 2)  # Basic heuristic
            return {
                "score": score,
                "feedback": f"You submitted {len(submission)} characters. Good start!",
                "strengths": ["Attempted the task", "Submitted something"],
                "improvements": ["Add more detail", "Include examples"],
                "skill_confidence_delta": 0.05 if score > 50 else 0.0
            }