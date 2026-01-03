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

echo "[*] Creating Python virtual environment"
python3 -m venv /opt/ml-api/venv

echo "[*] Installing Python dependencies in venv"
/opt/ml-api/venv/bin/pip install --upgrade pip
/opt/ml-api/venv/bin/pip install -r requirements.txt

echo "[*] Creating systemd service for ML API"
cat > /etc/systemd/system/ml-api.service << 'EOF'
[Unit]
Description=ML API FastAPI Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ml-api
ExecStart=/opt/ml-api/venv/bin/uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "[*] Starting ML API service"
systemctl daemon-reload
systemctl enable ml-api
systemctl start ml-api

echo "=== Setup complete === $(date)" >> $LOG
