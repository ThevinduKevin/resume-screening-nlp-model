#!/bin/bash
set -e

apt update -y
apt install -y python3 python3-pip awscli git

mkdir -p /app
cd /app

aws s3 sync s3://resume-screening-ml-models-thevindu/models /app

pip3 install --upgrade pip
pip3 install -r requirements.txt

nohup python3 app.py > app.log 2>&1 &
