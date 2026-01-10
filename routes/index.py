"""
Vercel API Entry Point
Imports and exposes the FastAPI app from pearl-agent-backend
"""
import sys
import os

# Add pearl-agent-backend to Python path
backend_path = os.path.join(os.path.dirname(__file__), '..', 'pearl-agent-backend')
sys.path.insert(0, backend_path)

# Change working directory to pearl-agent-backend
os.chdir(backend_path)

# Import the FastAPI app
from index import app

# Vercel will serve this
__all__ = ['app']