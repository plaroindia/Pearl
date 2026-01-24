"""
Content Provider Service
Manages curated content from YouTube, freeCodeCamp, and MIT OpenCourseWare
Provides structured learning paths based on user preferences
"""

from typing import List, Dict, Optional


class ContentProviderService:
    """
    Manages curated, high-quality content from trusted educational providers:
    - YouTube: Primary video content source
    - freeCodeCamp: Hands-on practice and certification
    - MIT OpenCourseWare: Rigorous academic depth
    """
    
    # Comprehensive curated content database
    CONTENT_DATABASE = {
        "Python": {
            "video": [
                {
                    "provider_id": "yt_python_001",
                    "name": "YouTube",
                    "content_type": "video",
                    "title": "Python Full Course - freeCodeCamp",
                    "difficulty": "beginner",
                    "duration": 270,
                    "source_url": "https://www.youtube.com/watch?v=rfscVS0vtbE",
                    "metadata": {
                        "channel": "freeCodeCamp.org",
                        "views": "50M+",
                        "rating": 4.9,
                        "topics": ["basics", "data structures", "OOP", "modules"]
                    }
                },
                {
                    "provider_id": "yt_python_002",
                    "name": "YouTube",
                    "content_type": "video",
                    "title": "Python in 100 Seconds",
                    "difficulty": "beginner",
                    "duration": 2,
                    "source_url": "https://www.youtube.com/watch?v=x7X9w_GIm1s",
                    "metadata": {
                        "channel": "Fireship",
                        "format": "quick_overview",
                        "topics": ["language_features", "basics"]
                    }
                }
            ],
            "task": [
                {
                    "provider_id": "fcc_python_001",
                    "name": "freeCodeCamp",
                    "content_type": "task",
                    "title": "Scientific Computing with Python",
                    "difficulty": "intermediate",
                    "duration": 300,
                    "source_url": "https://www.freecodecamp.org/learn/scientific-computing-with-python/",
                    "metadata": {
                        "certification": True,
                        "projects": 5,
                        "estimated_hours": 300,
                        "topics": ["numpy", "pandas", "matplotlib", "data_analysis"]
                    }
                },
                {
                    "provider_id": "fcc_python_002",
                    "name": "freeCodeCamp",
                    "content_type": "task",
                    "title": "Python for Everybody",
                    "difficulty": "beginner",
                    "duration": 200,
                    "source_url": "https://www.freecodecamp.org/learn/python-for-everybody/",
                    "metadata": {
                        "certification": False,
                        "projects": 3,
                        "topics": ["fundamentals", "functions", "files"]
                    }
                }
            ],
            "text": [
                {
                    "provider_id": "mit_python_001",
                    "name": "MIT OpenCourseWare",
                    "content_type": "text",
                    "title": "Introduction to Computer Science and Programming in Python",
                    "difficulty": "advanced",
                    "duration": 900,
                    "source_url": "https://ocw.mit.edu/courses/6-0001-introduction-to-computer-science-and-programming-in-python-fall-2016/",
                    "metadata": {
                        "format": "course",
                        "has_lectures": True,
                        "has_assignments": True,
                        "has_exams": True,
                        "university": "MIT"
                    }
                }
            ]
        },
        "JavaScript": {
            "video": [
                {
                    "provider_id": "yt_js_001",
                    "name": "YouTube",
                    "content_type": "video",
                    "title": "JavaScript Full Course for Beginners",
                    "difficulty": "beginner",
                    "duration": 480,
                    "source_url": "https://www.youtube.com/watch?v=PkZNo7MFNFg",
                    "metadata": {
                        "channel": "freeCodeCamp.org",
                        "views": "30M+",
                        "topics": ["variables", "functions", "DOM", "events"]
                    }
                },
                {
                    "provider_id": "yt_js_002",
                    "name": "YouTube",
                    "content_type": "video",
                    "title": "Modern JavaScript Course 2024",
                    "difficulty": "intermediate",
                    "duration": 600,
                    "source_url": "https://www.youtube.com/watch?v=lkIFF4maKMU",
                    "metadata": {
                        "channel": "freeCodeCamp.org",
                        "topics": ["ES6", "async", "promises", "async_await"]
                    }
                }
            ],
            "task": [
                {
                    "provider_id": "fcc_js_001",
                    "name": "freeCodeCamp",
                    "content_type": "task",
                    "title": "JavaScript Algorithms and Data Structures",
                    "difficulty": "intermediate",
                    "duration": 300,
                    "source_url": "https://www.freecodecamp.org/learn/javascript-algorithms-and-data-structures/",
                    "metadata": {
                        "certification": True,
                        "projects": 5,
                        "topics": ["algorithms", "data_structures", "problem_solving"]
                    }
                }
            ]
        },
        "React": {
            "video": [
                {
                    "provider_id": "yt_react_001",
                    "name": "YouTube",
                    "content_type": "video",
                    "title": "React Course - Beginner's Tutorial",
                    "difficulty": "intermediate",
                    "duration": 720,
                    "source_url": "https://www.youtube.com/watch?v=bMknfKXIFA8",
                    "metadata": {
                        "channel": "freeCodeCamp.org",
                        "views": "15M+",
                        "topics": ["components", "hooks", "state", "JSX"]
                    }
                }
            ],
            "task": [
                {
                    "provider_id": "fcc_react_001",
                    "name": "freeCodeCamp",
                    "content_type": "task",
                    "title": "Front End Development Libraries",
                    "difficulty": "intermediate",
                    "duration": 300,
                    "source_url": "https://www.freecodecamp.org/learn/front-end-development-libraries/",
                    "metadata": {
                        "certification": True,
                        "projects": 5,
                        "includes": ["React", "Redux", "Bootstrap"]
                    }
                }
            ]
        },
        "SQL": {
            "video": [
                {
                    "provider_id": "yt_sql_001",
                    "name": "YouTube",
                    "content_type": "video",
                    "title": "SQL Tutorial - Full Database Course",
                    "difficulty": "beginner",
                    "duration": 240,
                    "source_url": "https://www.youtube.com/watch?v=HXV3zeQKqGY",
                    "metadata": {
                        "channel": "freeCodeCamp.org",
                        "topics": ["queries", "joins", "aggregation", "indexing"]
                    }
                }
            ],
            "task": [
                {
                    "provider_id": "fcc_sql_001",
                    "name": "freeCodeCamp",
                    "content_type": "task",
                    "title": "Relational Database Certification",
                    "difficulty": "intermediate",
                    "duration": 300,
                    "source_url": "https://www.freecodecamp.org/learn/relational-database/",
                    "metadata": {
                        "certification": True,
                        "projects": 4,
                        "topics": ["design", "normalization", "transactions"]
                    }
                }
            ]
        },
        "Machine Learning": {
            "video": [
                {
                    "provider_id": "yt_ml_001",
                    "name": "YouTube",
                    "content_type": "video",
                    "title": "Machine Learning Course - freeCodeCamp",
                    "difficulty": "advanced",
                    "duration": 600,
                    "source_url": "https://www.youtube.com/watch?v=NWONeJKn6kc",
                    "metadata": {
                        "channel": "freeCodeCamp.org",
                        "topics": ["supervised_learning", "regression", "classification"]
                    }
                }
            ],
            "text": [
                {
                    "provider_id": "mit_ml_001",
                    "name": "MIT OpenCourseWare",
                    "content_type": "text",
                    "title": "Introduction to Machine Learning",
                    "difficulty": "advanced",
                    "duration": 1200,
                    "source_url": "https://ocw.mit.edu/courses/6-036-introduction-to-machine-learning-fall-2020/",
                    "metadata": {
                        "format": "course",
                        "has_video": True,
                        "has_assignments": True,
                        "university": "MIT"
                    }
                }
            ]
        },
        "Git": {
            "video": [
                {
                    "provider_id": "yt_git_001",
                    "name": "YouTube",
                    "content_type": "video",
                    "title": "Git and GitHub Tutorial",
                    "difficulty": "beginner",
                    "duration": 120,
                    "source_url": "https://www.youtube.com/watch?v=RGOj5yH7evk",
                    "metadata": {
                        "channel": "freeCodeCamp.org",
                        "topics": ["version_control", "branches", "collaboration"]
                    }
                }
            ]
        },
        "REST APIs": {
            "video": [
                {
                    "provider_id": "yt_api_001",
                    "name": "YouTube",
                    "content_type": "video",
                    "title": "REST API Best Practices",
                    "difficulty": "intermediate",
                    "duration": 180,
                    "source_url": "https://www.youtube.com/watch?v=SLwpqD8n3d0",
                    "metadata": {
                        "channel": "Tech With Tim",
                        "topics": ["HTTP", "REST", "design_patterns"]
                    }
                }
            ],
            "task": [
                {
                    "provider_id": "fcc_api_001",
                    "name": "freeCodeCamp",
                    "content_type": "task",
                    "title": "Build a REST API",
                    "difficulty": "intermediate",
                    "duration": 200,
                    "source_url": "https://www.freecodecamp.org/learn/",
                    "metadata": {
                        "projects": 2,
                        "topics": ["Flask", "Express", "FastAPI"]
                    }
                }
            ]
        }
    }
    
    @staticmethod
    def get_content_for_skill(
        skill: str,
        content_type: Optional[str] = None,
        difficulty: Optional[str] = None,
        provider: Optional[str] = None
    ) -> List[Dict]:
        """
        Retrieve curated content for a skill with optional filters
        
        Args:
            skill: Skill name (e.g., "Python", "React")
            content_type: Filter by type ('video', 'task', 'text')
            difficulty: Filter by difficulty ('beginner', 'intermediate', 'advanced')
            provider: Filter by provider ('YouTube', 'freeCodeCamp', 'MIT OpenCourseWare')
        
        Returns:
            List of matching content items
        """
        
        try:
            skill_content = ContentProviderService.CONTENT_DATABASE.get(skill, {})
            
            if not skill_content:
                print(f"[CONTENT] ⚠️  No content found for skill: {skill}")
                return []
            
            all_content = []
            
            # Iterate through provider categories
            for provider_name, items in skill_content.items():
                if provider and provider != provider_name:
                    continue
                
                try:
                    # items is dict like {"video": [...], "task": [...]}
                    if isinstance(items, dict):
                        for ctype, content_list in items.items():
                            if content_type and ctype != content_type:
                                continue
                            
                            if not isinstance(content_list, list):
                                print(f"[CONTENT] WARNING: Invalid content_list structure for {skill}/{ctype}")
                                continue
                            
                            for item in content_list:
                                if difficulty and item.get("difficulty") != difficulty:
                                    continue
                                
                                all_content.append(item)
                    else:
                        # items is list (legacy format)
                        if not isinstance(items, list):
                            print(f"[CONTENT] WARNING: Invalid items structure for {skill}")
                            continue
                        
                        for item in items:
                            if content_type and item.get("content_type") != content_type:
                                continue
                            if difficulty and item.get("difficulty") != difficulty:
                                continue
                            
                            all_content.append(item)
                
                except Exception as type_error:
                    print(f"[CONTENT] WARNING: Error processing {skill}/{provider_name}: {type_error}")
                    continue
            
            print(f"[CONTENT] 📚 Found {len(all_content)} resources for {skill}")
            return all_content
        
        except Exception as e:
            print(f"[CONTENT] ERROR: Failed to get content for {skill}: {e}")
            return []
    
    @staticmethod
    def get_mixed_learning_path(
        skill: str,
        learning_preference: str = "mixed"
    ) -> List[Dict]:
        """
        Create a balanced content mix based on user's learning preference
        
        Args:
            skill: Skill to learn
            learning_preference: 'video', 'reading', 'hands_on', or 'mixed'
        
        Returns:
            List of content items optimized for the preference
        """
        
        # Preference weight mappings
        weights = {
            "video": {"video": 0.7, "task": 0.2, "text": 0.1},
            "reading": {"text": 0.6, "video": 0.2, "task": 0.2},
            "hands_on": {"task": 0.6, "video": 0.3, "text": 0.1},
            "mixed": {"video": 0.4, "task": 0.4, "text": 0.2}
        }
        
        pref_weights = weights.get(learning_preference, weights["mixed"])
        
        content = []
        skill_resources = ContentProviderService.CONTENT_DATABASE.get(skill, {})
        
        if not skill_resources:
            print(f"[CONTENT] ⚠️  No resources available for {skill}")
            return []
        
        # Flatten the nested structure
        all_by_type = {}
        for provider_name, items in skill_resources.items():
            if isinstance(items, dict):
                for ctype, content_list in items.items():
                    if ctype not in all_by_type:
                        all_by_type[ctype] = []
                    all_by_type[ctype].extend(content_list)
            else:
                for item in items:
                    ctype = item.get("content_type", "unknown")
                    if ctype not in all_by_type:
                        all_by_type[ctype] = []
                    all_by_type[ctype].append(item)
        
        # Add content based on preference weights
        if pref_weights.get("video", 0) >= 0.3 and "video" in all_by_type:
            # Add top 2 videos
            content.extend(all_by_type["video"][:2])
        
        if pref_weights.get("task", 0) >= 0.2 and "task" in all_by_type:
            # Add top practice task
            content.extend(all_by_type["task"][:1])
        
        if pref_weights.get("text", 0) >= 0.1 and "text" in all_by_type:
            # Add top text resource
            content.extend(all_by_type["text"][:1])
        
        print(f"[CONTENT] 🎓 Created {learning_preference} learning path with {len(content)} items for {skill}")
        return content
    
    @staticmethod
    def get_learning_roadmap(
        primary_skill: str,
        secondary_skills: List[str],
        learning_preference: str = "mixed"
    ) -> Dict:
        """
        Create a comprehensive learning roadmap for multiple related skills
        
        Args:
            primary_skill: Main skill to focus on
            secondary_skills: Supporting skills to learn alongside
            learning_preference: User's preferred learning style
        
        Returns:
            Structured roadmap with phases and content
        """
        
        roadmap = {
            "primary_skill": primary_skill,
            "phases": []
        }
        
        # Phase 1: Primary skill fundamentals
        phase1_content = ContentProviderService.get_mixed_learning_path(
            primary_skill, learning_preference
        )
        roadmap["phases"].append({
            "phase": 1,
            "title": f"Master {primary_skill}",
            "duration_weeks": 4,
            "content": phase1_content,
            "focus": "fundamentals"
        })
        
        # Phase 2: Secondary skills (if provided)
        if secondary_skills:
            phase2_content = []
            for skill in secondary_skills[:2]:  # Limit to 2 secondary skills
                phase2_content.extend(
                    ContentProviderService.get_content_for_skill(skill, content_type="video")[:1]
                )
            
            roadmap["phases"].append({
                "phase": 2,
                "title": f"Build Supporting Skills: {', '.join(secondary_skills[:2])}",
                "duration_weeks": 3,
                "content": phase2_content,
                "focus": "supporting"
            })
        
        # Phase 3: Advanced and project-based
        phase3_content = ContentProviderService.get_content_for_skill(
            primary_skill, difficulty="advanced"
        )
        if not phase3_content:
            phase3_content = ContentProviderService.get_content_for_skill(
                primary_skill, content_type="task"
            )
        
        roadmap["phases"].append({
            "phase": 3,
            "title": f"Advanced {primary_skill} & Real Projects",
            "duration_weeks": 3,
            "content": phase3_content[:2],
            "focus": "advanced"
        })
        
        roadmap["total_duration_weeks"] = 10
        roadmap["estimated_hours"] = 60
        
        print(f"[CONTENT] 🗺️  Created learning roadmap for {primary_skill} + {len(secondary_skills)} skills")
        return roadmap


# Global instance for use across the application
content_provider = ContentProviderService()
