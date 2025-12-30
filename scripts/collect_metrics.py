import psutil
import time
import csv
import os

os.makedirs("results", exist_ok=True)

with open("results/system_metrics.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["timestamp", "cpu_percent", "memory_percent"])

    for _ in range(180):
        writer.writerow([
            time.time(),
            psutil.cpu_percent(interval=1),
            psutil.virtual_memory().percent
        ])
