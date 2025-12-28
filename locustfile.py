from locust import HttpUser, task, between

class ResumeUser(HttpUser):
    wait_time = between(1, 2)

    @task
    def predict_resume(self):
        with open("NetworkSecurityEng_Resume.pdf", "rb") as f:
            files = {"file": ("NetworkSecurityEng_Resume.pdf", f, "application/pdf")}
            self.client.post("/predict", files=files)
