from supabase import create_client, Client
from config import get_settings
from functools import lru_cache

settings = get_settings()


@lru_cache()
def get_supabase() -> Client:
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)


# Helper functions for common queries
class SupabaseHelper:
    def __init__(self):
        self.client = get_supabase()
    
    def get_user_skills(self, user_id: str):
        response = self.client.table('user_skill_memory') \
            .select('*') \
            .eq('user_id', user_id) \
            .execute()
        return response.data
    
    def create_session(self, user_id: str, jd_text: str):
        response = self.client.table('ai_agent_sessions') \
            .insert({
                'user_id': user_id,
                'jd_text': jd_text,
                'status': 'active'
            }) \
            .execute()
        return response.data[0]
    
    def update_session(self, session_id: str, updates: dict):
        response = self.client.table('ai_agent_sessions') \
            .update(updates) \
            .eq('id', session_id) \
            .execute()
        return response.data[0]
    
    def save_roadmap(self, session_id: str, user_id: str, target_role: str, roadmap_data: dict):
        response = self.client.table('ai_roadmap') \
            .insert({
                'session_id': session_id,
                'user_id': user_id,
                'target_role': target_role,
                'roadmap_data': roadmap_data,
                'duration_weeks': len(roadmap_data.get('weeks', []))
            }) \
            .execute()
        return response.data[0]
    
    def save_practice_task(self, session_id: str, user_id: str, task_data: dict):
        response = self.client.table('ai_practice_tasks') \
            .insert({
                'session_id': session_id,
                'user_id': user_id,
                'skill_focus': task_data['skill_focus'],
                'task_type': task_data['task_type'],
                'task_description': task_data['description'],
                'difficulty': task_data['difficulty']
            }) \
            .execute()
        return response.data[0]
    
    def save_task_result(self, task_id: str, user_id: str, result_data: dict):
        response = self.client.table('ai_task_results') \
            .insert({
                'task_id': task_id,
                'user_id': user_id,
                'submission': result_data['submission'],
                'score': result_data['score'],
                'feedback': result_data['feedback'],
                'skill_improvement': result_data.get('skill_improvement', {})
            }) \
            .execute()
        return response.data[0]
    
    def update_skill_confidence(self, user_id: str, skill_name: str, new_confidence: float):
        response = self.client.table('user_skill_memory') \
            .update({
                'confidence_score': new_confidence
            }) \
            .eq('user_id', user_id) \
            .eq('skill_name', skill_name) \
            .execute()
        return response.data
