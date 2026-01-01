#!/bin/bash
set -e

# Redirect all output to a log file for debugging via AWS Console
exec > >(tee /var/log/user_data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== INITIALIZING SYSTEM ==="
apt-get update -y
apt-get install -y python3-pip python3-venv wget awscli

# Create App Directory
mkdir -p /opt/ml-api
cd /opt/ml-api

echo "=== FETCHING CODE ==="
wget -O app.py "https://raw.githubusercontent.com/ThevinduKevin/resume-screening-nlp-model/main/app.py"

echo "=== INSTALLING ML STACK ==="
# We install these explicitly to ensure uvicorn has what it needs
pip3 install --upgrade pip
pip3 install fastapi uvicorn scikit-learn pandas python-docx PyPDF2 pydantic

echo "=== DOWNLOADING MODELS FROM S3 ==="
# Note: Ensure these file names match your S3 bucket exactly
aws s3 cp s3://resume-screening-ml-models-thevindu/clf.pkl . || echo "ERROR: clf.pkl not found"
aws s3 cp s3://resume-screening-ml-models-thevindu/tfidf.pkl . || echo "ERROR: tfidf.pkl not found"
aws s3 cp s3://resume-screening-ml-models-thevindu/encoder.pkl . || echo "ERROR: encoder.pkl not found"

echo "=== STARTING FASTAPI ==="
# Run uvicorn in the background. If it crashes, the error will be in /var/log/ml-api.log
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 > /var/log/ml-api.log 2>&1 &

echo "=== SETUP COMPLETE ==="