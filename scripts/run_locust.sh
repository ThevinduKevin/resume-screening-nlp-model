#!/bin/bash
set -e

mkdir -p results

USERS_LIST=("1" "10" "100" "1000" "2000")
SPAWN_RATE=("1" "10" "10" "10" "10")

for i in ${!USERS_LIST[@]}; do
  USERS=${USERS_LIST[$i]}
  RATE=${SPAWN_RATE[$i]}

  echo "Running load test: users=$USERS rate=$RATE"

  python3 -m locust \
    -f locustfile.py \
    --host http://$TARGET_IP:8000 \
    --headless \
    -u $USERS \
    -r $RATE \
    --run-time 2m \
    --csv results/locust_${USERS}
done
