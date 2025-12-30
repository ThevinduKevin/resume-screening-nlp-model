#!/bin/bash
apt update -y
apt install -y python3 python3-pip git

cd /home
git clone https://github.com/ThevinduKevin/resume-screening-nlp-model.git
cd resume-screening-nlp-model

pip3 install -r requirements.txt

nohup uvicorn app:app --host 0.0.0.0 --port 8000 &
