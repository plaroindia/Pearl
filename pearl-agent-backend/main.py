from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routes import pearl_routes, auth_routes
import os

app = FastAPI(title="PEARL Agent API", version="2.0.0")

# CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers BEFORE static files (important for routing precedence)
app.include_router(pearl_routes.router, prefix="/agent", tags=["pearl"])
app.include_router(auth_routes.router, prefix="/auth", tags=["auth"])

# Serve static files (frontend.html) - must be last
app.mount("/", StaticFiles(directory=os.path.dirname(__file__), html=True, follow_symlink=True), name="static")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

