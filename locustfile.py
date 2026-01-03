from locust import HttpUser, task, between
import random

class ResumeAPIUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        self.sample_resumes = [
            "Experienced Python DevOps Engineer Terraform AWS FastAPI",
            "Senior ML Engineer Resume Screening Scikit-learn FastAPI",
            "DevOps Architect Kubernetes Docker AWS GCP Terraform Ansible"
        ]

    @task(4)
    def predict_text(self):
        """Primary load test - text endpoint"""
        self.client.post("/predict/text", json={"resume_text": random.choice(self.sample_resumes)})

    @task(1)
    def health_check(self):
        self.client.get("/health")
