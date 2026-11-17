---
paths:
  - "prometheus/**"
  - "alertmanager/**"
---

# Quy ước Prometheus & Alertmanager

## Scrape config
- Mỗi exporter một `job_name` riêng, đặt theo tên thành phần (`nginx`, `cadvisor`, `node`...). Đổi `job_name` sẽ làm hỏng dashboard và alert đang lọc theo `job`.
- Target dùng tên service trong compose (`nginx-exporter:9113`), không dùng `localhost` (trừ job `prometheus` tự scrape chính nó).
- Metric không dùng tới và có nhiều series thì drop bằng `metric_relabel_configs`, không để tràn TSDB.

## Recording rules (`prometheus/rules/recording.rules.yml`)
- Tên theo quy ước `level:metric:operations`, ví dụ `name:container_cpu_usage:percent`.
- Counter luôn đi qua `rate()`/`increase()` trước khi `sum`: viết `sum(rate(x[1m]))`, không viết `rate(sum(x)[1m])`.
- Khoảng thời gian trong `rate()` ít nhất bằng 4 lần `scrape_interval` của job đó.
- Nếu dashboard và alert cùng dùng một biểu thức, đưa nó vào recording rule và dùng chung.

## Alert rules (`prometheus/rules/alerts.rules.yml`)
Mỗi alert BẮT BUỘC có:
- `for:` (không để alert bắn ngay từ một lần đo).
- label `severity`: `critical` (cần xử lý ngay) hoặc `warning`.
- annotation `summary` (một dòng) và `description` (có `{{ $labels.* }}` / `{{ $value }}` để biết bị gì, ở đâu).
- ít nhất một test case trong `prometheus/tests/alerts.test.yml`: cả trường hợp bắn và trường hợp chưa bắn (trước khi hết `for`).

Ngưỡng phải giải thích được; nếu chọn ngưỡng thấp để dễ demo, ghi rõ trong `description` hoặc README.

## Alertmanager
- Không ghi token/password trực tiếp trong `alertmanager.yml`: dùng `*_file` trỏ tới file đã gitignore.
- Thêm inhibit rule khi một alert là hệ quả của alert khác (ví dụ `NginxDown` chặn `NginxHighConnections`).

## Kiểm tra
Sau mọi thay đổi trong `prometheus/` hoặc `alertmanager/`, chạy `./scripts/check.sh` và phải pass trước khi commit.
