# CLAUDE.md

Lab giám sát Nginx + Docker containers bằng Prometheus, Grafana, Alertmanager, chạy hoàn toàn bằng Docker Compose.
Mục tiêu học tập: mọi thay đổi phải dễ đọc, có giải thích ngắn, và chạy được bằng `docker compose up`.

## Lệnh thường dùng

```bash
docker compose up -d --wait          # dựng stack
./scripts/check.sh                    # kiểm tra toàn bộ config + unit test rules (chạy trước mỗi commit)
./scripts/load-test.sh                # tạo tải để thấy dashboard/alert thay đổi
curl -X POST localhost:9090/-/reload  # nạp lại prometheus.yml và rules
docker compose down -v                # dừng và xoá dữ liệu
```

## Bố cục

- `docker-compose.yml`: 7 service (nginx, nginx-exporter, cadvisor, node-exporter, prometheus, alertmanager, grafana).
- `prometheus/prometheus.yml`: scrape_configs; `prometheus/rules/*.rules.yml`: recording + alert rules; `prometheus/tests/*.test.yml`: unit test.
- `alertmanager/alertmanager.yml`: route, receiver, inhibit rules.
- `grafana/provisioning/`: datasource (uid `prometheus`, `alertmanager`) và provider dashboard; `grafana/dashboards/*.json`: dashboard.
- `docs/promql-cheatsheet.md`: giải thích mọi câu PromQL đang dùng. Thêm panel/rule mới thì cập nhật file này.

## Quy ước chung

- Pin version image cụ thể, không dùng `latest`. `scripts/check.sh` lấy version promtool/amtool từ `docker-compose.yml`, nên chỉ sửa version ở đó.
- Không publish cổng `stub_status` (8082) ra host. Các cổng còn lại chỉ bind `127.0.0.1`, trừ Nginx `8080`.
- Không commit secret: mật khẩu Grafana trong `.env`, token Telegram trong `alertmanager/telegram_token` (đã gitignore).
- Tên container cố định (`container_name`) vì dashboard và alert lọc theo label `name`.
- Comment trong file config viết tiếng Anh; tài liệu (README, docs) viết tiếng Việt.
- Commit theo Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`). Không thêm trailer `Co-Authored-By` hay tham chiếu Claude vào commit; không dùng chữ "claude" trong tên branch.

Quy ước chi tiết theo từng loại file nằm trong `.claude/rules/`. Quy trình làm việc lặp lại nằm trong `.claude/skills/`.
