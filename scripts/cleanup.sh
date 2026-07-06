#!/bin/bash

# ==============================================================================
# Script Dọn Dẹp Môi Trường Docker & K3d
# ==============================================================================

echo "================================================================="
echo "BẮT ĐẦU DỌN DẸP DỮ LIỆU RÁC CỦA DOCKER VÀ KUBERNETES..."
echo "================================================================="
echo ""
echo "Cảnh báo: Quá trình này sẽ xóa toàn bộ:"
echo "  - Các container đang tắt"
echo "  - Các network không được sử dụng"
echo "  - Tất cả các images (kể cả k3d/k3s) không có container nào đang chạy"
echo "  - Tất cả các volumes không được gắn vào container nào"
echo ""

# Thêm 3 giây để người dùng có thể huỷ (Ctrl+C) nếu chạy nhầm
sleep 3

# Dọn dẹp toàn diện Docker
echo "[1/2] Đang chạy lệnh docker system prune..."
docker system prune -a --volumes -f

echo ""
echo "[2/2] Hoàn tất dọn dẹp hệ thống!"
echo ""
