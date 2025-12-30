#!/bin/bash
set -e

sudo apt update
sudo apt install -y python3 python3-pip

pip3 install -r requirements.txt

nohup uvicorn app:app --host 0.0.0.0 --port 8000 &
