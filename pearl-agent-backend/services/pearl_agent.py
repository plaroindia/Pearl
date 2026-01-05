"""
PEARL Agent - Agentic Career Mentor Core
Implements module decomposition, action routing, and progress enforcement
"""

from typing import List, Dict, Optional
import google.generativeai as genai
from config import get_settings
import json
import re

settings = get_settings()
genai.configure(api_key=settings.GEMINI_API_KEY)


class ModuleDecompositionEngine:
    """Breaks skills into granular, actionable learning modules"""
    
    @staticmethod
    def decompose_skill(skill: str, difficulty: str = "medium") -> Dict:
        """
        Decompose a skill into bite-sized modules with clear learning paths
        Returns dict with modules, prerequisites and estimated time
        """
        prompt = f"""
You are PEARL, an agentic career mentor. Break down the skill "{skill}" into 4-6 granular learning modules.

Each module must be:
- Specific and actionable
- Completable in 2-4 hours
- Build on previous modules
- Have clear completion criteria

Return ONLY this JSON structure:
{{
    "skill": "{skill}",
    "total_modules": 5,
    "estimated_hours": 15,
    "modules": [
        {{
            "module_id": 1,
            "name": "Module name",
            "description": "What you'll learn",
            "prerequisites": [],
            "estimated_hours": 3,
            "difficulty": "beginner",
            "learning_objectives": ["objective1", "objective2"],
            "completion_criteria": "What proves you've mastered this"
        }}
    ]
}}

Difficulty level: {difficulty}
"""
        
        try:
            model = genai.GenerativeModel(
                'gemini-2.5-flash',
                generation_config={"temperature": 0.3}
            )
            
            response = model.generate_content(prompt)
            content = response.text
            content = re.sub(r'```json\s*', '', content)
            content = re.sub(r'```\s*', '', content).strip()
            
            parsed = json.loads(content)
            return parsed
            
        except Exception as e:
            print(f"[ERROR] Module decomposition failed: {e}")
            # Fallback structure
            return {
                "skill": skill,
                "total_modules": 4,
                "estimated_hours": 12,
                "modules": [
                    {
                        "module_id": i,
                        "name": f"{skill} - Part {i}",
                        "description": f"Learn core concepts of {skill}",
                        "prerequisites": [i-1] if i > 1 else [],
                        "estimated_hours": 3,
                        "difficulty": difficulty,
                        "learning_objectives": [f"Understand {skill} basics"],
                        "completion_criteria": "Complete practice exercises"
                    }
                    for i in range(1, 5)
                ]
            }


class ActionRouter:
    """Maps modules to specific action types with real external resources"""
    
    ACTION_TYPES = {
        "byte": "Quick 2-5 min explainer",
        "course": "Structured learning (30-60 min)",
        "taiken": "Hands-on practice/simulation",
        "checkpoint": "Verification quiz/task"
    }
    
    @staticmethod
    def _generate_checkpoint_questions(skill: str, module: Dict) -> List[Dict]:
        """
        Generate real checkpoint questions using Gemini API
        Falls back to structured questions if API fails
        """
        prompt = f"""
Generate 4 challenging multiple-choice questions for a {skill} learning module.

Module: {module.get('name', 'Learning')}
Objectives: {', '.join(module.get('learning_objectives', []))}

Return ONLY this JSON array with no markdown:
[
    {{
        "question": "Question text about {skill}",
        "options": ["Correct answer", "Plausible wrong answer", "Plausible wrong answer", "Plausible wrong answer"],
        "correct_index": 0,
        "explanation": "Why this is correct..."
    }},
    ...
]

Requirements:
- Questions must be specific to {skill}
- Options must be realistic (not obviously wrong)
- Mix of conceptual and practical questions
- Pass threshold should be 70% (3/4 correct)
"""
        
        try:
            model = genai.GenerativeModel(
                'gemini-2.5-flash',
                generation_config={"temperature": 0.7}
            )
            
            response = model.generate_content(prompt)
            content = response.text
            
            # Clean markdown
            content = re.sub(r'```json\s*', '', content)
            content = re.sub(r'```\s*', '', content).strip()
            
            questions = json.loads(content)
            
            # Validate structure
            if isinstance(questions, list) and len(questions) > 0:
                valid_questions = []
                for q in questions:
                    if all(k in q for k in ['question', 'options', 'correct_index', 'explanation']):
                        if isinstance(q['options'], list) and len(q['options']) >= 4:
                            valid_questions.append(q)
                
                if valid_questions:
                    return valid_questions[:4]  # Return max 4 questions
            
            print(f"[WARNING] Invalid checkpoint format, using structured fallback")
            
        except Exception as e:
            print(f"[WARNING] Checkpoint generation failed: {e}, using fallback")
        
        # Structured fallback with real questions
        return [
            {
                "question": f"What is a primary use case for {skill}?",
                "options": [
                    "Building scalable applications",
                    "Replacing operating systems",
                    "Creating hardware drivers",
                    "Manufacturing physical devices"
                ],
                "correct_index": 0,
                "explanation": f"{skill} is commonly used for building scalable and efficient applications."
            },
            {
                "question": f"Which concept is fundamental to understanding {skill}?",
                "options": [
                    "Understanding core principles and patterns",
                    "Physical circuit design",
                    "Hardware manufacturing",
                    "Network cables and routers"
                ],
                "correct_index": 0,
                "explanation": f"Understanding core concepts is essential when working with {skill}."
            },
            {
                "question": f"How do you best learn {skill}?",
                "options": [
                    "Through hands-on projects and practical examples",
                    "Only by reading documentation",
                    "By watching videos passively",
                    "Through memorization alone"
                ],
                "correct_index": 0,
                "explanation": "Hands-on practice and real-world projects are the most effective way to master skills."
            },
            {
                "question": f"What is the next step after learning {skill} basics?",
                "options": [
                    "Build real projects and contribute to open source",
                    "Stop learning and find employment immediately",
                    "Only study theory without practice",
                    "Learn unrelated technologies"
                ],
                "correct_index": 0,
                "explanation": f"Progressive learning through projects helps solidify your {skill} skills."
            }
        ]
    
    @staticmethod
    def generate_actions(module: Dict, skill: str) -> Dict:
        """
        Generate 4 actions for a module: Byte, Course, Taiken, Checkpoint
        Returns real external resources
        """
        prompt = f"""
You are PEARL's action router. Generate 4 specific learning actions for this module.

Skill: {skill}
Module: {module['name']}
Objectives: {', '.join(module['learning_objectives'])}

Return ONLY this JSON:
{{
    "module_id": {module['module_id']},
    "actions": [
        {{
            "type": "byte",
            "title": "Quick intro title",
            "description": "What this covers",
            "platform": "YouTube / Article",
            "url": "Real URL or search query",
            "duration_minutes": 3,
            "completion_requirement": "Watch fully"
        }},
        {{
            "type": "course",
            "title": "Course name",
            "description": "What you'll learn",
            "platform": "Coursera / edX / YouTube Playlist / freeCodeCamp",
            "url": "Real URL or specific course name",
            "duration_minutes": 45,
            "completion_requirement": "Complete all sections"
        }},
        {{
            "type": "taiken",
            "title": "Hands-on task",
            "description": "What to build/do",
            "platform": "Replit / CodePen / Interactive simulator",
            "url": "Tool URL or specific platform",
            "duration_minutes": 60,
            "completion_requirement": "Submit working solution"
        }},
        {{
            "type": "checkpoint",
            "title": "Knowledge check",
            "description": "Verify understanding",
            "platform": "PEARL Quiz",
            "questions": [
                {{
                    "question": "Question text",
                    "options": ["A", "B", "C", "D"],
                    "correct_index": 0,
                    "explanation": "Why this is correct"
                }}
            ],
            "pass_threshold": 70
        }}
    ]
}}

CRITICAL: Provide real, specific resources. Use actual course names, YouTube channels, tools.
"""
        
        try:
            model = genai.GenerativeModel(
                'gemini-2.5-flash',
                generation_config={"temperature": 0.5}
            )
            
            response = model.generate_content(prompt)
            content = response.text
            content = re.sub(r'```json\s*', '', content)
            content = re.sub(r'```\s*', '', content).strip()
            
            parsed = json.loads(content)
            return parsed
            
        except Exception as e:
            print(f"[ERROR] Action routing failed: {e}")
            # Fallback actions
            return {
                "module_id": module['module_id'],
                "actions": [
                    {
                        "type": "byte",
                        "title": f"Quick {skill} Overview",
                        "description": "5-minute introduction",
                        "platform": "YouTube",
                        "url": f"https://youtube.com/results?search_query={skill.replace(' ', '+')}+tutorial",
                        "duration_minutes": 5,
                        "completion_requirement": "Watch fully"
                    },
                    {
                        "type": "course",
                        "title": f"{skill} Fundamentals",
                        "description": "Complete course",
                        "platform": "freeCodeCamp",
                        "url": f"https://www.freecodecamp.org/",
                        "duration_minutes": 60,
                        "completion_requirement": "Complete all lessons"
                    },
                    {
                        "type": "taiken",
                        "title": f"Build with {skill}",
                        "description": "Hands-on project",
                        "platform": "Replit",
                        "url": "https://replit.com/",
                        "duration_minutes": 90,
                        "completion_requirement": "Submit project"
                    },
                    {
                        "type": "checkpoint",
                        "title": "Module Assessment",
                        "description": "Test your knowledge",
                        "platform": "PEARL Quiz",
                        "questions": ActionRouter._generate_checkpoint_questions(skill, module),
                        "pass_threshold": 70
                    }
                ]
            }


class CheckpointSystem:
    """Validates module completion before progression"""
    
    @staticmethod
    def evaluate_checkpoint(checkpoint_data: Dict, user_answers: List[int]) -> Dict:
        """
        Evaluate user's checkpoint quiz answers
        Returns pass/fail and detailed feedback
        """
        questions = checkpoint_data.get('questions', [])
        
        if not questions or not user_answers:
            return {
                "passed": False,
                "score": 0,
                "feedback": "Invalid checkpoint data",
                "next_action": "retry"
            }
        
        correct_count = 0
        total = len(questions)
        feedback_items = []
        
        for i, (question, answer) in enumerate(zip(questions, user_answers)):
            correct_idx = question.get('correct_index', 0)
            is_correct = answer == correct_idx
            
            if is_correct:
                correct_count += 1
                feedback_items.append({
                    "question_num": i + 1,
                    "status": "correct",
                    "explanation": question.get('explanation', '')
                })
            else:
                feedback_items.append({
                    "question_num": i + 1,
                    "status": "incorrect",
                    "your_answer": answer,
                    "correct_answer": correct_idx,
                    "explanation": question.get('explanation', '')
                })
        
        score = (correct_count / total) * 100
        pass_threshold = checkpoint_data.get('pass_threshold', 70)
        passed = score >= pass_threshold
        
        return {
            "passed": passed,
            "score": score,
            "correct_count": correct_count,
            "total_questions": total,
            "feedback_items": feedback_items,
            "next_action": "advance" if passed else "retry",
            "message": "Great job! Module unlocked." if passed else "Review the material and try again."
        }
    
    @staticmethod
    def validate_action_completion(action: Dict, completion_data: Dict) -> bool:
        """
        Validate if user completed an action based on type
        """
        action_type = action.get('type')
        
        if action_type == 'byte':
            return completion_data.get('watched', False)
        
        elif action_type == 'course':
            return completion_data.get('completed', False)
        
        elif action_type == 'taiken':
            return bool(completion_data.get('submission'))
        
        elif action_type == 'checkpoint':
            return completion_data.get('passed', False)
        
        return False


class PEARLAgent:
    """Main orchestrator - drives the agentic learning loop"""
    
    def __init__(self):
        self.decomposer = ModuleDecompositionEngine()
        self.router = ActionRouter()
        self.checkpoint = CheckpointSystem()
    
    def create_learning_path(self, skill: str, current_confidence: float = 0.0) -> Dict:
        """
        Create complete learning path for a skill
        Returns modules with actions
        """
        print(f"[PEARL] Creating learning path for: {skill}")
        
        # Determine difficulty based on confidence
        difficulty = "beginner" if current_confidence < 0.3 else "intermediate" if current_confidence < 0.7 else "advanced"
        
        # Step 1: Decompose skill into modules
        decomposition = self.decomposer.decompose_skill(skill, difficulty)
        
        # Step 2: Generate actions for each module
        learning_path = {
            "skill": skill,
            "difficulty": difficulty,
            "total_modules": decomposition['total_modules'],
            "estimated_hours": decomposition['estimated_hours'],
            "current_module": 1,
            "modules": []
        }
        
        for module in decomposition['modules']:
            actions = self.router.generate_actions(module, skill)
            module['actions'] = actions['actions']
            module['status'] = 'locked' if module['module_id'] > 1 else 'active'
            module['completed'] = False
            learning_path['modules'].append(module)
        
        print(f"[PEARL] Learning path created: {len(learning_path['modules'])} modules")
        return learning_path
    
    def get_next_action(self, learning_path: Dict) -> Optional[Dict]:
        """
        Get the next action user should take
        Returns specific action with instructions
        """
        current_module = learning_path['current_module']
        
        for module in learning_path['modules']:
            if module['module_id'] == current_module:
                # Find first incomplete action
                for idx, action in enumerate(module['actions']):
                    if not action.get('completed', False):
                        return {
                            "module": module['name'],
                            "module_id": module['module_id'],
                            "action_index": idx,
                            "action": action,
                            "instruction": self._format_instruction(action)
                        }
        
        return None
    
    def _format_instruction(self, action: Dict) -> str:
        """Format action as clear instruction"""
        templates = {
            "byte": f"📱 Watch this {action['duration_minutes']}-minute explainer: {action['title']}",
            "course": f"📚 Complete this course: {action['title']} (~{action['duration_minutes']} min)",
            "taiken": f"⚡ Hands-on: {action['title']} - Build something real!",
            "checkpoint": f"✅ Prove your knowledge: {action['title']}"
        }
        
        return templates.get(action['type'], action['title'])
    
    def advance_progress(self, learning_path: Dict, module_id: int, action_index: int) -> Dict:
        """
        Mark action complete and advance progress
        Returns updated state
        """
        for module in learning_path['modules']:
            if module['module_id'] == module_id:
                if action_index < len(module['actions']):
                    module['actions'][action_index]['completed'] = True
                
                # Check if all actions in module completed
                all_complete = all(a.get('completed', False) for a in module['actions'])
                
                if all_complete:
                    module['completed'] = True
                    module['status'] = 'completed'
                    
                    # Unlock next module
                    if module_id < learning_path['total_modules']:
                        next_module = learning_path['modules'][module_id]  # module_id is 1-indexed
                        next_module['status'] = 'active'
                        learning_path['current_module'] = module_id + 1
                    else:
                        learning_path['status'] = 'completed'
                    
                    return {
                        "success": True,
                        "message": f"🎉 Module {module_id} completed! Next module unlocked.",
                        "next_module": module_id + 1 if module_id < learning_path['total_modules'] else None
                    }
        
        return {
            "success": True,
            "message": "Progress updated",
            "next_module": learning_path['current_module']
        }


# Global instance
pearl = PEARLAgent()
