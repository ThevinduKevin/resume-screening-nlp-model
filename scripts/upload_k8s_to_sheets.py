#!/usr/bin/env python3
"""
Upload K8s benchmark results to Google Sheets for comparison.
Requires GCP credentials with access to the Google Sheet.
"""

import os
import csv
import sys
from datetime import datetime, timezone

import gspread
from google.oauth2.service_account import Credentials

# Google Sheet ID - same spreadsheet as VM benchmarks, different worksheet
SPREADSHEET_ID = "1uX2OFJXOWsPlktGLeZIcvoecs8I5Sg_xT-7GGGRDXk8"

# Scopes required for Google Sheets API
SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive"
]


def get_credentials():
    """Get credentials from environment or default application credentials."""
    creds_file = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if creds_file and os.path.exists(creds_file):
        return Credentials.from_service_account_file(creds_file, scopes=SCOPES)
    
    import google.auth
    credentials, _ = google.auth.default(scopes=SCOPES)
    return credentials


def safe_float(value, default=0.0):
    """Safely convert a value to float, handling N/A and empty strings."""
    if value is None or value == "" or value == "N/A":
        return default
    try:
        return float(value)
    except (ValueError, TypeError):
        return default


def safe_int(value, default=0):
    """Safely convert a value to int, handling N/A and empty strings."""
    if value is None or value == "" or value == "N/A":
        return default
    try:
        return int(value)
    except (ValueError, TypeError):
        return default


def parse_locust_stats(results_dir, user_count):
    """Parse Locust stats CSV and extract key metrics."""
    stats_file = os.path.join(results_dir, f"locust_{user_count}_stats.csv")
    
    if not os.path.exists(stats_file):
        print(f"Warning: {stats_file} not found")
        return None
    
    with open(stats_file, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["Name"] == "Aggregated":
                return {
                    "request_count": safe_int(row["Request Count"]),
                    "failure_count": safe_int(row["Failure Count"]),
                    "median_response_time": safe_float(row["Median Response Time"]),
                    "avg_response_time": safe_float(row["Average Response Time"]),
                    "min_response_time": safe_float(row["Min Response Time"]),
                    "max_response_time": safe_float(row["Max Response Time"]),
                    "requests_per_sec": safe_float(row["Requests/s"]),
                    "p50": safe_float(row["50%"]),
                    "p95": safe_float(row["95%"]),
                    "p99": safe_float(row["99%"]),
                }
    return None


def parse_k8s_pod_metrics(results_dir):
    """Parse Kubernetes pod metrics from kubectl top output."""
    metrics_file = os.path.join(results_dir, "k8s_pod_metrics.txt")
    
    if not os.path.exists(metrics_file):
        print(f"Warning: {metrics_file} not found")
        return None
    
    try:
        with open(metrics_file, "r") as f:
            lines = f.readlines()
        
        if len(lines) < 2 or "Metrics not available" in lines[0]:
            return None
        
        # Parse lines like: ml-api-xxxxx   100m   256Mi
        total_cpu_millicores = 0
        total_memory_mi = 0
        pod_count = 0
        
        for line in lines[1:]:  # Skip header
            parts = line.split()
            if len(parts) >= 3 and parts[0].startswith("ml-api"):
                # Parse CPU (e.g., "100m" -> 100)
                cpu = parts[1].replace("m", "")
                total_cpu_millicores += safe_int(cpu)
                
                # Parse Memory (e.g., "256Mi" -> 256)
                mem = parts[2].replace("Mi", "").replace("Gi", "000")
                total_memory_mi += safe_int(mem)
                
                pod_count += 1
        
        if pod_count > 0:
            return {
                "avg_cpu_millicores": total_cpu_millicores / pod_count,
                "total_cpu_millicores": total_cpu_millicores,
                "avg_memory_mi": total_memory_mi / pod_count,
                "total_memory_mi": total_memory_mi,
                "pod_count": pod_count
            }
    except Exception as e:
        print(f"Error parsing K8s metrics: {e}")
    
    return None


def parse_system_metrics(results_dir):
    """Parse system metrics CSV from runner."""
    metrics_file = os.path.join(results_dir, "system_metrics.csv")
    
    if not os.path.exists(metrics_file):
        return None
    
    cpu_values = []
    mem_values = []
    
    try:
        with open(metrics_file, "r") as f:
            reader = csv.DictReader(f)
            for row in reader:
                cpu_values.append(safe_float(row.get("cpu_percent", 0)))
                mem_values.append(safe_float(row.get("memory_percent", 0)))
        
        if cpu_values:
            return {
                "avg_cpu": sum(cpu_values) / len(cpu_values),
                "max_cpu": max(cpu_values),
                "avg_memory": sum(mem_values) / len(mem_values),
                "max_memory": max(mem_values),
            }
    except Exception as e:
        print(f"Error parsing system metrics: {e}")
    
    return None


def upload_results(cloud_provider, results_dir):
    """Upload K8s benchmark results to Google Sheets."""
    
    credentials = get_credentials()
    gc = gspread.authorize(credentials)
    
    spreadsheet = gc.open_by_key(SPREADSHEET_ID)
    
    # Define headers for K8s benchmark
    headers = [
        "Timestamp", "Cloud Provider", "Deployment Type", "User Count",
        "Request Count", "Failure Count", "Failure Rate (%)",
        "Median Response (ms)", "Avg Response (ms)", 
        "Min Response (ms)", "Max Response (ms)",
        "Requests/sec", "P50 (ms)", "P95 (ms)", "P99 (ms)",
        "Pod Count", "Avg CPU (millicores)", "Total CPU (millicores)",
        "Avg Memory (Mi)", "Total Memory (Mi)",
        "Runner Avg CPU (%)", "Runner Max CPU (%)"
    ]
    
    # Map provider names to deployment types
    deployment_map = {
        "aws-eks": ("AWS", "EKS"),
        "gcp-gke": ("GCP", "GKE"),
        "azure-aks": ("Azure", "AKS")
    }
    
    cloud, deployment_type = deployment_map.get(cloud_provider, (cloud_provider.upper(), "K8s"))
    
    # Get or create the worksheet
    try:
        worksheet = spreadsheet.worksheet("K8s Benchmark Results")
        current_headers = worksheet.row_values(1)
        if len(current_headers) < len(headers):
            print("Updating headers with new columns...")
            worksheet.update('A1:V1', [headers])
            worksheet.format('A1:V1', {'textFormat': {'bold': True}})
    except gspread.WorksheetNotFound:
        worksheet = spreadsheet.add_worksheet(title="K8s Benchmark Results", rows=100, cols=26)
        worksheet.update('A1:V1', [headers])
        worksheet.format('A1:V1', {'textFormat': {'bold': True}})
    
    user_counts = [1, 10, 100, 1000, 2000]
    
    # Parse K8s pod metrics
    k8s_metrics = parse_k8s_pod_metrics(results_dir)
    
    # Parse system metrics
    system_metrics = parse_system_metrics(results_dir)
    
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    rows_to_add = []
    
    for user_count in user_counts:
        stats = parse_locust_stats(results_dir, user_count)
        if stats:
            failure_rate = (stats["failure_count"] / stats["request_count"] * 100) if stats["request_count"] > 0 else 0
            row = [
                timestamp,
                cloud,
                deployment_type,
                user_count,
                stats["request_count"],
                stats["failure_count"],
                round(failure_rate, 2),
                round(stats["median_response_time"], 2),
                round(stats["avg_response_time"], 2),
                round(stats["min_response_time"], 2),
                round(stats["max_response_time"], 2),
                round(stats["requests_per_sec"], 4),
                round(stats["p50"], 2),
                round(stats["p95"], 2),
                round(stats["p99"], 2),
                k8s_metrics["pod_count"] if k8s_metrics else "",
                round(k8s_metrics["avg_cpu_millicores"], 2) if k8s_metrics else "",
                k8s_metrics["total_cpu_millicores"] if k8s_metrics else "",
                round(k8s_metrics["avg_memory_mi"], 2) if k8s_metrics else "",
                k8s_metrics["total_memory_mi"] if k8s_metrics else "",
                round(system_metrics["avg_cpu"], 2) if system_metrics else "",
                round(system_metrics["max_cpu"], 2) if system_metrics else "",
            ]
            rows_to_add.append(row)
            print(f"Parsed results for {cloud} {deployment_type} with {user_count} users")
    
    if rows_to_add:
        worksheet.append_rows(rows_to_add, value_input_option='USER_ENTERED')
        print(f"Successfully uploaded {len(rows_to_add)} rows for {cloud} {deployment_type}")
    else:
        print(f"No results found for {cloud} {deployment_type}")


def main():
    if len(sys.argv) != 3:
        print("Usage: python upload_k8s_to_sheets.py <cloud_provider> <results_dir>")
        print("  cloud_provider: aws-eks, gcp-gke, or azure-aks")
        print("  results_dir: path to results directory")
        sys.exit(1)
    
    cloud_provider = sys.argv[1]
    results_dir = sys.argv[2]
    
    if cloud_provider not in ["aws-eks", "gcp-gke", "azure-aks"]:
        print(f"Invalid cloud provider: {cloud_provider}")
        sys.exit(1)
    
    if not os.path.exists(results_dir):
        print(f"Results directory not found: {results_dir}")
        sys.exit(1)
    
    upload_results(cloud_provider, results_dir)


if __name__ == "__main__":
    main()
