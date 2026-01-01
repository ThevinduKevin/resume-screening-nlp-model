#!/bin/bash
set -e

mkdir -p results

# WAIT LOGIC: Wait up to 5 minutes for the API to come online
echo "Waiting for API at http://$TARGET_IP:8000/health..."
MAX_RETRIES=30
COUNT=0
while ! curl -s --fail http://$TARGET_IP:8000/health; do
    echo "API not ready (Attempt $COUNT/$MAX_RETRIES). Sleeping 10s..."
    sleep 10
    COUNT=$((COUNT+1))
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "Error: API failed to start in time."
        exit 1
    fi
done

USERS_LIST=("1" "10" "100" "1000"  "2000") # Start with smaller increments
SPAWN_RATE=("1" "10" "10" "10" "10")

for i in ${!USERS_LIST[@]}; do
  USERS=${USERS_LIST[$i]}
  RATE=${SPAWN_RATE[$i]}

  echo "Starting Load Test: Users=$USERS, Rate=$RATE"

  python3 -m locust \
    -f locustfile.py \
    --host http://$TARGET_IP:8000 \
    --headless \
    -u $USERS \
    -r $RATE \
    --run-time 1m \
    --csv results/locust_${USERS} \
    --logfile results/locust_${USERS}.log
done