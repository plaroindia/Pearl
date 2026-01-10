"""
PEARL Agent Backend - Vercel Entry Point
"""
# Add this import at the top
from fastapi.responses import FileResponse, HTMLResponse
import os

# Add this route (after your existing routes)
@app.get("/app", response_class=HTMLResponse)
async def serve_frontend():
    html_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "pearl_frontend.html")
    if os.path.exists(html_path):
        with open(html_path, 'r', encoding='utf-8') as f:
            return HTMLResponse(content=f.read())
    return {"error": "Frontend not found"}
import sys
import os

# Add parent directory to Python path
parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, parent_dir)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Create FastAPI app
app = FastAPI(
    title="PEARL Agent API",
    description="Agentic Career Mentor",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import routes AFTER app is created
try:
    from routes.pearl_routes import router as pearl_router
    app.include_router(pearl_router, prefix="/agent", tags=["PEARL Agent"])
except Exception as e:
    print(f"Error importing routes: {e}")

@app.get("/")
async def root():
    return {
        "status": "online",
        "message": "PEARL Agent API",
        "endpoints": {
            "docs": "/docs",
            "health": "/health",
            "start": "/agent/start-journey"
        }
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "PEARL Agent",
        "version": "1.0.0"
    }

@app.get("/test")
async def test():
    return {"message": "API is working"}

# Error handler
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "error": str(exc),
            "type": type(exc).__name__,
            "path": str(request.url)
        }
    )