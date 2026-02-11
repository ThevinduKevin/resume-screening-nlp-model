"""
AWS Lambda Handler for FastAPI Resume Screening API
Uses Mangum to wrap FastAPI for AWS Lambda compatibility
"""

from mangum import Mangum
from app import app

# Create Lambda handler from FastAPI app
handler = Mangum(app, lifespan="off")
