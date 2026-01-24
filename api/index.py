"""
PEARL Agent Backend - Vercel Entry Point
(Serverless-safe, API-only)
"""

import sys
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# ------------------------------------------------------------------
# Path setup (allow importing routes/)
# ------------------------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

# ------------------------------------------------------------------
# FastAPI app
# ------------------------------------------------------------------
app = FastAPI(
    title="PEARL Agent API",
    description="Agentic Career Mentor",
    version="1.0.0"
)

# ------------------------------------------------------------------
# CORS (Vercel-safe)
# ------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:5173",
        "https://pearl-agent.vercel.app",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["Authorization", "Content-Type"],
)

# ------------------------------------------------------------------
# Routes
# ------------------------------------------------------------------
try:
    from routes.pearl_routes import router as pearl_router
    app.include_router(pearl_router, prefix="/agent", tags=["PEARL Agent"])
except Exception as e:
    print(f"[ERROR] Failed to load pearl routes: {e}")

# ------------------------------------------------------------------
# Core endpoints
# ------------------------------------------------------------------
@app.get("/")
async def root():
    return {
        "status": "online",
        "service": "PEARL Agent API",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "PEARL Agent",
        "version": "1.0.0"
    }

@app.get("/test")
async def test():
    return {"message": "API is working"}

# ------------------------------------------------------------------
# Global error handler (safe for production)
# ------------------------------------------------------------------
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "type": type(exc).__name__,
            "path": str(request.url)
        }
    )
