---
paths:
  - "grafana/**"
---

# Quy ước Grafana

- Mọi dashboard là file JSON trong `grafana/dashboards/`, được nạp qua provisioning. Không có dashboard nào chỉ tồn tại trên UI.
- Provider đặt `allowUiUpdates: false`: sửa trên UI sẽ không lưu được. Muốn sửa bằng UI thì làm bản sao, chỉnh xong **Export → JSON** rồi ghi đè file trong repo.
- Mỗi dashboard có `uid` cố định, viết thường, dạng kebab-case (`nginx-overview`). Đổi `uid` sẽ làm hỏng link và CI.
- Datasource trong panel và target luôn tham chiếu theo uid: `{"type": "prometheus", "uid": "prometheus"}`. Không dùng tên hiển thị hay `${DS_...}`.
- Đặt `unit` cho mọi panel (`reqps`, `percent`, `bytes`, `Bps`...). `percent` cho giá trị 0–100, `percentunit` cho tỉ lệ 0–1.
- Panel có nhiều series dùng `legendFormat` (`{{name}}`), không để legend hiện cả chuỗi label.
- Ưu tiên dùng recording rule có sẵn thay vì viết lại PromQL dài trong panel.
- Viết `description` cho panel khi PromQL không hiển nhiên (vì sao dùng `rate`, ý nghĩa ngưỡng).
- Thêm panel mới thì cập nhật bảng PromQL trong `docs/promql-cheatsheet.md`.
- JSON phải hợp lệ và có `uid`: `./scripts/check.sh` kiểm tra điều này.
