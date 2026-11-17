# PromQL cheatsheet

Ghi chú các khái niệm cơ bản và mọi câu PromQL dùng trong dự án. Thử từng câu ở http://localhost:9090/graph.

## 1. Bốn loại metric

| Loại | Đặc điểm | Ví dụ trong lab | Cách dùng đúng |
|---|---|---|---|
| **Counter** | Chỉ tăng (về 0 khi process khởi động lại). Tên thường kết thúc `_total` | `nginx_http_requests_total`, `container_cpu_usage_seconds_total` | Luôn bọc trong `rate()` / `increase()`; giá trị thô gần như vô nghĩa |
| **Gauge** | Lên xuống tự do, là giá trị tại thời điểm đo | `nginx_connections_active`, `container_memory_working_set_bytes`, `nginx_up` | Dùng trực tiếp, hoặc `avg_over_time()`, `max_over_time()` |
| **Histogram** | Đếm số quan sát rơi vào từng bucket (`_bucket`, `_sum`, `_count`) | `prometheus_http_request_duration_seconds_bucket` | `histogram_quantile(0.95, sum by (le) (rate(..._bucket[5m])))` |
| **Summary** | Quantile tính sẵn ở phía client | `go_gc_duration_seconds` | Đọc trực tiếp, **không** cộng gộp được giữa các instance |

## 2. Hàm hay dùng

```promql
# Tốc độ tăng mỗi giây, trung bình trong 1 phút (dùng cho counter)
rate(nginx_http_requests_total[1m])

# Tổng số tăng trong khoảng thời gian (counter) -> "có bao nhiêu request trong 1 giờ"
increase(nginx_http_requests_total[1h])

# Gộp nhiều series thành một, giữ lại label `name`
sum by (name) (rate(container_cpu_usage_seconds_total{name!=""}[1m]))

# Giá trị lớn nhất của gauge trong 10 phút
max_over_time(nginx_connections_active[10m])

# Top 3 container ăn RAM nhiều nhất
topk(3, name:container_memory_working_set:bytes)
```

**Chọn khoảng `[1m]` thế nào?** Tối thiểu khoảng 4 lần `scrape_interval` (ở đây 15s → `[1m]`), để luôn có đủ điểm dữ liệu.

**Label matcher:** `=` bằng, `!=` khác, `=~` khớp regex, `!~` không khớp regex.
`{name!=""}` bỏ đi các series của cgroup hệ thống (không phải container).

## 3. Câu PromQL trong dashboard

### Nginx Overview

| Panel | PromQL | Ghi chú |
|---|---|---|
| Nginx status | `nginx_up` | Gauge 0/1, map thành DOWN/UP |
| Requests / s | `sum(rate(nginx_http_requests_total[1m]))` | Counter → `rate` |
| Active connections | `sum(nginx_connections_active)` | Gauge |
| Total requests | `sum(increase(nginx_http_requests_total[$__range]))` | `$__range` = khoảng thời gian đang chọn trên Grafana |
| Connections by state | `nginx_connections_reading` / `writing` / `waiting` | `waiting` = keep-alive đang rảnh |
| Accepted vs handled | `rate(nginx_connections_accepted[1m])`, `rate(nginx_connections_handled[1m])` | Hai đường lệch nhau nghĩa là Nginx đang từ chối kết nối |
| Nginx container CPU | `name:container_cpu_usage:percent{name="nginx"}` | Dùng recording rule |

### Docker Containers

| Panel | PromQL |
|---|---|
| Running containers | `count(time() - container_last_seen{name=~".+"} < 60)` |
| CPU by container | `name:container_cpu_usage:percent{name=~"$container"}` |
| Memory by container | `name:container_memory_working_set:bytes{name=~"$container"}` |
| Network receive | `sum by (name) (rate(container_network_receive_bytes_total{name=~"$container"}[1m]))` |
| Memory vs limit | `name:container_memory_usage:ratio{name=~"$container"}` |
| Firing alerts | `count(ALERTS{alertstate="firing"}) or vector(0)` |

`$container` là biến của dashboard (lấy bằng `label_values(container_last_seen{name!=""}, name)`).
`or vector(0)` giúp panel hiện `0` thay vì *No data* khi không có alert nào.

## 4. Recording rules

Recording rule chạy một câu PromQL theo chu kỳ và lưu kết quả thành metric mới, nên:
- Dashboard và alert đọc nhanh hơn (không phải tính lại mỗi lần).
- Một định nghĩa dùng chung cho cả dashboard và alert, tránh hai nơi viết lệch nhau.

Quy ước tên: `level:metric:operations`, ví dụ `name:container_cpu_usage:percent` = gộp theo label `name`, metric gốc `container_cpu_usage`, phép tính ra phần trăm.

## 5. Alert: vòng đời

```
Inactive --(biểu thức đúng)--> Pending --(vẫn đúng sau `for`)--> Firing --> Alertmanager
```

`for:` chống báo động giả do một lần đo đột biến. Alertmanager mới là nơi **gom nhóm**, **chặn trùng** (inhibit)
và **gửi** thông báo; Prometheus chỉ đánh giá điều kiện.

## Giới hạn của stub_status

`stub_status` chỉ cho biết **tổng** số request và số kết nối, không chia theo mã trạng thái (2xx/5xx), URL hay độ trễ.
Vì vậy chạy `ERRORS=1 ./scripts/load-test.sh` (gọi `/error`, luôn trả 500) thì `Requests / s` vẫn tăng
nhưng **không có cách nào** phân biệt đó là lỗi. Muốn có error rate và latency, cần:
- đọc access log (ví dụ [nginxlog-exporter](https://github.com/martin-helmich/prometheus-nginxlog-exporter) hoặc Loki), hoặc
- dùng module VTS / NGINX Plus, hoặc
- tự gắn metric trong ứng dụng phía sau Nginx (Counter + Histogram), là bước tiếp theo nên học.
