#!/usr/bin/env bash
# Validate every config in the repo without starting the stack.
# Uses the same image versions as docker-compose.yml (promtool / amtool).
set -euo pipefail

cd "$(dirname "$0")/.."

PROM_IMAGE=$(grep -oE 'prom/prometheus:[^"[:space:]]+' docker-compose.yml | head -1)
AM_IMAGE=$(grep -oE 'prom/alertmanager:[^"[:space:]]+' docker-compose.yml | head -1)

step() { printf '\n==> %s\n' "$*"; }

promtool() {
  docker run --rm -v "$PWD/prometheus:/etc/prometheus:ro" -w /etc/prometheus \
    --entrypoint promtool "$PROM_IMAGE" "$@"
}

step "docker compose config"
docker compose config -q

step "promtool check config ($PROM_IMAGE)"
promtool check config /etc/prometheus/prometheus.yml

step "promtool check rules"
promtool check rules $(cd prometheus && ls rules/*.rules.yml)

step "promtool test rules"
promtool test rules $(cd prometheus && ls tests/*.test.yml)

step "amtool check-config ($AM_IMAGE)"
docker run --rm -v "$PWD/alertmanager:/etc/alertmanager:ro" \
  --entrypoint amtool "$AM_IMAGE" check-config /etc/alertmanager/alertmanager.yml

step "Grafana dashboards are valid JSON with a fixed uid"
for f in grafana/dashboards/*.json; do
  python3 - "$f" <<'PY'
import json, sys
path = sys.argv[1]
d = json.load(open(path))
assert d.get("uid"), f"{path}: missing uid"
print(f"{path}: ok (uid={d['uid']}, panels={len(d.get('panels', []))})")
PY
done

step "yamllint"
if command -v yamllint >/dev/null 2>&1; then
  yamllint .
else
  echo "yamllint not installed, skipping (pip install yamllint)"
fi

printf '\nAll checks passed.\n'
