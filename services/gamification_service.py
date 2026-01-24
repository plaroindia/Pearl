"""
Gamification Service - Handles points, streaks, achievements
"""
from typing import Dict, List, Optional
from datetime import datetime, timedelta
from database import EnhancedSupabaseHelper
import json

db = EnhancedSupabaseHelper()


class GamificationService:
    """Handles all gamification features"""
    
    # Achievement definitions
    ACHIEVEMENTS = {
        # Learning milestones
        "first_module": {
            "title": "First Step",
            "description": "Complete your first learning module",
            "points": 100,
            "icon": "🥇"
        },
        "week_streak": {
            "title": "Week Warrior",
            "description": "Maintain a 7-day learning streak",
            "points": 250,
            "icon": "🔥"
        },
        "skill_master": {
            "title": "Skill Master",
            "description": "Reach 80% confidence in any skill",
            "points": 300,
            "icon": "🎯"
        },
        # Content creation
        "first_post": {
            "title": "Voice Heard",
            "description": "Create your first post",
            "points": 50,
            "icon": "📢"
        },
        "taiken_creator": {
            "title": "Experience Creator",
            "description": "Create your first Taiken",
            "points": 500,
            "icon": "🎮"
        },
        # Social
        "first_follower": {
            "title": "Making Connections",
            "description": "Get your first follower",
            "points": 100,
            "icon": "👥"
        },
        "community_helper": {
            "title": "Community Helper",
            "description": "Help 10 other learners",
            "points": 400,
            "icon": "🤝"
        },
        # Progression
        "roadmap_complete": {
            "title": "Journey Complete",
            "description": "Complete a full learning roadmap",
            "points": 1000,
            "icon": "🏆"
        },
        "freelance_ready": {
            "title": "Freelance Ready",
            "description": "Become eligible for freelance work",
            "points": 1500,
            "icon": "💼"
        }
    }
    
    @staticmethod
    def award_achievement(user_id: str, achievement_key: str, 
                         metadata: Optional[Dict] = None) -> bool:
        """Award achievement to user"""
        if achievement_key not in GamificationService.ACHIEVEMENTS:
            print(f"[GAMIFICATION] Unknown achievement: {achievement_key}")
            return False
        
        achievement = GamificationService.ACHIEVEMENTS[achievement_key]
        
        try:
            # Check if already earned
            # Note: You'll need to implement this check based on your schema
            # For now, we'll always award
            
            # Award points
            db.award_plaro_points(
                user_id=user_id,
                source='achievement',
                points=achievement['points'],
                related_content_type='achievement',
                related_content_id=achievement_key,
                reason=f"Achievement: {achievement['title']}"
            )
            
            # Log achievement (you'll need to create this table)
            # achievement_data = {
            #     'user_id': user_id,
            #     'achievement_key': achievement_key,
            #     'title': achievement['title'],
            #     'description': achievement['description'],
            #     'points': achievement['points'],
            #     'icon': achievement['icon'],
            #     'earned_at': datetime.now().isoformat(),
            #     'metadata': metadata or {}
            # }
            
            print(f"[GAMIFICATION] 🏆 Awarded {achievement['title']} to {user_id}")
            return True
            
        except Exception as e:
            print(f"[GAMIFICATION ERROR] Award failed: {e}")
            return False
    
    @staticmethod
    def check_learning_achievements(user_id: str) -> List[str]:
        """Check and award learning-related achievements"""
        awarded = []
        
        try:
            # Get user progress
            progress_response = db.client.table('ai_module_progress').select('*').eq(
                'user_id', user_id
            ).execute()
            
            # Check first module
            if progress_response.data and len(progress_response.data) > 0:
                completed = [p for p in progress_response.data if p.get('status') == 'completed']
                if len(completed) >= 1:
                    GamificationService.award_achievement(user_id, "first_module")
                    awarded.append("first_module")
            
            # Check streak
            profile = db.get_user_profile(user_id)
            if profile and profile.get('streak_count', 0) >= 7:
                GamificationService.award_achievement(user_id, "week_streak")
                awarded.append("week_streak")
            
            # Check skill mastery
            skills = db.get_user_skills(user_id)
            for skill in skills:
                if skill.get('confidence_score', 0) >= 0.8:
                    GamificationService.award_achievement(user_id, "skill_master", 
                                                         {"skill": skill.get('skill_name')})
                    awarded.append("skill_master")
                    break
            
            return awarded
            
        except Exception as e:
            print(f"[GAMIFICATION ERROR] Check achievements failed: {e}")
            return []
    
    @staticmethod
    def get_leaderboard(limit: int = 20) -> List[Dict]:
        """Get leaderboard of top users"""
        try:
            response = db.client.table('user_profile_rank').select(
                'user_id, total_points, rank_level'
            ).order('total_points', desc=True).limit(limit).execute()
            
            leaderboard = []
            for rank, user in enumerate(response.data or [], 1):
                # Get user profile for name
                profile = db.get_user_profile(user['user_id'])
                leaderboard.append({
                    'rank': rank,
                    'user_id': user['user_id'],
                    'username': profile.get('username', 'Anonymous') if profile else 'Anonymous',
                    'points': user.get('total_points', 0),
                    'rank_level': user.get('rank_level', 'beginner'),
                    'profile_pic': profile.get('profile_pic') if profile else None
                })
            
            return leaderboard
            
        except Exception as e:
            print(f"[GAMIFICATION ERROR] Get leaderboard failed: {e}")
            return []
    
    @staticmethod
    def get_user_gamification_summary(user_id: str) -> Dict:
        """Get complete gamification summary for user"""
        try:
            # Get points
            points_summary = db.get_user_plaro_points(user_id)
            
            # Get streak
            profile = db.get_user_profile(user_id)
            streak = profile.get('streak_count', 0) if profile else 0
            
            # Calculate next milestones
            current_points = points_summary.get('total_points', 0)
            next_milestones = [
                {"points": 1000, "title": "Bronze Learner", "reward": "Profile badge"},
                {"points": 5000, "title": "Silver Scholar", "reward": "Early access to features"},
                {"points": 10000, "title": "Gold Master", "reward": "Mentor status"}
            ]
            
            # Filter upcoming milestones
            upcoming = [m for m in next_milestones if m['points'] > current_points]
            next_milestone = upcoming[0] if upcoming else None
            
            # Get recent achievements (placeholder)
            recent_achievements = [
                {"title": "First Module", "points": 100, "date": "2024-01-15"},
                {"title": "3-Day Streak", "points": 50, "date": "2024-01-18"}
            ]
            
            # Calculate daily challenge progress
            today = datetime.now().date()
            today_start = datetime.combine(today, datetime.min.time())
            
            today_events = db.client.table('user_content_events').select('*').eq(
                'user_id', user_id
            ).gte('created_at', today_start.isoformat()).execute()
            
            daily_tasks = {
                'complete_module': len([e for e in (today_events.data or []) 
                                      if e.get('event_type') == 'complete' 
                                      and e.get('content_type') == 'module']) > 0,
                'practice_skill': len([e for e in (today_events.data or []) 
                                     if e.get('event_type') == 'practice_submit']) > 0,
                'engage_content': len([e for e in (today_events.data or []) 
                                     if e.get('event_type') in ['like', 'comment', 'share']]) > 0
            }
            
            daily_progress = sum(1 for completed in daily_tasks.values() if completed)
            daily_percentage = (daily_progress / 3) * 100
            
            return {
                'points_summary': points_summary,
                'streak': streak,
                'next_milestone': next_milestone,
                'recent_achievements': recent_achievements,
                'daily_challenge': {
                    'progress': daily_progress,
                    'total': 3,
                    'percentage': daily_percentage,
                    'tasks': daily_tasks,
                    'reward': 50 if daily_progress == 3 else 0
                },
                'leaderboard_position': GamificationService._get_user_leaderboard_position(user_id)
            }
            
        except Exception as e:
            print(f"[GAMIFICATION ERROR] Get summary failed: {e}")
            return {}
    
    @staticmethod
    def _get_user_leaderboard_position(user_id: str) -> Optional[int]:
        """Get user's position on leaderboard"""
        try:
            leaderboard = GamificationService.get_leaderboard(limit=100)
            for i, entry in enumerate(leaderboard, 1):
                if entry['user_id'] == user_id:
                    return i
            return None
        except Exception as e:
            print(f"[GAMIFICATION ERROR] Get position failed: {e}")
            return None
    
    @staticmethod
    def process_daily_rewards(user_id: str) -> Dict:
        """Process daily rewards and streak updates"""
        try:
            # Update streak
            streak_updated = db.update_streak(user_id)
            
            # Award daily login bonus
            profile = db.get_user_profile(user_id)
            streak = profile.get('streak_count', 0) if profile else 0
            
            # Calculate bonus based on streak
            base_points = 10
            streak_bonus = min(streak * 5, 50)  # Max 50 bonus points
            total_points = base_points + streak_bonus
            
            db.award_plaro_points(
                user_id=user_id,
                source='daily_login',
                points=total_points,
                reason=f'Daily login (Streak: {streak} days)'
            )
            
            # Check daily challenge completion
            daily_summary = GamificationService.get_user_gamification_summary(user_id)
            daily_challenge = daily_summary.get('daily_challenge', {})
            
            if daily_challenge.get('progress', 0) == 3:
                db.award_plaro_points(
                    user_id=user_id,
                    source='daily_challenge',
                    points=50,
                    reason='Completed all daily challenges'
                )
            
            return {
                'success': True,
                'streak_updated': streak_updated,
                'streak_days': streak,
                'daily_points': total_points,
                'challenge_completed': daily_challenge.get('progress', 0) == 3
            }
            
        except Exception as e:
            print(f"[GAMIFICATION ERROR] Process rewards failed: {e}")
            return {
                'success': False,
                'error': str(e)
            }


# Global instance
gamification_service = GamificationService()