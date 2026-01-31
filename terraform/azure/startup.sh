#!/bin/bash
set -e

LOG=/var/log/startup.log
echo "=== Starting ML API setup ===" >> $LOG

exec > >(tee -a $LOG) 2>&1

apt-get update -y
apt-get install -y python3-pip python3-venv git unzip wget curl

mkdir -p /opt/ml-api
cd /opt/ml-api

echo "[*] Downloading app.py and requirements.txt"
wget -O app.py "https://raw.githubusercontent.com/ThevinduKevin/resume-screening-nlp-model/main/app.py"
wget -O requirements.txt "https://raw.githubusercontent.com/ThevinduKevin/resume-screening-nlp-model/main/requirements.txt"

echo "[*] Downloading models from S3 (public bucket)"
wget -O clf.pkl "https://resume-screening-ml-models-thevindu.s3.ap-south-1.amazonaws.com/clf.pkl"
wget -O tfidf.pkl "https://resume-screening-ml-models-thevindu.s3.ap-south-1.amazonaws.com/tfidf.pkl"
wget -O encoder.pkl "https://resume-screening-ml-models-thevindu.s3.ap-south-1.amazonaws.com/encoder.pkl"

echo "[*] Checking pkl files..."
ls -la *.pkl || echo "ERROR: pkl files not found!"

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
