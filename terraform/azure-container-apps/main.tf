terraform {
  backend "gcs" {
    bucket = "resume-screening-ml-terraform-bucket"
    prefix = "azure-container-apps"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Register required resource providers using CLI (azurerm_resource_provider_registration has bugs)
resource "terraform_data" "register_providers" {
  provisioner "local-exec" {
    command = "az provider register --namespace Microsoft.App --wait && az provider register --namespace Microsoft.OperationalInsights --wait"
  }
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Log Analytics Workspace (required for Container Apps)
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "ml-serverless-logs"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container Apps Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "ml-serverless-env"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  workload_profile {
    name                  = "Dedicated-D4"
    workload_profile_type = "D4" # General Purpose (4 vCPU / 16 GiB)
  }

  depends_on = [terraform_data.register_providers]
}

# Container App
resource "azurerm_container_app" "ml_api" {
  name                         = var.app_name
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  workload_profile_name = "Dedicated-D4"

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  template {
    container {
      name   = "ml-api"
      image  = "${azurerm_container_registry.acr.login_server}/ml-resume-api:latest"
      cpu    = var.cpu_cores
      memory = var.memory_size

      env {
        name  = "ENVIRONMENT"
        value = "serverless"
      }

      liveness_probe {
        path             = "/health"
        port             = 8000
        transport        = "HTTP"
        interval_seconds = 30
        timeout          = 5
      }

      readiness_probe {
        path             = "/health"
        port             = 8000
        transport        = "HTTP"
        interval_seconds = 10
        timeout          = 5
      }

      startup_probe {
        path                    = "/health"
        port                    = 8000
        transport               = "HTTP"
        interval_seconds        = 10
        timeout                 = 5
        failure_count_threshold = 10
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    http_scale_rule {
      name                = "http-scaling"
      concurrent_requests = 10
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }
}
