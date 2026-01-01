#!/bin/bash
set -e

echo "=== Starting ML API setup ===" >> /var/log/user_data.log

# Update system
apt-get update -y >> /var/log/user_data.log 2>&1
apt-get install -y python3-pip python3-venv git unzip wget >> /var/log/user_data.log 2>&1

# Create app directory
mkdir -p /opt/ml-api
cd /opt/ml-api

# Download your app.py (replace with your actual repo/raw URLs)
wget -O app.py "https://raw.githubusercontent.com/ThevinduKevin/resume-screening-nlp-model/main/app.py"
wget -O requirements.txt "https://raw.githubusercontent.com/ThevinduKevin/resume-screening-nlp-model/main/requirements.txt"

# Download your ML models from S3 (using IAM role you created)
aws s3 cp s3://resume-screening-ml-models-thevindu/ clf.pkl .
aws s3 cp s3://resume-screening-ml-models-thevindu/ tfidf.pkl .
aws s3 cp s3://resume-screening-ml-models-thevindu/ encoder.pkl .

# Install Python dependencies
pip3 install --upgrade pip
pip3 install -r requirements.txt

# Start FastAPI with Uvicorn
cd /opt/ml-api
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 >> /var/log/ml-api.log 2>&1 &

echo "=== API started at $(date) ===" >> /var/log/ml-api.log
echo "=== Setup complete ===" >> /var/log/user_data.log
