"""
Comprehensive Test Script for PEARL Agent Hackathon Implementation
Tests all new features: Agent 4, Adzuna Integration, Content Providers
"""

import asyncio
import json
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from services.learning_optimizer_agent import learning_optimizer
from services.job_retrieval_service import adzuna_service
from services.content_provider_service import content_provider
from config import get_settings


def print_section(title):
    """Print formatted section header"""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}\n")


def print_success(message):
    """Print success message"""
    print(f"✅ {message}")


def print_error(message):
    """Print error message"""
    print(f"❌ {message}")


def print_info(message):
    """Print info message"""
    print(f"ℹ️  {message}")


# ============================================
# TEST 1: AGENT 4 - Learning Path Optimizer
# ============================================

def test_learning_optimizer():
    """Test the Learning Path Optimizer agent"""
    print_section("TEST 1: Agent 4 - Learning Path Optimizer")
    
    try:
        user_skills = {
            "Python": 0.3,
            "SQL": 0.5,
            "HTML/CSS": 0.2
        }
        
        required_skills = ["Python", "SQL", "REST APIs", "Git", "Docker"]
        
        print_info(f"User Skills: {user_skills}")
        print_info(f"Required Skills: {required_skills}")
        print_info(f"Time Available: 8 weeks")
        print_info(f"Learning Preference: mixed")
        
        result = learning_optimizer.optimize_learning_sequence(
            user_skills=user_skills,
            required_skills=required_skills,
            time_constraint_weeks=8,
            learning_preference="mixed"
        )
        
        # Validate response structure
        assert isinstance(result, dict), "Result should be a dictionary"
        assert "optimized_sequence" in result, "Missing optimized_sequence"
        assert isinstance(result["optimized_sequence"], list), "optimized_sequence should be a list"
        assert len(result["optimized_sequence"]) > 0, "optimized_sequence should not be empty"
        
        print_success("Optimizer returned valid response")
        print_info(f"Optimized sequence: {len(result['optimized_sequence'])} skills")
        print_info(f"Estimated completion: {result.get('estimated_completion_weeks', '?')} weeks")
        print_info(f"Learning strategy: {result.get('learning_strategy', '?')}")
        
        # Print first priority skill details
        first_skill = result["optimized_sequence"][0]
        print_info(f"\nTop Priority Skill: {first_skill.get('skill', '?')}")
        print_info(f"  - Priority: {first_skill.get('priority', '?')}")
        print_info(f"  - Gap Severity: {first_skill.get('gap_severity', '?')}")
        print_info(f"  - Estimated weeks: {first_skill.get('estimated_weeks', '?')}")
        print_info(f"  - Content mix: {first_skill.get('content_mix', {})}")
        
        print_success("Agent 4 optimization test PASSED ✨")
        return True
    
    except Exception as e:
        print_error(f"Agent 4 optimization test FAILED: {e}")
        import traceback
        traceback.print_exc()
        return False


# ============================================
# TEST 2: Adzuna Job Service
# ============================================

def test_adzuna_service():
    """Test the Adzuna Job Service"""
    print_section("TEST 2: Adzuna Job Retrieval Service")
    
    try:
        settings = get_settings()
        
        # Check if Adzuna credentials are configured
        if not settings.ADZUNA_APP_ID or settings.ADZUNA_APP_ID == "your_adzuna_app_id_here":
            print_error("Adzuna API credentials not configured in .env")
            print_info("To use Adzuna, register at https://developer.adzuna.com/")
            print_info("Then update ADZUNA_APP_ID and ADZUNA_APP_KEY in .env")
            return False
        
        print_info(f"Adzuna App ID configured: {settings.ADZUNA_APP_ID[:10]}...")
        
        # Test job search
        print_info("\n📍 Testing job search for 'Backend Developer' in Chennai...")
        jobs = adzuna_service.search_jobs(
            query="Backend Developer",
            location="Chennai",
            max_results=5
        )
        
        if jobs:
            print_success(f"Job search returned {len(jobs)} results")
            print_info(f"First job: {jobs[0]['title']} at {jobs[0]['company']}")
        else:
            print_info("No jobs found in search (may indicate API rate limit or no results)")
        
        # Test job matching
        print_info("\n🎯 Testing job skill matching...")
        user_skills = {
            "Python": 0.7,
            "REST APIs": 0.6,
            "SQL": 0.5,
            "Git": 0.8
        }
        
        matched_jobs = adzuna_service.match_jobs_to_skills(
            user_skills=user_skills,
            target_role="Backend Developer",
            location="Chennai"
        )
        
        if matched_jobs:
            print_success(f"Matched {len(matched_jobs)} jobs with >30% skill overlap")
            best_match = matched_jobs[0]
            print_info(f"Best match: {best_match['title']}")
            print_info(f"  - Match: {best_match.get('match_percentage', 0)}%")
            print_info(f"  - Matched skills: {best_match.get('matched_skills', [])}")
            print_info(f"  - Skills to learn: {len(best_match.get('missing_skills', []))} remaining")
        else:
            print_info("No jobs matched (may indicate no availability)")
        
        print_success("Adzuna service test PASSED (with optional API)")
        return True
    
    except Exception as e:
        print_error(f"Adzuna service test FAILED: {e}")
        import traceback
        traceback.print_exc()
        return False


# ============================================
# TEST 3: Content Provider Service
# ============================================

def test_content_provider():
    """Test the Content Provider Service"""
    print_section("TEST 3: Content Provider Service")
    
    try:
        # Test 1: Get content for a skill
        print_info("Testing content retrieval for 'Python'...")
        python_content = content_provider.get_content_for_skill("Python")
        
        assert len(python_content) > 0, "Should find Python content"
        print_success(f"Found {len(python_content)} resources for Python")
        
        print_info(f"Content types available:")
        types_count = {}
        for content in python_content:
            ctype = content.get("content_type", "unknown")
            types_count[ctype] = types_count.get(ctype, 0) + 1
        for ctype, count in types_count.items():
            print_info(f"  - {ctype}: {count}")
        
        # Test 2: Get content with filters
        print_info("\n🎯 Testing filtered content retrieval...")
        video_content = content_provider.get_content_for_skill(
            "Python",
            content_type="video"
        )
        assert len(video_content) > 0, "Should find video content"
        print_success(f"Found {len(video_content)} video resources")
        
        # Test 3: Get mixed learning path
        print_info("\n🎓 Testing mixed learning path...")
        for preference in ["video", "reading", "hands_on", "mixed"]:
            path = content_provider.get_mixed_learning_path(
                "Python",
                learning_preference=preference
            )
            print_info(f"  - {preference}: {len(path)} items")
        
        # Test 4: Get learning roadmap
        print_info("\n Testing learning roadmap...")
        roadmap = content_provider.get_learning_roadmap(
            primary_skill="Python",
            secondary_skills=["SQL", "REST APIs"],
            learning_preference="mixed"
        )
        
        assert "phases" in roadmap, "Roadmap should have phases"
        assert len(roadmap["phases"]) > 0, "Should have at least one phase"
        print_success(f"Created roadmap with {len(roadmap['phases'])} phases")
        
        for phase in roadmap["phases"]:
            print_info(f"  - Phase {phase['phase']}: {phase['title']} ({len(phase['content'])} items)")
        
        # Test 5: Sample a specific resource
        if python_content:
            sample = python_content[0]
            print_info("\n📖 Sample resource:")
            print_info(f"  - Title: {sample.get('title', 'N/A')}")
            print_info(f"  - Provider: {sample.get('name', 'N/A')}")
            print_info(f"  - Type: {sample.get('content_type', 'N/A')}")
            print_info(f"  - Duration: {sample.get('duration', 'N/A')} min")
            print_info(f"  - Difficulty: {sample.get('difficulty', 'N/A')}")
            print_info(f"  - URL: {sample.get('source_url', 'N/A')}")
        
        print_success("Content Provider test PASSED ✨")
        return True
    
    except Exception as e:
        print_error(f"Content Provider test FAILED: {e}")
        import traceback
        traceback.print_exc()
        return False


# ============================================
# TEST 4: Integration Test
# ============================================

def test_integration():
    """Test integration of all three services"""
    print_section("TEST 4: Integration Test")
    
    try:
        print_info("🔗 Testing complete workflow...")
        
        # Step 1: Optimize learning path
        print_info("\n1️⃣  Optimizing learning path...")
        user_skills = {"Python": 0.5, "SQL": 0.4}
        required_skills = ["Python", "SQL", "REST APIs"]
        
        optimization = learning_optimizer.optimize_learning_sequence(
            user_skills=user_skills,
            required_skills=required_skills,
            time_constraint_weeks=8,
            learning_preference="mixed"
        )
        print_success(f"Optimized path for {len(required_skills)} skills")
        
        # Step 2: Get content for first skill
        if optimization["optimized_sequence"]:
            first_skill = optimization["optimized_sequence"][0]["skill"]
            print_info(f"\n2️⃣  Getting content for first skill: {first_skill}...")
            
            content = content_provider.get_mixed_learning_path(
                skill=first_skill,
                learning_preference="mixed"
            )
            print_success(f"Found {len(content)} resources for {first_skill}")
        
        # Step 3: Simulate job search (if Adzuna configured)
        settings = get_settings()
        if settings.ADZUNA_APP_ID and settings.ADZUNA_APP_ID != "your_adzuna_app_id_here":
            print_info(f"\n3️⃣  Searching for jobs...")
            
            target_role = "Backend Developer"
            jobs = adzuna_service.match_jobs_to_skills(
                user_skills=user_skills,
                target_role=target_role
            )
            
            if jobs:
                print_success(f"Found {len(jobs)} matching jobs")
                print_info(f"Top match: {jobs[0]['title']} ({jobs[0].get('match_percentage', 0)}% match)")
            else:
                print_info("No jobs matched (may indicate API issues)")
        else:
            print_info("\n3️⃣  Skipping job search (Adzuna not configured)")
        
        print_success("Integration test PASSED ✨")
        return True
    
    except Exception as e:
        print_error(f"Integration test FAILED: {e}")
        import traceback
        traceback.print_exc()
        return False


# ============================================
# Main Test Runner
# ============================================

def main():
    """Run all tests"""
    print("\n")
    print("╔" + "="*58 + "╗")
    print("║" + " "*58 + "║")
    print("║  🧪 PEARL AGENT HACKATHON - IMPLEMENTATION TESTS    ║")
    print("║" + " "*58 + "║")
    print("╚" + "="*58 + "╝")
    
    results = {
        "Agent 4 Optimizer": test_learning_optimizer(),
        "Adzuna Job Service": test_adzuna_service(),
        "Content Provider": test_content_provider(),
        "Integration": test_integration()
    }
    
    # Print summary
    print_section("TEST SUMMARY")
    
    total = len(results)
    passed = sum(1 for v in results.values() if v)
    
    for test_name, result in results.items():
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"{test_name:<30} {status}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n" + "="*60)
        print("  🎉 ALL TESTS PASSED! Ready for hackathon! 🎉")
        print("="*60 + "\n")
        return 0
    else:
        print("\n" + "="*60)
        print(f"  ⚠️  {total - passed} test(s) failed. Please review above.")
        print("="*60 + "\n")
        return 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
