FROM python:3.11-slim

WORKDIR /app

# Install AWS CLI for downloading model from S3
RUN apt-get update && apt-get install -y curl unzip && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip aws && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy your existing model files + API code
COPY app.py .
COPY tfidf.pkl encoder.pkl ./

# Download large model file from S3 (public bucket)
RUN aws s3 cp s3://resume-screening-ml-models-thevindu/clf.pkl clf.pkl --no-sign-request --region ap-south-1

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
