#!/bin/bash
set -e

LOG=/var/log/startup.log
echo "=== Starting ML API setup ===" >> $LOG

exec > >(tee -a $LOG) 2>&1

# Set HOME for git-lfs
export HOME=/root

apt-get update -y
apt-get install -y python3-pip python3-venv git unzip wget curl

# Install git-lfs manually
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get install -y git-lfs
git lfs install

mkdir -p /opt/ml-api
cd /opt/ml-api

echo "[*] Cloning repository (main branch) with LFS files"
# Clone the main branch with LFS files - use GIT_LFS_SKIP_SMUDGE to clone first, then pull LFS separately
export GIT_LFS_SKIP_SMUDGE=1
git clone --branch main --single-branch https://github.com/ThevinduKevin/resume-screening-nlp-model.git repo
unset GIT_LFS_SKIP_SMUDGE

cd /opt/ml-api/repo

echo "[*] Current branch:"
git branch -v

# Force pull LFS files
echo "[*] Pulling LFS files..."
git lfs fetch --all
git lfs checkout

# Verify files exist and are not LFS pointers
echo "[*] Checking pkl files..."
ls -la *.pkl || echo "ERROR: pkl files not found!"

# Check if they are actual files or just LFS pointers
echo "[*] File types:"
file *.pkl || true

# Verify file sizes (clf.pkl should be ~237MB)
echo "[*] File sizes:"
du -h *.pkl || true

echo "[*] Creating Python virtual environment"
python3 -m venv /opt/ml-api/venv

echo "[*] Installing Python dependencies in venv"
/opt/ml-api/venv/bin/pip install --upgrade pip
/opt/ml-api/venv/bin/pip install -r /opt/ml-api/repo/requirements.txt

# Copy necessary files to /opt/ml-api
cp /opt/ml-api/repo/app.py /opt/ml-api/
cp /opt/ml-api/repo/clf.pkl /opt/ml-api/
cp /opt/ml-api/repo/tfidf.pkl /opt/ml-api/
cp /opt/ml-api/repo/encoder.pkl /opt/ml-api/

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
