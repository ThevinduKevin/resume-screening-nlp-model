#!/bin/bash
# Collect system metrics on the remote instance
# Usage: collect_remote_metrics.sh <output_file> <duration_seconds> <interval_seconds>

OUTPUT_FILE="${1:-/tmp/instance_metrics.csv}"
DURATION="${2:-300}"
INTERVAL="${3:-5}"

echo "timestamp,cpu_percent,memory_percent,memory_used_mb,memory_total_mb,disk_percent,network_rx_bytes,network_tx_bytes,load_avg_1m,load_avg_5m,load_avg_15m" > "$OUTPUT_FILE"

END_TIME=$(($(date +%s) + DURATION))
PREV_RX=0
PREV_TX=0

while [ $(date +%s) -lt $END_TIME ]; do
    TIMESTAMP=$(date +%s.%N)
    
    # CPU usage (average across all cores)
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    # Memory usage
    MEM_INFO=$(free -m | grep Mem)
    MEM_TOTAL=$(echo $MEM_INFO | awk '{print $2}')
    MEM_USED=$(echo $MEM_INFO | awk '{print $3}')
    MEM_PERCENT=$(awk "BEGIN {printf \"%.1f\", ($MEM_USED/$MEM_TOTAL)*100}")
    
    # Disk usage
    DISK_PERCENT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
    
    # Network I/O (cumulative bytes)
    NET_INFO=$(cat /proc/net/dev | grep -E "eth0|ens" | head -1)
    if [ -n "$NET_INFO" ]; then
        RX_BYTES=$(echo $NET_INFO | awk '{print $2}')
        TX_BYTES=$(echo $NET_INFO | awk '{print $10}')
    else
        RX_BYTES=0
        TX_BYTES=0
    fi
    
    # Load average
    LOAD_AVG=$(cat /proc/loadavg)
    LOAD_1=$(echo $LOAD_AVG | awk '{print $1}')
    LOAD_5=$(echo $LOAD_AVG | awk '{print $2}')
    LOAD_15=$(echo $LOAD_AVG | awk '{print $3}')
    
    echo "$TIMESTAMP,$CPU,$MEM_PERCENT,$MEM_USED,$MEM_TOTAL,$DISK_PERCENT,$RX_BYTES,$TX_BYTES,$LOAD_1,$LOAD_5,$LOAD_15" >> "$OUTPUT_FILE"
    
    sleep $INTERVAL
done

echo "Metrics collection complete: $OUTPUT_FILE"
