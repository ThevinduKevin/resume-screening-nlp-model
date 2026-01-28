#!/usr/bin/env python3
"""
Upload benchmark results to Google Sheets for comparison.
Requires GCP credentials with access to the Google Sheet.
"""

import os
import csv
import sys
from datetime import datetime, timezone

import gspread
from google.oauth2.service_account import Credentials

# Google Sheet ID from the URL
SPREADSHEET_ID = "1uX2OFJXOWsPlktGLeZIcvoecs8I5Sg_xT-7GGGRDXk8"

# Scopes required for Google Sheets API
SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive"
]


def get_credentials():
    """Get credentials from environment or default application credentials."""
    # Check for GOOGLE_APPLICATION_CREDENTIALS environment variable
    creds_file = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if creds_file and os.path.exists(creds_file):
        return Credentials.from_service_account_file(creds_file, scopes=SCOPES)
    
    # Fall back to application default credentials
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


def parse_instance_metrics(results_dir):
    """Parse instance metrics CSV and compute averages."""
    metrics_file = os.path.join(results_dir, "instance_metrics.csv")
    
    if not os.path.exists(metrics_file):
        print(f"Warning: {metrics_file} not found")
        return None
    
    cpu_values = []
    mem_values = []
    load_1_values = []
    
    with open(metrics_file, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            cpu_values.append(safe_float(row.get("cpu_percent", 0)))
            mem_values.append(safe_float(row.get("memory_percent", 0)))
            load_1_values.append(safe_float(row.get("load_avg_1m", 0)))
    
    if not cpu_values:
        return None
    
    return {
        "avg_cpu": sum(cpu_values) / len(cpu_values),
        "max_cpu": max(cpu_values),
        "avg_memory": sum(mem_values) / len(mem_values),
        "max_memory": max(mem_values),
        "avg_load": sum(load_1_values) / len(load_1_values),
        "max_load": max(load_1_values),
    }


def upload_results(cloud_provider, results_dir):
    """Upload benchmark results to Google Sheets."""
    
    # Get credentials and connect to Google Sheets
    credentials = get_credentials()
    gc = gspread.authorize(credentials)
    
    # Open the spreadsheet
    spreadsheet = gc.open_by_key(SPREADSHEET_ID)
    
    # Get or create the worksheet
    try:
        worksheet = spreadsheet.worksheet("Benchmark Results")
    except gspread.WorksheetNotFound:
        worksheet = spreadsheet.add_worksheet(title="Benchmark Results", rows=100, cols=26)
        # Add headers
        headers = [
            "Timestamp", "Cloud Provider", "User Count",
            "Request Count", "Failure Count", "Failure Rate (%)",
            "Median Response (ms)", "Avg Response (ms)", 
            "Min Response (ms)", "Max Response (ms)",
            "Requests/sec", "P50 (ms)", "P95 (ms)", "P99 (ms)",
            "Avg CPU (%)", "Max CPU (%)", "Avg Memory (%)", "Max Memory (%)",
            "Avg Load", "Max Load"
        ]
        worksheet.update('A1:T1', [headers])
        # Format header row
        worksheet.format('A1:T1', {'textFormat': {'bold': True}})
    
    # User counts to process
    user_counts = [1, 10, 100, 1000, 2000]
    
    # Parse instance metrics (shared across all user counts)
    instance_metrics = parse_instance_metrics(results_dir)
    
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    rows_to_add = []
    
    for user_count in user_counts:
        stats = parse_locust_stats(results_dir, user_count)
        if stats:
            failure_rate = (stats["failure_count"] / stats["request_count"] * 100) if stats["request_count"] > 0 else 0
            row = [
                timestamp,
                cloud_provider.upper(),
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
                round(instance_metrics["avg_cpu"], 2) if instance_metrics else "",
                round(instance_metrics["max_cpu"], 2) if instance_metrics else "",
                round(instance_metrics["avg_memory"], 2) if instance_metrics else "",
                round(instance_metrics["max_memory"], 2) if instance_metrics else "",
                round(instance_metrics["avg_load"], 2) if instance_metrics else "",
                round(instance_metrics["max_load"], 2) if instance_metrics else "",
            ]
            rows_to_add.append(row)
            print(f"Parsed results for {cloud_provider.upper()} with {user_count} users")
    
    if rows_to_add:
        # Append rows to the worksheet
        worksheet.append_rows(rows_to_add, value_input_option='USER_ENTERED')
        print(f"Successfully uploaded {len(rows_to_add)} rows for {cloud_provider.upper()}")
    else:
        print(f"No results found for {cloud_provider.upper()}")


def main():
    if len(sys.argv) != 3:
        print("Usage: python upload_to_sheets.py <cloud_provider> <results_dir>")
        print("  cloud_provider: aws, azure, or gcp")
        print("  results_dir: path to results directory")
        sys.exit(1)
    
    cloud_provider = sys.argv[1]
    results_dir = sys.argv[2]
    
    if cloud_provider not in ["aws", "azure", "gcp"]:
        print(f"Invalid cloud provider: {cloud_provider}")
        sys.exit(1)
    
    if not os.path.exists(results_dir):
        print(f"Results directory not found: {results_dir}")
        sys.exit(1)
    
    upload_results(cloud_provider, results_dir)


if __name__ == "__main__":
    main()
