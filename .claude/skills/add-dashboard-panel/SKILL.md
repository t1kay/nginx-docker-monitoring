---
name: add-dashboard-panel
description: Add or change a panel in a provisioned Grafana dashboard (grafana/dashboards/*.json) - test the PromQL in Prometheus, edit the JSON with the right datasource uid/unit/legend, reload and verify the panel shows data. Use when the user wants a new chart, stat, or a change to an existing dashboard.
---

# Add a dashboard panel

## 1. Get the query right in Prometheus first

Run the PromQL at http://localhost:9090/graph (or via `curl localhost:9090/api/v1/query --data-urlencode 'query=...'`).
- Counter => wrap in `rate(...[1m])`; aggregate with `sum by (<label>)` to keep only the labels the panel needs.
- Prefer an existing recording rule (`prometheus/rules/recording.rules.yml`).
- On the containers dashboard, filter with the variable: `{name=~"$container"}`.

## 2. Edit the dashboard JSON

Dashboards are provisioned with `allowUiUpdates: false`, so edit the file in `grafana/dashboards/`.
Copy an existing panel of the same type and change:

| Field | Rule |
|---|---|
| `id` | unique within the dashboard (max existing + 1) |
| `gridPos` | `w` 12 = half width, 24 = full; place below the last row (`y` = last `y` + its `h`) |
| `datasource` | `{"type": "prometheus", "uid": "prometheus"}` on the panel and on each target |
| `targets[].legendFormat` | e.g. `{{name}}`; `refId` A, B, C... |
| `fieldConfig.defaults.unit` | `reqps`, `percent` (0-100), `percentunit` (0-1), `bytes`, `Bps`, `s` |
| `description` | one sentence explaining the query when it is not obvious |

Alternative: build the panel in the UI on a copy of the dashboard, then **Share -> Export -> JSON** and copy only the panel object back, replacing the datasource with the uid form above.

## 3. Reload and verify

```bash
./scripts/check.sh                       # JSON valid + uid present
```

Grafana re-reads the folder every 30 s (`updateIntervalSeconds`). Then:

```bash
curl -s -u admin:admin localhost:3000/api/dashboards/uid/<uid> | python3 -c "import sys,json; print([p['title'] for p in json.load(sys.stdin)['dashboard']['panels']])"
```

Open the dashboard and confirm the panel shows data (run `./scripts/load-test.sh` if it needs traffic). "No data" usually means a wrong metric/label name or a datasource that is not the uid form.

## 4. Document

Add the panel and its PromQL to the table in `docs/promql-cheatsheet.md`.
