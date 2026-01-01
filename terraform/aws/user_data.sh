#!/bin/bash
set -e

LOG=/var/log/user_data.log
echo "=== Starting ML API setup ===" >> $LOG

exec > >(tee -a $LOG) 2>&1

apt-get update -y
apt-get install -y python3-pip python3-venv git unzip wget awscli

mkdir -p /opt/ml-api
cd /opt/ml-api

echo "[*] Downloading app.py and requirements.txt"
wget -O app.py "https://raw.githubusercontent.com/ThevinduKevin/resume-screening-nlp-model/main/app.py"
wget -O requirements.txt "https://raw.githubusercontent.com/ThevinduKevin/resume-screening-nlp-model/main/requirements.txt"

echo "[*] Downloading models from S3"
aws s3 cp s3://resume-screening-ml-models-thevindu/clf.pkl clf.pkl
aws s3 cp s3://resume-screening-ml-models-thevindu/tfidf.pkl tfidf.pkl
aws s3 cp s3://resume-screening-ml-models-thevindu/encoder.pkl encoder.pkl

echo "[*] Installing Python dependencies"
pip3 install --upgrade pip
pip3 install -r requirements.txt

echo "[*] Starting FastAPI (Uvicorn) on 0.0.0.0:8000"
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 >> /var/log/ml-api.log 2>&1 &

echo "=== Setup complete === $(date)" >> $LOG
