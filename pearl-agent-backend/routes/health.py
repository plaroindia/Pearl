from fastapi import APIRouter
from database import get_supabase

router = APIRouter()


@router.get("/health")
async def health_check():
    try:
        supabase = get_supabase()
        # Test connection
        result = supabase.table('user_profiles').select('count').limit(1).execute()
        return {
            "status": "healthy",
            "database": "connected",
            "service": "PEARL Agent"
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e)
        }
