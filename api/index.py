import sys
import os

# Add parent directory to path to ensure app module is found
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app

# Export the app for Vercel
handler = app
