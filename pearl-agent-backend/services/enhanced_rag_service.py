"""
Enhanced RAG Service - Real External Resource Retrieval
Provides curated database of real learning resources

"""

from typing import List, Dict, Optional
import json


class EnhancedRAGService:
    """Retrieves real, curated external learning resources"""
    
    # Curated resource database
    RESOURCE_DB = {
        "Python": {
            "byte": [
                {
                    "title": "Python in 100 Seconds",
                    "platform": "YouTube",
                    "url": "https://www.youtube.com/watch?v=x7X9w_GIm1s",
                    "duration": 2,
                    "source": "Fireship"
                },
                {
                    "title": "Python Basics - What is Python?",
                    "platform": "YouTube",
                    "url": "https://www.youtube.com/watch?v=rfscVS0vtik",
                    "duration": 10,
                    "source": "Corey Schafer"
                }
            ],
            "course": [
                {
                    "title": "Python for Everybody",
                    "platform": "freeCodeCamp",
                    "url": "https://www.freecodecamp.org/learn/scientific-computing-with-python/",
                    "duration": 200,
                    "source": "Dr. Charles Severance"
                },
                {
                    "title": "Complete Python Bootcamp",
                    "platform": "Udemy",
                    "url": "https://www.udemy.com/course/complete-python-bootcamp/",
                    "duration": 240,
                    "source": "José Portilla"
                },
                {
                    "title": "Python Programming Masterclass",
                    "platform": "Coursera",
                    "url": "https://www.coursera.org/learn/python-programming",
                    "duration": 180,
                    "source": "Tim Buchalka"
                }
            ],
            "taiken": [
                {
                    "title": "Build Projects on Replit",
                    "platform": "Replit",
                    "url": "https://replit.com/community",
                    "description": "Interactive Python projects with instant feedback",
                    "difficulty": "beginner"
                },
                {
                    "title": "LeetCode Python Problems",
                    "platform": "LeetCode",
                    "url": "https://leetcode.com/",
                    "description": "Coding challenges and practice",
                    "difficulty": "medium"
                },
                {
                    "title": "Python Data Science Projects",
                    "platform": "Kaggle",
                    "url": "https://www.kaggle.com/",
                    "description": "Real-world projects and competitions",
                    "difficulty": "advanced"
                }
            ]
        },
        "SQL": {
            "byte": [
                {
                    "title": "SQL in 100 Seconds",
                    "platform": "YouTube",
                    "url": "https://www.youtube.com/watch?v=zsjvFFKOm3c",
                    "duration": 2,
                    "source": "Fireship"
                },
                {
                    "title": "SQL Basics Tutorial",
                    "platform": "YouTube",
                    "url": "https://www.youtube.com/watch?v=zbMHLZEHgtc",
                    "duration": 15,
                    "source": "Traversy Media"
                }
            ],
            "course": [
                {
                    "title": "SQL for Data Analysis",
                    "platform": "Mode Analytics",
                    "url": "https://mode.com/sql-tutorial/",
                    "duration": 120,
                    "source": "Mode Analytics"
                },
                {
                    "title": "The Complete SQL Bootcamp",
                    "platform": "Udemy",
                    "url": "https://www.udemy.com/course/the-complete-sql-bootcamp/",
                    "duration": 150,
                    "source": "Jose Portilla"
                },
                {
                    "title": "Google Cloud SQL Basics",
                    "platform": "Google Cloud Skills Boost",
                    "url": "https://www.cloudskillsboost.google/",
                    "duration": 90,
                    "source": "Google"
                }
            ],
            "taiken": [
                {
                    "title": "SQLiteOnline Editor",
                    "platform": "SQLiteOnline",
                    "url": "https://sqliteonline.com/",
                    "description": "Practice SQL with online editor",
                    "difficulty": "beginner"
                },
                {
                    "title": "HackerRank SQL Challenges",
                    "platform": "HackerRank",
                    "url": "https://www.hackerrank.com/domains/sql",
                    "description": "SQL problem solving",
                    "difficulty": "medium"
                }
            ]
        },
        "REST APIs": {
            "byte": [
                {
                    "title": "REST APIs in 100 Seconds",
                    "platform": "YouTube",
                    "url": "https://www.youtube.com/watch?v=-MTSQjw5DrM",
                    "duration": 2,
                    "source": "Fireship"
                }
            ],
            "course": [
                {
                    "title": "Build REST APIs with Django",
                    "platform": "freeCodeCamp",
                    "url": "https://www.freecodecamp.org/news/build-a-rest-api-in-django/",
                    "duration": 180,
                    "source": "freeCodeCamp"
                },
                {
                    "title": "REST API Design Rulebook",
                    "platform": "Udacity",
                    "url": "https://www.udacity.com/",
                    "duration": 120,
                    "source": "Udacity"
                }
            ],
            "taiken": [
                {
                    "title": "Build API on Replit",
                    "platform": "Replit",
                    "url": "https://replit.com/",
                    "description": "Create and test APIs instantly",
                    "difficulty": "intermediate"
                }
            ]
        },
        "JavaScript": {
            "byte": [
                {
                    "title": "JavaScript in 100 Seconds",
                    "platform": "YouTube",
                    "url": "https://www.youtube.com/watch?v=DHjqpvDnNGE",
                    "duration": 2,
                    "source": "Fireship"
                }
            ],
            "course": [
                {
                    "title": "The Complete JavaScript Course",
                    "platform": "Udemy",
                    "url": "https://www.udemy.com/course/the-complete-javascript-course-2022/",
                    "duration": 300,
                    "source": "Jonas Schmedtmann"
                },
                {
                    "title": "JavaScript Algorithms & Data Structures",
                    "platform": "freeCodeCamp",
                    "url": "https://www.freecodecamp.org/learn/javascript-algorithms-and-data-structures/",
                    "duration": 300,
                    "source": "freeCodeCamp"
                }
            ],
            "taiken": [
                {
                    "title": "CodePen JavaScript Projects",
                    "platform": "CodePen",
                    "url": "https://codepen.io/",
                    "description": "Interactive coding environment",
                    "difficulty": "beginner"
                }
            ]
        },
        "React": {
            "byte": [
                {
                    "title": "React in 100 Seconds",
                    "platform": "YouTube",
                    "url": "https://www.youtube.com/watch?v=Tn6-PIqc4UM",
                    "duration": 2,
                    "source": "Fireship"
                }
            ],
            "course": [
                {
                    "title": "React - The Complete Guide",
                    "platform": "Udemy",
                    "url": "https://www.udemy.com/course/react-the-complete-guide-incl-redux/",
                    "duration": 360,
                    "source": "Maximilian Schwarzmüller"
                },
                {
                    "title": "React Tutorial: Tic-Tac-Toe",
                    "platform": "Official React",
                    "url": "https://react.dev/learn/tutorial-tic-tac-toe",
                    "duration": 90,
                    "source": "React Team"
                }
            ],
            "taiken": [
                {
                    "title": "Build on CodeSandbox",
                    "platform": "CodeSandbox",
                    "url": "https://codesandbox.io/",
                    "description": "React development environment",
                    "difficulty": "beginner"
                }
            ]
        },
        "Data Analysis": {
            "byte": [
                {
                    "title": "Pandas in 10 Minutes",
                    "platform": "YouTube",
                    "url": "https://www.youtube.com/results?search_query=pandas+python+tutorial",
                    "duration": 10,
                    "source": "Various"
                }
            ],
            "course": [
                {
                    "title": "Data Analysis with Python",
                    "platform": "freeCodeCamp",
                    "url": "https://www.freecodecamp.org/learn/data-analysis-with-python/",
                    "duration": 250,
                    "source": "freeCodeCamp"
                }
            ],
            "taiken": [
                {
                    "title": "Kaggle Datasets & Analysis",
                    "platform": "Kaggle",
                    "url": "https://www.kaggle.com/",
                    "description": "Real data analysis projects",
                    "difficulty": "intermediate"
                }
            ]
        },
        "Machine Learning": {
            "byte": [
                {
                    "title": "Machine Learning in 100 Seconds",
                    "platform": "YouTube",
                    "url": "https://www.youtube.com/watch?v=PeMlggyqfqo",
                    "duration": 2,
                    "source": "Fireship"
                }
            ],
            "course": [
                {
                    "title": "Machine Learning Specialization",
                    "platform": "Coursera",
                    "url": "https://www.coursera.org/specializations/machine-learning-introduction",
                    "duration": 400,
                    "source": "Andrew Ng"
                },
                {
                    "title": "ML with Python",
                    "platform": "Scikit-learn",
                    "url": "https://scikit-learn.org/stable/",
                    "duration": 200,
                    "source": "Scikit-learn Team"
                }
            ],
            "taiken": [
                {
                    "title": "Build ML Models on Google Colab",
                    "platform": "Google Colab",
                    "url": "https://colab.research.google.com/",
                    "description": "Free ML development environment",
                    "difficulty": "intermediate"
                }
            ]
        }
    }
    
    @staticmethod
    def retrieve_resources(skill: str, resource_type: str, count: int = 3) -> List[Dict]:
        """
        Retrieve real resources for a skill and type
        Falls back to search queries if not in database
        """
        skill_resources = EnhancedRAGService.RESOURCE_DB.get(skill, {})
        resources = skill_resources.get(resource_type, [])
        
        if resources:
            return resources[:count]
        
        # Fallback: generate search queries
        fallback_platforms = {
            "byte": f"https://youtube.com/results?search_query={skill.replace(' ', '+')}+tutorial",
            "course": f"https://www.freecodecamp.org/news/search/?query={skill}",
            "taiken": f"https://replit.com/search?query={skill}"
        }
        
        return [{
            "title": f"{skill} - {resource_type}",
            "platform": "Search Results",
            "url": fallback_platforms.get(resource_type, "https://google.com"),
            "duration": 60,
            "description": f"Search for {skill} {resource_type} resources"
        }]
    
    @staticmethod
    def get_available_skills() -> List[str]:
        """Get list of available skills in resource database"""
        return list(EnhancedRAGService.RESOURCE_DB.keys())
    
    @staticmethod
    def add_custom_resource(skill: str, resource_type: str, resource: Dict) -> bool:
        """Add custom resource to database"""
        if skill not in EnhancedRAGService.RESOURCE_DB:
            EnhancedRAGService.RESOURCE_DB[skill] = {}
        
        if resource_type not in EnhancedRAGService.RESOURCE_DB[skill]:
            EnhancedRAGService.RESOURCE_DB[skill][resource_type] = []
        
        EnhancedRAGService.RESOURCE_DB[skill][resource_type].append(resource)
        return True


# Global instance
enhanced_rag = EnhancedRAGService()
