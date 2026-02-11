# Resume Screening with NLP — Multi-Cloud Deployment & Benchmarking

An end-to-end machine learning research project that automates resume screening using Natural Language Processing (NLP). The project trains multiple classification models on a labelled resume dataset, exposes the best-performing model through a FastAPI REST API, and benchmarks deployment performance across **three major cloud providers** (AWS, Azure, GCP) using **three deployment paradigms** (Virtual Machines, Managed Kubernetes, and Serverless).

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Dataset](#dataset)
3. [ML Pipeline](#ml-pipeline)
   - [Data Preprocessing](#data-preprocessing)
   - [Feature Engineering](#feature-engineering)
   - [Model Training & Evaluation](#model-training--evaluation)
4. [API](#api)
5. [Project Structure](#project-structure)
6. [Getting Started](#getting-started)
   - [Prerequisites](#prerequisites)
   - [Local Setup](#local-setup)
   - [Docker](#docker)
7. [Multi-Cloud Deployment Architecture](#multi-cloud-deployment-architecture)
   - [VM Deployments (IaaS)](#vm-deployments-iaas)
   - [Managed Kubernetes (CaaS)](#managed-kubernetes-caas)
   - [Serverless (FaaS / Managed Containers)](#serverless-faas--managed-containers)
8. [Infrastructure as Code (Terraform)](#infrastructure-as-code-terraform)
9. [CI/CD — GitHub Actions](#cicd--github-actions)
10. [Performance Benchmarking](#performance-benchmarking)
    - [Load Testing with Locust](#load-testing-with-locust)
    - [Cold Start Measurement](#cold-start-measurement)
    - [Metrics Collection & Reporting](#metrics-collection--reporting)
11. [Results](#results)
12. [Technologies Used](#technologies-used)
13. [Cloud Secrets Setup](#cloud-secrets-setup)
14. [License](#license)

---

## Project Overview

Hiring teams manually screen thousands of resumes for every open position — a time-consuming and error-prone process. This project addresses the problem by building a **text classification model** that automatically categorises a resume into one of **25 professional categories** (e.g., Data Science, Java Developer, DevOps Engineer, HR, etc.).

Beyond the ML model itself, the research investigates **how deployment strategy and cloud provider choice affect real-world serving performance**. The same containerised API is deployed to nine distinct cloud environments, and each deployment is subjected to identical load tests so that latency, throughput, failure rate, resource utilisation, and cold-start behaviour can be compared objectively.

---

## Dataset

| Property | Value |
|----------|-------|
| **File** | `UpdatedResumeDataSet.csv` |
| **Rows** | ~962 resumes (before balancing) |
| **Columns** | `Category`, `Resume` |
| **Categories** | 25 |

### Resume Categories

Advocate · Arts · Automation Testing · Blockchain · Business Analyst · Civil Engineer · Data Science · Database · DevOps Engineer · DotNet Developer · ETL Developer · Electrical Engineering · HR · Hadoop · Health and fitness · Java Developer · Mechanical Engineer · Network Security Engineer · Operations Manager · PMO · Python Developer · SAP Developer · Sales · Testing · Web Designing

---

## ML Pipeline

The full training pipeline is implemented in the Jupyter notebook **`Resume Screening with Python.ipynb`**.

### Data Preprocessing

1. **Exploratory Data Analysis** — category distribution visualisations (bar chart, pie chart).
2. **Class Balancing** — oversampling minority categories to the size of the largest category so the classifier is not biased towards any single class.
3. **Text Cleaning** (`cleanResume` function) — removes:
   - URLs (`http…`)
   - Retweet / CC tags
   - Hashtags and mentions
   - Special characters and punctuation
   - Non-ASCII characters
   - Extra whitespace

### Feature Engineering

- **TF-IDF Vectorisation** (`TfidfVectorizer` with English stop-word removal) converts each cleaned resume into a sparse numerical feature vector.

### Model Training & Evaluation

Three classifiers were trained with a **One-vs-Rest** strategy and an 80/20 train-test split (`random_state=42`):

| Model | Strategy | Notes |
|-------|----------|-------|
| **K-Nearest Neighbours (KNN)** | OneVsRestClassifier | Baseline |
| **Support Vector Classifier (SVC)** | OneVsRestClassifier | **Selected for production** |
| **Random Forest** | OneVsRestClassifier | Ensemble baseline |

Each model was evaluated using **accuracy, confusion matrix, and a full classification report** (precision, recall, F1-score per category).

The **SVC model** was chosen for deployment. The trained artefacts are serialised with `pickle`:

| File | Contents |
|------|----------|
| `clf.pkl` | Trained SVC model |
| `tfidf.pkl` | Fitted TF-IDF vectoriser |
| `encoder.pkl` | Fitted `LabelEncoder` (maps category names ↔ integers) |

---

## API

The prediction service is built with **FastAPI** (`app.py`) and supports multiple input methods.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/predict` | Upload a resume file (PDF, DOCX, or TXT) for classification |
| `POST` | `/predict/text` | Submit raw resume text as a query parameter |
| `GET`  | `/health` | Health check — returns `{"status": "healthy", "model": "loaded"}` |

### Example Requests

```bash
# Health check
curl http://localhost:8000/health

# Predict from text
curl -X POST "http://localhost:8000/predict/text?resume_text=Experienced+Python+developer+with+Django+Flask"

# Predict from file upload
curl -X POST -F "file=@resume.pdf" http://localhost:8000/predict
```

### Response Format

```json
{
  "category": "Python Developer",
  "processing_time_ms": 12.34,
  "message": "Resume analyzed successfully"
}
```

---

## Project Structure

```
.
├── Resume Screening with Python.ipynb  # Full ML training notebook
├── UpdatedResumeDataSet.csv            # Labelled resume dataset
├── app.py                              # FastAPI prediction API
├── lambda_handler.py                   # AWS Lambda handler (Mangum wrapper)
├── clf.pkl                             # Trained SVC model
├── tfidf.pkl                           # Fitted TF-IDF vectoriser
├── encoder.pkl                         # Fitted LabelEncoder
├── requirements.txt                    # Python dependencies
├── Dockerfile                          # Container image (VM / K8s)
├── Dockerfile.lambda                   # Container image (AWS Lambda)
├── locustfile.py                       # Locust load-testing script
├── k8s/
│   ├── deployment.yaml                 # Kubernetes Deployment manifest
│   └── service.yaml                    # Kubernetes LoadBalancer Service
├── terraform/
│   ├── aws/                            # AWS EC2 VM
│   ├── azure/                          # Azure VM
│   ├── gcp/                            # GCP Compute Engine VM
│   ├── aws-eks/                        # AWS EKS (Kubernetes)
│   ├── azure-aks/                      # Azure AKS (Kubernetes)
│   ├── gcp-gke/                        # GCP GKE (Kubernetes)
│   ├── aws-lambda/                     # AWS Lambda (Serverless)
│   ├── gcp-cloudrun/                   # GCP Cloud Run (Serverless)
│   └── azure-container-apps/           # Azure Container Apps (Serverless)
├── scripts/
│   ├── deploy.sh                       # VM deployment helper
│   ├── run_locust.sh                   # Automated Locust load-test runner
│   ├── collect_metrics.py              # Local system metrics collector
│   ├── collect_remote_metrics.sh       # Remote instance metrics collector
│   ├── measure_cold_starts.py          # Serverless cold-start measurement
│   ├── upload_to_sheets.py             # Upload VM results to Google Sheets
│   ├── upload_k8s_to_sheets.py         # Upload K8s results to Google Sheets
│   └── upload_serverless_to_sheets.py  # Upload serverless results to Google Sheets
├── results/                            # Benchmark result CSVs (Locust output)
│   └── aws/                            # Example: AWS EC2 benchmark data
├── docs/
│   └── CLOUD_SECRETS_SETUP.md          # Guide for configuring cloud credentials
└── .github/
    └── workflows/                      # CI/CD workflow definitions
        ├── main.yml                    # Master multi-cloud benchmark workflow
        ├── deploy-aws.yml              # AWS EC2 deployment
        ├── deploy-azure.yml            # Azure VM deployment
        ├── deploy-gcp.yml              # GCP Compute deployment
        ├── deploy-aws-eks.yml          # AWS EKS deployment
        ├── deploy-azure-aks.yml        # Azure AKS deployment
        ├── deploy-gcp-gke.yml          # GCP GKE deployment
        ├── deploy-aws-lambda.yml       # AWS Lambda deployment
        ├── deploy-gcp-cloudrun.yml     # GCP Cloud Run deployment
        └── deploy-azure-container-apps.yml  # Azure Container Apps deployment
```

---

## Getting Started

### Prerequisites

- Python 3.11+
- Docker (optional, for containerised deployment)
- Terraform (optional, for cloud infrastructure)

### Local Setup

```bash
# Clone the repository
git clone https://github.com/ThevinduKevin/resume-screening-nlp-model.git
cd resume-screening-nlp-model

# Install dependencies
pip install -r requirements.txt

# Start the API server
uvicorn app:app --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`. Interactive docs are served at `http://localhost:8000/docs` (Swagger UI).

### Docker

```bash
# Build the container image
docker build -t resume-screening-api .

# Run the container
docker run -p 8000:8000 resume-screening-api
```

For the AWS Lambda variant:

```bash
docker build -f Dockerfile.lambda -t resume-screening-lambda .
```

---

## Multi-Cloud Deployment Architecture

The API is deployed to **nine environments** across three cloud providers and three deployment paradigms:

|  | **AWS** | **Azure** | **GCP** |
|--|---------|-----------|---------|
| **VM (IaaS)** | EC2 (`t3.large`) | Virtual Machine (`Standard_D2s_v3`) | Compute Engine (`e2-standard-2`) |
| **Managed Kubernetes (CaaS)** | EKS | AKS | GKE |
| **Serverless** | Lambda | Container Apps | Cloud Run |

### VM Deployments (IaaS)

Each VM is provisioned with Terraform, receives the application code and model files, and runs the FastAPI server directly via `uvicorn` on port 8000.

- **AWS**: EC2 instance with an IAM role for S3 access, a security group opening ports 22 and 8000.
- **Azure**: VM with a startup script to install dependencies.
- **GCP**: Compute Engine instance with a startup script.

### Managed Kubernetes (CaaS)

The Docker image is pushed to each provider's container registry and deployed using the shared Kubernetes manifests in `k8s/`:

- **Deployment** — single replica, 2 Gi memory request / 7 Gi limit, 500 m CPU request / 1500 m limit, with readiness and liveness probes on `/health`.
- **Service** — `LoadBalancer` type exposing port 8000.

### Serverless (FaaS / Managed Containers)

- **AWS Lambda** — uses `Dockerfile.lambda` with the Mangum adapter to run FastAPI inside Lambda.
- **GCP Cloud Run** — uses the standard `Dockerfile` deployed as a managed container.
- **Azure Container Apps** — uses the standard `Dockerfile` deployed as a managed container.

---

## Infrastructure as Code (Terraform)

All cloud infrastructure is defined in the `terraform/` directory with one sub-directory per deployment target. Each module includes:

| File | Purpose |
|------|---------|
| `main.tf` | Provider configuration, resource definitions |
| `variables.tf` | Input variables (region, instance type, SSH key, etc.) |
| `outputs.tf` | Outputs (public IP, endpoint URL, etc.) |

Terraform state is stored remotely in a **GCS backend** (`resume-screening-ml-terraform-bucket`) to enable CI/CD runs.

```bash
# Example: deploy to AWS EC2
cd terraform/aws
terraform init
terraform apply -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

---

## CI/CD — GitHub Actions

The `.github/workflows/` directory contains automated pipelines for every deployment target:

| Workflow | Description |
|----------|-------------|
| `main.yml` | **Master workflow** — selectively triggers any combination of the nine deployment benchmarks via `workflow_dispatch` inputs |
| `deploy-aws.yml` | Deploys to AWS EC2, runs load tests, collects metrics |
| `deploy-azure.yml` | Deploys to Azure VM, runs load tests, collects metrics |
| `deploy-gcp.yml` | Deploys to GCP Compute Engine, runs load tests, collects metrics |
| `deploy-aws-eks.yml` | Deploys to AWS EKS, runs load tests, collects metrics |
| `deploy-azure-aks.yml` | Deploys to Azure AKS, runs load tests, collects metrics |
| `deploy-gcp-gke.yml` | Deploys to GCP GKE, runs load tests, collects metrics |
| `deploy-aws-lambda.yml` | Deploys to AWS Lambda, runs load tests, measures cold starts |
| `deploy-gcp-cloudrun.yml` | Deploys to GCP Cloud Run, runs load tests, measures cold starts |
| `deploy-azure-container-apps.yml` | Deploys to Azure Container Apps, runs load tests, measures cold starts |

Each workflow follows the same pattern:
1. **Provision** infrastructure with Terraform
2. **Deploy** the application (copy code / push Docker image)
3. **Run** Locust load tests at 1, 10, 100, 1,000, and 2,000 concurrent users
4. **Collect** system metrics (CPU, memory, load average, network I/O)
5. **Upload** results to a Google Sheet for cross-cloud comparison
6. **Tear down** infrastructure to avoid ongoing costs

---

## Performance Benchmarking

### Load Testing with Locust

The load-testing script (`locustfile.py`) defines two tasks:

| Task | Weight | Description |
|------|--------|-------------|
| `predict_text` | 4× | POST to `/predict/text` with a sample resume |
| `health_check` | 1× | GET to `/health` |

The automated runner (`scripts/run_locust.sh`) executes five sequential test runs at increasing concurrency levels (**1 → 10 → 100 → 1,000 → 2,000 users**), each lasting **2 minutes**.

### Cold Start Measurement

For serverless deployments, `scripts/measure_cold_starts.py` measures cold-start latency by:

1. Sending an initial warm-up request.
2. Waiting a configurable idle period (default 60 s) for the service to scale to zero.
3. Sending a request and recording the cold-start response time.
4. Sending follow-up warm requests for comparison.
5. Repeating the cycle for multiple cold-start tests.

### Metrics Collection & Reporting

| Script | Purpose |
|--------|---------|
| `scripts/collect_metrics.py` | Collects local CPU and memory usage every second for 180 samples (configurable in script) |
| `scripts/collect_remote_metrics.sh` | Collects CPU, memory, disk, network I/O, and load average on the deployed VM |
| `scripts/upload_to_sheets.py` | Parses Locust results and system metrics, uploads to Google Sheets (VM benchmarks) |
| `scripts/upload_k8s_to_sheets.py` | Same as above, for Kubernetes benchmarks (includes pod metrics) |
| `scripts/upload_serverless_to_sheets.py` | Same as above, for serverless benchmarks (includes cold-start metrics) |

All results are uploaded to a shared **Google Sheets** spreadsheet with separate worksheets for VM, Kubernetes, and Serverless benchmarks, enabling side-by-side comparison.

---

## Results

Benchmark output CSVs are stored in the `results/` directory. Each Locust run produces:

- `locust_{users}_stats.csv` — aggregated statistics (request count, failure count, median / avg / min / max response times, requests/sec, percentiles)
- `locust_{users}_stats_history.csv` — time-series statistics
- `locust_{users}_failures.csv` — details of failed requests
- `locust_{users}_exceptions.csv` — exception traces
- `system_metrics.csv` — CPU and memory usage during the test

---

## Technologies Used

| Category | Technologies |
|----------|-------------|
| **Machine Learning** | scikit-learn, NumPy, pandas |
| **NLP** | TF-IDF (scikit-learn), regex-based text cleaning |
| **API Framework** | FastAPI, Uvicorn, Gunicorn |
| **Serverless Adapter** | Mangum (FastAPI → AWS Lambda) |
| **File Parsing** | PyPDF2 (PDF), python-docx (DOCX) |
| **Containerisation** | Docker |
| **Orchestration** | Kubernetes (EKS, AKS, GKE) |
| **Infrastructure as Code** | Terraform |
| **CI/CD** | GitHub Actions |
| **Load Testing** | Locust |
| **Cloud Providers** | AWS, Microsoft Azure, Google Cloud Platform |
| **Data Visualisation** | Matplotlib, Seaborn |
| **Results Storage** | Google Sheets (via `gspread`) |

---

## Cloud Secrets Setup

To run the CI/CD workflows, the following GitHub repository secrets must be configured:

| Cloud | Secret | Type |
|-------|--------|------|
| AWS | `AWS_ACCESS_KEY_ID` | String |
| AWS | `AWS_SECRET_ACCESS_KEY` | String |
| Azure | `AZURE_CREDENTIALS` | JSON |
| GCP | `GCP_CREDENTIALS` | JSON |
| GCP | `GCP_PROJECT_ID` | String |

For detailed setup instructions, see [`docs/CLOUD_SECRETS_SETUP.md`](docs/CLOUD_SECRETS_SETUP.md).

---

## License

This project is for academic and research purposes.
