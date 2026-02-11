#!/bin/bash
set -e

mkdir -p results

USERS_LIST=("1" "10" "100" "1000" "2000")
SPAWN_RATE=("1" "10" "10" "10" "10")

# Determine protocol and port
# For serverless (HTTPS), no port needed
# For VMs/K8s (HTTP), use port 8000
PROTOCOL="${TARGET_PROTOCOL:-http}"
if [ "$PROTOCOL" = "https" ]; then
  HOST_URL="${PROTOCOL}://${TARGET_IP}"
else
  HOST_URL="${PROTOCOL}://${TARGET_IP}:8000"
fi

echo "Using host: $HOST_URL"

for i in ${!USERS_LIST[@]}; do
  USERS=${USERS_LIST[$i]}
  RATE=${SPAWN_RATE[$i]}

  echo "Running load test: users=$USERS rate=$RATE"

  # Run Locust - allow it to complete even with some connection errors
  # Connection errors are expected during load testing
  python -m locust \
    -f locustfile.py \
    --host $HOST_URL \
    --headless \
    -u $USERS \
    -r $RATE \
    --run-time 2m \
    --csv results/locust_${USERS} \
    --csv-full-history \
    --logfile results/locust_${USERS}.log \
    --exit-code-on-error 0
done
