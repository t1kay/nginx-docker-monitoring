---
paths:
  - "docker-compose.yml"
  - "nginx/**"
  - "scripts/**"
  - ".github/**"
---

# Quy ước Docker Compose, Nginx và scripts

## docker-compose.yml
- Pin version image cụ thể (`prom/prometheus:v3.15.0`), không dùng `latest` hay tag chỉ có major.
- Đặt `container_name` cho mọi service: cAdvisor đưa tên này vào label `name`, dashboard và alert lọc theo nó.
- Service có shell/wget thì thêm `healthcheck`; service phụ thuộc dùng `depends_on: condition: service_healthy`.
- Cổng của công cụ giám sát chỉ bind `127.0.0.1:` ; chỉ Nginx publish ra mọi interface.
- Config mount dạng `:ro`. Dữ liệu (Prometheus TSDB, Grafana, Alertmanager) dùng named volume.
- Biến nhạy cảm đọc từ `.env` với giá trị mặc định cho lab: `${GRAFANA_ADMIN_PASSWORD:-admin}`. Cập nhật `.env.example` khi thêm biến.
- Đổi version image Prometheus/Alertmanager xong thì chạy `./scripts/check.sh` (promtool/amtool lấy đúng version đó).

## Nginx
- `stub_status` chỉ nằm ở server nội bộ cổng 8082, không publish cổng này.
- Thêm location mới để demo (ví dụ `/error`) thì ghi chú mục đích ngay trong `nginx.conf`.

## Scripts
- Bash có `set -euo pipefail`, chạy được từ bất kỳ thư mục nào (`cd "$(dirname "$0")/.."`).
- Tham số cấu hình qua biến môi trường có giá trị mặc định, ghi cách dùng ở đầu file.
- Không yêu cầu cài tool lên host nếu chạy được bằng `docker run`.

## CI
- `.github/workflows/ci.yml` phải gọi lại `scripts/check.sh`, không lặp lại logic kiểm tra ở hai nơi.
