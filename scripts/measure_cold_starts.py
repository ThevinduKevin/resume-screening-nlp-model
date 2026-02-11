#!/usr/bin/env python3
"""
Measure cold start times for serverless deployments.
This script makes requests and detects cold starts based on response times.
"""

import os
import sys
import csv
import time
import requests
from datetime import datetime

def measure_cold_starts(api_url, output_file, num_cold_start_tests=5, wait_between_tests=60):
    """
    Measure cold starts by making requests after idle periods.
    
    Args:
        api_url: The serverless API URL
        output_file: CSV file to write results
        num_cold_start_tests: Number of cold start tests to run
        wait_between_tests: Seconds to wait between tests to trigger cold starts
    """
    
    health_url = f"{api_url.rstrip('/')}/health"
    results = []
    
    print(f"Measuring cold starts for {api_url}")
    
    # First, warm up the service
    print("Initial warm-up request...")
    try:
        requests.get(health_url, timeout=300)
    except Exception as e:
        print(f"Warm-up request failed: {e}")
    
    # Wait for the service to go cold
    print(f"Waiting {wait_between_tests}s for service to go cold...")
    time.sleep(wait_between_tests)
    
    for i in range(num_cold_start_tests):
        print(f"\nCold start test {i + 1}/{num_cold_start_tests}")
        
        # Make cold start request
        start_time = time.time()
        try:
            response = requests.get(health_url, timeout=300)
            response_time_ms = (time.time() - start_time) * 1000
            success = response.status_code == 200
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            success = False
            print(f"Request failed: {e}")
        
        # First request after idle is considered cold start
        results.append({
            "timestamp": datetime.utcnow().isoformat(),
            "test_number": i + 1,
            "request_type": "cold_start",
            "is_cold_start": "true",
            "response_time_ms": round(response_time_ms, 2),
            "success": success
        })
        print(f"  Cold start response time: {response_time_ms:.2f}ms")
        
        # Make a few warm requests
        for j in range(3):
            time.sleep(1)
            start_time = time.time()
            try:
                response = requests.get(health_url, timeout=60)
                response_time_ms = (time.time() - start_time) * 1000
                success = response.status_code == 200
            except Exception as e:
                response_time_ms = (time.time() - start_time) * 1000
                success = False
            
            results.append({
                "timestamp": datetime.utcnow().isoformat(),
                "test_number": i + 1,
                "request_type": "warm_start",
                "is_cold_start": "false",
                "response_time_ms": round(response_time_ms, 2),
                "success": success
            })
            print(f"  Warm request {j + 1} response time: {response_time_ms:.2f}ms")
        
        # Wait for next cold start test
        if i < num_cold_start_tests - 1:
            print(f"Waiting {wait_between_tests}s for service to go cold...")
            time.sleep(wait_between_tests)
    
    # Write results to CSV
    with open(output_file, "w", newline="") as f:
        fieldnames = ["timestamp", "test_number", "request_type", "is_cold_start", "response_time_ms", "success"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)
    
    print(f"\nResults written to {output_file}")
    
    # Print summary
    cold_starts = [r["response_time_ms"] for r in results if r["is_cold_start"] == "true"]
    warm_starts = [r["response_time_ms"] for r in results if r["is_cold_start"] == "false"]
    
    if cold_starts:
        print(f"\nCold Start Summary:")
        print(f"  Count: {len(cold_starts)}")
        print(f"  Avg: {sum(cold_starts)/len(cold_starts):.2f}ms")
        print(f"  Min: {min(cold_starts):.2f}ms")
        print(f"  Max: {max(cold_starts):.2f}ms")
    
    if warm_starts:
        print(f"\nWarm Start Summary:")
        print(f"  Count: {len(warm_starts)}")
        print(f"  Avg: {sum(warm_starts)/len(warm_starts):.2f}ms")


def main():
    if len(sys.argv) < 3:
        print("Usage: python measure_cold_starts.py <api_url> <output_file> [num_tests] [wait_seconds]")
        print("  api_url: The serverless API URL")
        print("  output_file: Output CSV file path")
        print("  num_tests: Number of cold start tests (default: 5)")
        print("  wait_seconds: Seconds to wait between tests (default: 60)")
        sys.exit(1)
    
    api_url = sys.argv[1]
    output_file = sys.argv[2]
    num_tests = int(sys.argv[3]) if len(sys.argv) > 3 else 5
    wait_seconds = int(sys.argv[4]) if len(sys.argv) > 4 else 60
    
    measure_cold_starts(api_url, output_file, num_tests, wait_seconds)


if __name__ == "__main__":
    main()
