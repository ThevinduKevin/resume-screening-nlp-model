#!/bin/bash
set -e

exec > >(tee /var/log/user_data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Starting ML API setup ==="

# Update and install dependencies
apt-get update -y
apt-get install -y python3-pip python3-venv git unzip wget awscli

# Create app directory
mkdir -p /opt/ml-api
cd /opt/ml-api

# Download code (Using your repo URLs)
wget -O app.py "https://raw.githubusercontent.com/ThevinduKevin/resume-screening-nlp-model/main/app.py"
wget -O requirements.txt "https://raw.githubusercontent.com/ThevinduKevin/resume-screening-nlp-model/main/requirements.txt"

# Download models from S3
aws s3 cp s3://resume-screening-ml-models-thevindu/clf.pkl .
aws s3 cp s3://resume-screening-ml-models-thevindu/tfidf.pkl .
aws s3 cp s3://resume-screening-ml-models-thevindu/encoder.pkl .

# Setup Python environment
pip3 install --upgrade pip
pip3 install -r requirements.txt

# Start FastAPI
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 > /var/log/ml-api.log 2>&1 &

echo "=== Setup complete ==="