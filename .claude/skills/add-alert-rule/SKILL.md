---
name: add-alert-rule
description: Add or change a Prometheus alerting rule end to end - explore the metric, write the rule with for/severity/annotations, add promtool unit tests, reload Prometheus and trigger the alert for real. Use when the user wants a new alert, a different threshold, or asks "alert me when ...".
---

# Add an alert rule

## 1. Find the metric and try the expression

1. List candidate metrics: open http://localhost:9090 and type the prefix (`nginx_`, `container_`, `node_`), or:
   ```bash
   curl -s localhost:9090/api/v1/label/__name__/values | python3 -c "import sys,json; print('\n'.join(m for m in json.load(sys.stdin)['data'] if m.startswith('nginx_')))"
   ```
2. Decide the metric type: name ends in `_total` => counter => must use `rate()`/`increase()`. Otherwise usually a gauge.
3. Run the expression without the threshold first and look at the current values, then pick a threshold the user can explain.
4. If the expression is reused by a dashboard, or is long, add a recording rule in `prometheus/rules/recording.rules.yml` (name `level:metric:operations`) and alert on that.

## 2. Write the rule

Add it to the right group in `prometheus/rules/alerts.rules.yml`:

```yaml
- alert: CamelCaseName
  expr: <expression> > <threshold>
  for: 2m
  labels:
    severity: warning        # or critical
  annotations:
    summary: "Short one-line summary with {{ $labels.name }}"
    description: "What is wrong, where, current value {{ $value }} and threshold."
```

Rules: `for` is mandatory, `severity` is `warning` or `critical`, both annotations mandatory.
If the new alert is a consequence of another (e.g. container down => its metrics high), add an inhibit rule in `alertmanager/alertmanager.yml`.

## 3. Unit test

Add a block to `prometheus/tests/alerts.test.yml` with:
- `input_series` that crosses the threshold (`values: "120x8"` = 120 repeated, `"0+13.5x40"` = counter growing 13.5 per step);
- one `alert_rule_test` before `for` elapses with `exp_alerts: []`;
- one after, with the exact expected labels and rendered annotations.

Run `./scripts/check.sh`; it must pass.

## 4. Try it for real

```bash
curl -X POST localhost:9090/-/reload
```

Generate the condition (`./scripts/load-test.sh`, `docker compose stop nginx`, etc.), then watch http://localhost:9090/alerts go Inactive -> Pending -> Firing and confirm it appears in http://localhost:9093.

## 5. Document

Add the alert to the "Alert rules" table in `README.md`.
