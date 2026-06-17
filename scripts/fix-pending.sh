#!/bin/bash
echo "=================================================="
echo "SCRIPT TỰ ĐỘNG KHẮC PHỤC LỖI POD PENDING / UNKNOWN"
echo "=================================================="

# 1. Xử lý chuyên biệt cho StatefulSet Database (postgres-0)
# Nguyên nhân: Volume Node Affinity Conflict khiến Pod không thể schedule trên Node mới.
# Giải pháp: Xóa PVC để StatefulSet tự động provision PVC mới trên Node khả dụng.
POSTGRES_POD_STATUS=$(kubectl get pod postgres-0 -n portfolio -o jsonpath='{.status.phase}' 2>/dev/null)
if [[ "$POSTGRES_POD_STATUS" == "Pending" || "$POSTGRES_POD_STATUS" == "Unknown" ]]; then
    echo "🔧 Phát hiện postgres-0 bị $POSTGRES_POD_STATUS. Đang xử lý Volume Lock..."
    kubectl delete pod postgres-0 -n portfolio --force --grace-period=0 >/dev/null 2>&1
    kubectl delete pvc postgres-data-postgres-0 -n portfolio >/dev/null 2>&1
    echo "✅ Đã xóa Pod và PVC của postgres-0. StatefulSet sẽ tự động tạo lại."
fi

# 2. Quét và xử lý các Pod lỗi khác trên toàn Cluster
echo "🔍 Đang quét các Pod bị lỗi (Pending / Unknown)..."
ERROR_PODS=$(kubectl get pods -A --no-headers | grep -E 'Pending|Unknown' | awk '{print $1":"$2}')

if [ -z "$ERROR_PODS" ]; then
    echo "✅ Không có Pod nào bị lỗi."
else
    echo "⚠️ Đang xử lý các Pod lỗi:"
    echo "$ERROR_PODS" | tr ':' '\t'
    
    # Khởi động lại Local Path Provisioner để làm mới trạng thái volume
    kubectl rollout restart deployment local-path-provisioner -n kube-system >/dev/null 2>&1
    
    # Force Delete các Pod lỗi
    for p in $ERROR_PODS; do
        ns=$(echo $p | cut -d: -f1)
        name=$(echo $p | cut -d: -f2)
        kubectl delete pod $name -n $ns --force --grace-period=0 >/dev/null 2>&1
    done
fi

# 3. Xử lý PVC bị kẹt ở trạng thái Terminating
STUCK_PVCS=$(kubectl get pvc -A --no-headers | grep Terminating | awk '{print $1":"$2}')
if [ ! -z "$STUCK_PVCS" ]; then
    echo "🔧 Đang xóa Finalizer cho PVC bị kẹt..."
    for pvc in $STUCK_PVCS; do
        ns=$(echo $pvc | cut -d: -f1)
        name=$(echo $pvc | cut -d: -f2)
        kubectl patch pvc $name -n $ns --type json -p='[{"op": "remove", "path":"/metadata/finalizers"}]' >/dev/null 2>&1
    done
fi

echo "⏳ Đang chờ Kubernetes cấp phát lại tài nguyên (15 giây)..."
sleep 15

echo "📊 Kết quả:"
kubectl get pods -n portfolio
echo ""
kubectl get pods -A --no-headers | grep -E 'Pending|Unknown' || echo "✅ Đã xử lý xong các lỗi Pending/Unknown trên toàn Cluster."
echo "=================================================="
