#!/bin/bash
set -e

# Log everything to user_data.log
exec > >(tee /var/log/user_data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== System Update ==="
apt-get update -y
apt-get install -y python3-pip python3-venv git unzip wget awscli

# Create app directory
mkdir -p /opt/ml-api
cd /opt/ml-api

echo "=== Downloading Files ==="
wget -O app.py "https://raw.githubusercontent.com/ThevinduKevin/resume-screening-nlp-model/main/app.py"
# If you don't have a requirements.txt, we install common ML libs manually:
echo "fastapi uvicorn scikit-learn pandas python-docx PyPDF2 pydantic" > requirements.txt

echo "=== Downloading Models from S3 ==="
# Ensure these names match EXACTLY what is in your bucket
aws s3 cp s3://resume-screening-ml-models-thevindu/clf.pkl . || echo "clf.pkl download failed"
aws s3 cp s3://resume-screening-ml-models-thevindu/tfidf.pkl . || echo "tfidf.pkl download failed"
aws s3 cp s3://resume-screening-ml-models-thevindu/encoder.pkl . || echo "encoder.pkl download failed"

echo "=== Installing Python Packages ==="
pip3 install --upgrade pip
pip3 install -r requirements.txt

echo "=== Starting API ==="
# We use nohup to keep it running and log output to ml-api.log
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 > /var/log/ml-api.log 2>&1 &

echo "=== Setup Sequence Complete ==="