#!/usr/bin/env bash
# Generate traffic to Nginx so the dashboards (and alerts) have something to show.
#
# Usage:
#   scripts/load-test.sh                 # 3 minutes, 80 concurrent connections
#   DURATION=5m CONCURRENCY=150 scripts/load-test.sh
#   ERRORS=1 scripts/load-test.sh        # hit /error (HTTP 500) instead of /
#
# 80 keep-alive connections held for > 1 minute will trigger NginxHighConnections (> 50).
set -euo pipefail

DURATION=${DURATION:-3m}
CONCURRENCY=${CONCURRENCY:-80}
RATE=${RATE:-20}          # requests/s per connection (hey -q), keeps CPU usage reasonable
PATH_TO_HIT=/
[[ "${ERRORS:-0}" == "1" ]] && PATH_TO_HIT=/error

echo "Load test: ${DURATION}, ${CONCURRENCY} connections, ${RATE} req/s each, path ${PATH_TO_HIT}"

if command -v hey >/dev/null 2>&1; then
  hey -z "$DURATION" -c "$CONCURRENCY" -q "$RATE" "http://localhost:8080${PATH_TO_HIT}"
else
  # Run hey inside the compose network and talk to the nginx service directly
  docker run --rm --name load-test --network nginx-docker-monitoring_default williamyeh/hey:latest \
    -z "$DURATION" -c "$CONCURRENCY" -q "$RATE" "http://nginx${PATH_TO_HIT}"
fi
