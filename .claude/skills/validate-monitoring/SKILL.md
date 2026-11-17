---
name: validate-monitoring
description: Validate the whole monitoring lab (compose, Prometheus config, rules and rule unit tests, Alertmanager config, Grafana dashboard JSON, yamllint) and optionally smoke-test the running stack. Use before every commit, after editing anything under prometheus/, alertmanager/, grafana/ or docker-compose.yml, or when the user asks "does it still work?".
---

# Validate monitoring lab

## 1. Static checks (always)

```bash
./scripts/check.sh
```

It must end with `All checks passed.` If a step fails:

| Failing step | Usual cause |
|---|---|
| `promtool check config` | Wrong indentation, unknown field, rule file glob matches nothing |
| `promtool check rules` | PromQL syntax error, duplicate rule name, bad template in annotation |
| `promtool test rules` | Alert labels/annotations in the test no longer match the rule (after changing a threshold or wording), or `for:` changed so `eval_time` is too early |
| `amtool check-config` | Receiver referenced in `route` but not defined, bad matcher syntax |
| dashboards | Invalid JSON or missing `uid` |
| yamllint | Line too long, trailing spaces, missing `---` |

Fix the cause, never weaken or delete a test to make it pass.

## 2. Runtime smoke test (when Docker is available and the change touches runtime behaviour)

```bash
docker compose up -d --wait
```

Then check, in order:

```bash
# every target must be "up"
curl -s localhost:9090/api/v1/targets | python3 -c "import sys,json; [print(t['labels']['job'], t['health'], t['lastError']) for t in json.load(sys.stdin)['data']['activeTargets']]"

# every rule must be "ok"
curl -s localhost:9090/api/v1/rules | python3 -c "import sys,json; [print(r['name'], r['health'], r.get('lastError','')) for g in json.load(sys.stdin)['data']['groups'] for r in g['rules']]"

# dashboards provisioned
curl -s -u admin:admin 'localhost:3000/api/search?type=dash-db' | python3 -c "import sys,json; [print(d['uid'], d['title']) for d in json.load(sys.stdin)]"

# cAdvisor sees containers by name (empty => see README troubleshooting)
curl -s 'localhost:9090/api/v1/query?query=count%20by%20(name)(container_last_seen%7Bname!%3D%22%22%7D)' | python3 -m json.tool | grep '"name"'
```

## 3. Report

Report each step as passed / failed (with the error) / skipped (with the reason, e.g. no Docker). Do not claim the stack works if only static checks ran.
