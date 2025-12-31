from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import agent, health

app = FastAPI(title="PEARL Agent API", version="1.0.0")

# CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router)
app.include_router(agent.router, prefix="/agent", tags=["agent"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
