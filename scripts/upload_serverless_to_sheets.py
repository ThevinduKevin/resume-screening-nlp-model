#!/usr/bin/env python3
"""
Upload Serverless benchmark results to Google Sheets for comparison.
Requires GCP credentials with access to the Google Sheet.
"""

import os
import csv
import sys
from datetime import datetime, timezone

import gspread
from google.oauth2.service_account import Credentials

# Google Sheet ID - same spreadsheet as VM and K8s benchmarks
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


def parse_cold_start_metrics(results_dir):
    """Parse cold start metrics from serverless tests."""
    metrics_file = os.path.join(results_dir, "cold_start_metrics.csv")
    
    if not os.path.exists(metrics_file):
        print(f"Warning: {metrics_file} not found")
        return None
    
    try:
        cold_starts = []
        warm_starts = []
        
        with open(metrics_file, "r") as f:
            reader = csv.DictReader(f)
            for row in reader:
                response_time = safe_float(row.get("response_time_ms", 0))
                is_cold = row.get("is_cold_start", "").lower() == "true"
                
                if is_cold:
                    cold_starts.append(response_time)
                else:
                    warm_starts.append(response_time)
        
        result = {}
        if cold_starts:
            result["cold_start_count"] = len(cold_starts)
            result["cold_start_avg"] = sum(cold_starts) / len(cold_starts)
            result["cold_start_max"] = max(cold_starts)
            result["cold_start_min"] = min(cold_starts)
        
        if warm_starts:
            result["warm_start_count"] = len(warm_starts)
            result["warm_start_avg"] = sum(warm_starts) / len(warm_starts)
        
        return result if result else None
    
    except Exception as e:
        print(f"Error parsing cold start metrics: {e}")
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
    """Upload Serverless benchmark results to Google Sheets."""
    
    credentials = get_credentials()
    gc = gspread.authorize(credentials)
    
    spreadsheet = gc.open_by_key(SPREADSHEET_ID)
    
    # Define headers for Serverless benchmark
    headers = [
        "Timestamp", "Cloud Provider", "Service Type", "User Count",
        "Request Count", "Failure Count", "Failure Rate (%)",
        "Median Response (ms)", "Avg Response (ms)", 
        "Min Response (ms)", "Max Response (ms)",
        "Requests/sec", "P50 (ms)", "P95 (ms)", "P99 (ms)",
        "Cold Start Count", "Cold Start Avg (ms)", "Cold Start Max (ms)",
        "Cold Start Min (ms)", "Warm Start Count", "Warm Start Avg (ms)",
        "Runner Avg CPU (%)", "Runner Max CPU (%)"
    ]
    
    # Map provider names to service types
    service_map = {
        "aws-lambda": ("AWS", "Lambda"),
        "gcp-cloudrun": ("GCP", "Cloud Run"),
        "azure-container-apps": ("Azure", "Container Apps")
    }
    
    cloud, service_type = service_map.get(cloud_provider, (cloud_provider.upper(), "Serverless"))
    
    # Get or create the worksheet
    try:
        worksheet = spreadsheet.worksheet("Serverless Benchmark Results")
        current_headers = worksheet.row_values(1)
        if len(current_headers) < len(headers):
            print("Updating headers with new columns...")
            worksheet.update('A1:W1', [headers])
            worksheet.format('A1:W1', {'textFormat': {'bold': True}})
    except gspread.WorksheetNotFound:
        worksheet = spreadsheet.add_worksheet(title="Serverless Benchmark Results", rows=100, cols=26)
        worksheet.update('A1:W1', [headers])
        worksheet.format('A1:W1', {'textFormat': {'bold': True}})
    
    user_counts = [1, 10, 100, 1000, 2000]
    
    # Parse cold start metrics
    cold_start_metrics = parse_cold_start_metrics(results_dir)
    
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
                service_type,
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
                cold_start_metrics.get("cold_start_count", "") if cold_start_metrics else "",
                round(cold_start_metrics.get("cold_start_avg", 0), 2) if cold_start_metrics and cold_start_metrics.get("cold_start_avg") else "",
                round(cold_start_metrics.get("cold_start_max", 0), 2) if cold_start_metrics and cold_start_metrics.get("cold_start_max") else "",
                round(cold_start_metrics.get("cold_start_min", 0), 2) if cold_start_metrics and cold_start_metrics.get("cold_start_min") else "",
                cold_start_metrics.get("warm_start_count", "") if cold_start_metrics else "",
                round(cold_start_metrics.get("warm_start_avg", 0), 2) if cold_start_metrics and cold_start_metrics.get("warm_start_avg") else "",
                round(system_metrics["avg_cpu"], 2) if system_metrics else "",
                round(system_metrics["max_cpu"], 2) if system_metrics else "",
            ]
            rows_to_add.append(row)
            print(f"Parsed results for {cloud} {service_type} with {user_count} users")
    
    if rows_to_add:
        worksheet.append_rows(rows_to_add, value_input_option='USER_ENTERED')
        print(f"Successfully uploaded {len(rows_to_add)} rows for {cloud} {service_type}")
    else:
        print(f"No results found for {cloud} {service_type}")


def main():
    if len(sys.argv) != 3:
        print("Usage: python upload_serverless_to_sheets.py <cloud_provider> <results_dir>")
        print("  cloud_provider: aws-lambda, gcp-cloudrun, or azure-container-apps")
        print("  results_dir: path to results directory")
        sys.exit(1)
    
    cloud_provider = sys.argv[1]
    results_dir = sys.argv[2]
    
    valid_providers = ["aws-lambda", "gcp-cloudrun", "azure-container-apps"]
    if cloud_provider not in valid_providers:
        print(f"Invalid cloud provider: {cloud_provider}")
        print(f"Valid options: {', '.join(valid_providers)}")
        sys.exit(1)
    
    if not os.path.exists(results_dir):
        print(f"Results directory not found: {results_dir}")
        sys.exit(1)
    
    upload_results(cloud_provider, results_dir)


if __name__ == "__main__":
    main()
