"""
Fixed Main Entry Point with Better Error Handling
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse
import os
import sys
import traceback

# Create app
app = FastAPI(
    title="PEARL Agent API", 
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS - Allow frontend origins
from config import get_settings
settings = get_settings()

cors_origins = [
    "http://localhost:3000",        # React dev server (Vite)
    "http://localhost:5173",        # Vite default
    "http://localhost:8000",        # Same origin
    "http://localhost:4200",        # Angular default
    "http://127.0.0.1:3000",
    "http://127.0.0.1:5173",
    "http://127.0.0.1:8000",
    "http://127.0.0.1:4200",
]

# Add production origins from env if available
if settings.ENVIRONMENT == "production":
    cors_origins.extend([
        "https://pearl-agent.vercel.app",
        "https://pearl-app.com",
    ])

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*", "Authorization", "Content-Type"],
    expose_headers=["*", "Authorization", "X-Total-Count"],
    max_age=3600
)

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle all unhandled exceptions"""
    error_detail = {
        "error": str(exc),
        "type": type(exc).__name__,
        "path": str(request.url),
        "method": request.method
    }
    
    # Log the full traceback
    print(f"\n[ERROR] Unhandled exception at {request.url}")
    print(traceback.format_exc())
    
    return JSONResponse(
        status_code=500,
        content=error_detail
    )

# Import routes with error handling
routes_loaded = {
    'auth': False,
    'pearl': False,
    'api': False
}

try:
    from routes import auth_routes
    app.include_router(auth_routes.router, prefix="/auth", tags=["auth"])
    routes_loaded['auth'] = True
    print("[SUCCESS] Auth routes loaded")
except Exception as e:
    print(f"[ERROR] Failed to load auth routes: {e}")
    traceback.print_exc()

try:
    from routes import pearl_routes
    app.include_router(pearl_routes.router, prefix="/agent", tags=["pearl"])
    routes_loaded['pearl'] = True
    print("[SUCCESS] Pearl routes loaded")
except Exception as e:
    print(f"[ERROR] Failed to load pearl routes: {e}")
    traceback.print_exc()

try:
    from routes import new_routes
    app.include_router(new_routes.router, prefix="/api", tags=["api"])
    routes_loaded['api'] = True
    print("[SUCCESS] API routes loaded")
except Exception as e:
    print(f"[ERROR] Failed to load API routes: {e}")
    traceback.print_exc()

# Load skill gap routes
try:
    from routes import skill_gap_routes
    app.include_router(skill_gap_routes.router, prefix="/api", tags=["skill-gap"])
    print("[SUCCESS] Skill gap routes loaded")
except Exception as e:
    print(f"[ERROR] Failed to load skill gap routes: {e}")
    traceback.print_exc()

# Load enhanced routes (practice, rpg, feedback, notifications)
try:
    from routes import enhanced_routes
    app.include_router(enhanced_routes.router, prefix="/api", tags=["enhanced"])
    print("[SUCCESS] Enhanced routes loaded (practice, rpg, feedback, notifications)")
except Exception as e:
    print(f"[ERROR] Failed to load enhanced routes: {e}")
    traceback.print_exc()

# Serve React/Angular frontend from pearl-agent folder
pearl_agent_path = os.path.join(os.path.dirname(__file__), "pearl-agent")
if os.path.exists(pearl_agent_path):
    @app.get("/")
    async def serve_frontend():
        """Serve index.html from pearl-agent folder as root page"""
        frontend_path = os.path.join(pearl_agent_path, "index.html")
        if os.path.exists(frontend_path):
            return FileResponse(frontend_path)
        else:
            return JSONResponse(
                status_code=404,
                content={"error": "Frontend index.html not found at pearl-agent/"}
            )
    
    # Mount pearl-agent folder as static files for assets (JS, CSS, images)
    app.mount("/", StaticFiles(directory=pearl_agent_path, html=True), name="frontend")
    print(f"[SUCCESS] React/Angular frontend mounted from pearl-agent at http://localhost:8000/")
else:
    print(f"[ERROR] pearl-agent folder not found at {pearl_agent_path}")
    print(f"[WARNING] Falling back to pearl_frontend.html if available")
    
    pearl_frontend = os.path.join(os.path.dirname(__file__), "pearl_frontend.html")
    if os.path.exists(pearl_frontend):
        @app.get("/")
        async def serve_fallback():
            """Fallback to pearl_frontend.html"""
            return FileResponse(pearl_frontend)
        print(f"[SUCCESS] Fallback: pearl_frontend.html will be served at http://localhost:8000/")

# Root endpoint
@app.get("/api-status")
async def root():
    return {
        "status": "online",
        "message": "PEARL Agent API",
        "version": "2.0.0",
        "routes_loaded": routes_loaded,
        "frontend": "http://localhost:8000/",
        "endpoints": {
            "auth": "/auth/signup, /auth/signin, /auth/signout" if routes_loaded['auth'] else "Not loaded",
            "agent": "/agent/start-journey" if routes_loaded['pearl'] else "Not loaded",
            "api": "/api/onboarding, /api/gamification, /api/resume, /api/analytics" if routes_loaded['api'] else "Not loaded",
            "docs": "/docs",
            "frontend": "http://localhost:8000/"
        }
    }

# Health check
@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "PEARL Agent",
        "frontend_url": "http://localhost:8000/",
        "routes_loaded": routes_loaded
    }

# Test endpoint
@app.get("/test")
async def test():
    return {
        "message": "API is working",
        "frontend": "http://localhost:8000/",
        "routes": routes_loaded
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app", 
        host="0.0.0.0", 
        port=8000, 
        reload=True,
        log_level="info"
    )