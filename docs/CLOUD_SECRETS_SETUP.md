# Cloud Provider Secrets Setup Guide

This guide explains how to configure GitHub Secrets for the Multi-Cloud ML Benchmark workflow.

## Adding Secrets to GitHub

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret listed below

---

## AWS (Amazon Web Services)

### Required Secrets

| Secret Name | Description |
|-------------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key ID |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret access key |

### How to Get AWS Credentials

1. Go to [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. Navigate to **Users** → Select your user (or create a new one)
3. Go to **Security credentials** tab
4. Click **Create access key**
5. Select **Command Line Interface (CLI)**
6. Copy the **Access key ID** and **Secret access key**

### Required IAM Permissions

The IAM user needs the following permissions:
- `ec2:*` - EC2 instance management
- `iam:*` - IAM role creation for EC2
- `s3:GetObject`, `s3:ListBucket` - Access to ML model bucket

Example IAM policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRole",
        "iam:GetInstanceProfile",
        "iam:PassRole"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::resume-screening-ml-models-thevindu",
        "arn:aws:s3:::resume-screening-ml-models-thevindu/*"
      ]
    }
  ]
}
```

---

## Azure (Microsoft Azure)

### Required Secrets

| Secret Name | Description |
|-------------|-------------|
| `AZURE_CREDENTIALS` | Azure service principal JSON |

### How to Get Azure Credentials

1. Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

2. Login to Azure:
   ```bash
   az login
   ```

3. Create a service principal:
   ```bash
   az ad sp create-for-rbac --name "github-actions-ml-benchmark" \
     --role contributor \
     --scopes /subscriptions/{subscription-id} \
     --sdk-auth
   ```

4. Copy the entire JSON output and paste it as the `AZURE_CREDENTIALS` secret.

### Expected JSON Format

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "your-client-secret",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### Required Azure Permissions

The service principal needs **Contributor** role on the subscription or resource group.

---

## GCP (Google Cloud Platform)

### Required Secrets

| Secret Name | Description |
|-------------|-------------|
| `GCP_CREDENTIALS` | GCP service account key JSON |
| `GCP_PROJECT_ID` | Your GCP project ID (e.g., `my-project-123456`) |

### How to Get GCP Credentials

1. Go to [GCP Console](https://console.cloud.google.com/)

2. Navigate to **IAM & Admin** → **Service Accounts**

3. Click **Create Service Account**:
   - Name: `github-actions-ml-benchmark`
   - Click **Create and Continue**

4. Grant roles:
   - `Compute Admin` (roles/compute.admin)
   - `Service Account User` (roles/iam.serviceAccountUser)

5. Click **Done**

6. Click on the created service account → **Keys** tab

7. Click **Add Key** → **Create new key** → **JSON**

8. Download the JSON file and paste its contents as `GCP_CREDENTIALS`

### Expected JSON Format

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "github-actions@your-project.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

### Enable Required APIs

Make sure these APIs are enabled in your GCP project:
```bash
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
```

---

## Summary: All Required Secrets

| Cloud | Secret Name | Type |
|-------|-------------|------|
| AWS | `AWS_ACCESS_KEY_ID` | String |
| AWS | `AWS_SECRET_ACCESS_KEY` | String |
| Azure | `AZURE_CREDENTIALS` | JSON |
| GCP | `GCP_CREDENTIALS` | JSON |
| GCP | `GCP_PROJECT_ID` | String |

---

## Security Best Practices

1. **Use least privilege** - Only grant permissions that are absolutely necessary
2. **Rotate credentials regularly** - Update secrets every 90 days
3. **Never commit credentials** - Always use GitHub Secrets
4. **Use separate accounts** - Create dedicated service accounts for CI/CD
5. **Monitor usage** - Enable cloud audit logs to track API usage

---

## Troubleshooting

### AWS
- **Error: "Unable to locate credentials"** - Check that both `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set correctly
- **Error: "Access Denied"** - Verify the IAM user has the required permissions

### Azure
- **Error: "AADSTS700016"** - The service principal may have expired; recreate it
- **Error: "AuthorizationFailed"** - Ensure the service principal has Contributor role

### GCP
- **Error: "Could not load the default credentials"** - Verify `GCP_CREDENTIALS` JSON is valid
- **Error: "Compute Engine API has not been used"** - Enable the Compute Engine API in your project
