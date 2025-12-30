from locust import HttpUser, task, between

class ResumeAPIUser(HttpUser):
    wait_time = between(1, 1)  # 1 request per second

    @task
    def predict(self):
        self.client.post(
            "/predict",
            json={"resume": "Experienced Python DevOps Engineer"}
        )
