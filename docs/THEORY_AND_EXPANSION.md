# TÀI LIỆU LÝ THUYẾT, BÀI HỌC VÀ HƯỚNG MỞ RỘNG DỰ ÁN
**Dự án:** Nền tảng Phân tích Mã độc Tĩnh (Mijil Platform)

Tài liệu này tổng hợp toàn bộ các nguyên lý hoạt động, lý thuyết chuyên sâu đằng sau dự án, những bài học giá trị thu được và định hướng phát triển trong tương lai. Đây là nguồn tài liệu cực kỳ hữu ích để phục vụ cho các buổi bảo vệ đồ án, phỏng vấn hoặc báo cáo nghiên cứu.

---

## PHẦN 1: NGUYÊN LÝ HOẠT ĐỘNG VÀ LÝ THUYẾT HỆ THỐNG

Dự án là sự giao thoa hoàn hảo giữa hai lĩnh vực cực kỳ nóng hiện nay: **DevOps/Cloud-Native (Quản trị hạ tầng đám mây)** và **Cybersecurity (An toàn thông tin)**.

### 1.1. Lý thuyết Kiến trúc Cloud-Native & DevOps

*   **Nguyên lý Microservices (Dịch vụ vi mô):** Thay vì viết một cục code khổng lồ (Monolith), dự án chia làm 3 mảnh ghép độc lập: Frontend (Giao diện), Backend (Logic trung chuyển), và Malware Analyzer (Lõi phân tích). Điều này cho phép từng thành phần được bảo trì, cập nhật và mở rộng (scale) độc lập mà không ảnh hưởng đến phần còn lại.
*   **Nguyên lý Containerization (Đóng gói với Docker):** Giải quyết triệt để bài toán "chạy được trên máy tôi nhưng lỗi trên server". Mọi thư viện (YARA, Python, Nginx) đều được đóng gói cứng trong Docker. Bất kể là hệ điều hành Windows, Mac hay Linux, ứng dụng đều chạy giống hệt nhau.
*   **Nguyên lý Orchestration (Điều phối bằng Kubernetes):** Khi có hàng chục hộp Docker, bạn cần một người chỉ huy. Kubernetes (ở đây dùng bản nhẹ k3d/k3s) là bộ não: nó tự khởi động lại Pod nếu chết (Self-healing), tự động điều phối tải (Load Balancing) và quản lý bí mật (Secrets).
*   **Nguyên lý Dev/Prod Parity (Đồng nhất môi trường):** Việc sử dụng K3d + Helm ngay trên máy cá nhân giúp môi trường phát triển (Dev) giống hệt 100% môi trường thực tế (Prod). Khi triển khai lên Cloud thật, ta chỉ cần "bê" nguyên thư mục `helm-charts` lên mà không phải lo cấu hình lại.

### 1.2. Lý thuyết An toàn thông tin (Cybersecurity) - Phân tích tĩnh (Static Analysis)

Phân tích tĩnh là quá trình phân tích một tệp tin (File) mà **không cần phải chạy (thực thi)** nó. Điều này an toàn tuyệt đối và cực kỳ nhanh. Các nguyên lý cốt lõi bao gồm:

*   **Phân tích cấu trúc PE (Portable Executable):** Giống như giải phẫu cơ thể người. Mã độc viết cho Windows thường là tệp PE (.exe, .dll). Việc đọc các thẻ Header, Section (.text, .data, .rdata) và Bảng nhập (Import Table) giúp phát hiện các hàm API mờ ám (ví dụ: `VirtualAlloc`, `WriteProcessMemory` - thường dùng cho tiêm mã độc).
*   **Lý thuyết Information Entropy (Độ hỗn loạn thông tin):** Entropy đo lường mức độ ngẫu nhiên của dữ liệu (từ 0 đến 8). Tệp tin bình thường có Entropy khoảng 4-6. Nếu mã độc dùng kỹ thuật Packer (nén) hoặc Mã hóa (Encryption) để qua mặt trình diệt virus, dữ liệu của nó sẽ trở nên rất ngẫu nhiên, đẩy Entropy lên > 7.0. Đo Entropy là cách nhanh nhất để "bắt tẩy" mã độc ngụy trang.
*   **Lý thuyết Pattern Matching (So khớp mẫu với YARA):** YARA được mệnh danh là "dao bầu của giới bảo mật". Nó hoạt động như một hệ thống nhận dạng chuỗi gen. Nếu file chứa đoạn byte hoặc chuỗi văn bản khớp với "hồ sơ tội phạm" (YARA Rules), hệ thống sẽ gán mác mã độc ngay lập tức.
*   **Trích xuất IoC (Indicators of Compromise):** Tìm kiếm các địa chỉ IP, Tên miền (Domain), URLs, hoặc Registry Key giấu trong file. Đây là các "Dấu vết tội phạm", chỉ ra nơi mã độc sẽ liên lạc (C2 Server) khi nó được kích hoạt.
*   **Ánh xạ MITRE ATT&CK:** Khung lý thuyết chuẩn hóa các hành vi của Hacker toàn cầu. Việc hệ thống ánh xạ được mã độc thuộc nhóm chiến thuật nào (ví dụ: T1055 - Process Injection) giúp chuyên gia bảo mật hiểu được ý đồ của kẻ tấn công.

---

## PHẦN 2: BÀI HỌC KINH NGHIỆM ĐẠT ĐƯỢC (LESSONS LEARNED)

### 2.1. Tư duy Thiết kế (System Design)
*   **Tách biệt Concerns (Separation of Concerns):** Việc để Nginx phục vụ tĩnh cho Frontend, Node.js làm API Gateway xử lý upload, và Python lo phần lõi tính toán nặng là một mô hình lý tưởng. Python rất giỏi xử lý dữ liệu (YARA, PE), còn Node.js/Nginx làm tốt việc định tuyến.
*   **Quản lý luồng trạng thái bất đồng bộ:** Do quá trình quét tệp diễn ra lâu, việc tạo luồng (Pipeline) trạng thái phía Frontend (Hash -> Entropy -> PE -> Risk) cung cấp trải nghiệm UI/UX xuất sắc, giúp người dùng không cảm thấy ứng dụng bị "đơ".

### 2.2. Vận hành & DevOps
*   **Tách biệt Provisioning và Deployment:** Bài học sâu sắc về việc không nên trộn lẫn script dựng Cluster (K3d) với script triển khai Code (Deploy).
*   **Sức mạnh của Helm:** Thấy rõ ưu điểm của việc khai báo mọi thứ (Declarative) qua các tệp `deployment.yaml`, `service.yaml`. Khi hệ thống sập, thời gian phục hồi (RTO) gần như bằng 0 vì chỉ cần chạy lại một lệnh Helm.

### 2.3. Bảo mật & Xử lý lỗi
*   **Vô hiệu hóa Path Traversal:** File do người dùng tải lên luôn tiềm ẩn nguy hiểm. Hàm `secure_filename` tùy chỉnh xử lý unicode và xóa dấu gạch chéo là bắt buộc để ngăn tin tặc ghi đè hệ thống.
*   **Cô lập môi trường (Sandboxing cấp độ OS):** Bản thân lõi phân tích Python được nhốt vào Docker và chạy bằng non-root user (`appuser`). Dù hacker có tải lên mã khai thác Zero-day, chúng cũng chỉ có thể quậy phá trong 1 hộp container kín, không ảnh hưởng đến máy chủ vật lý.

---

## PHẦN 3: HƯỚNG MỞ RỘNG VÀ PHÁT TRIỂN (FUTURE EXPANSIONS)

Nếu dự án này được tiếp tục phát triển (ví dụ làm Đồ án tốt nghiệp hoặc đưa ra kinh doanh), dưới đây là lộ trình các tính năng "sát thủ":

### 3.1. Phân tích Động (Dynamic Analysis / Sandboxing)
*   **Nguyên lý:** Hiện tại hệ thống chỉ đọc code (Static). Hướng đi tiếp theo là thực sự "bấm đúp" để chạy mã độc trong môi trường máy ảo an toàn (Cuckoo Sandbox hoặc QEMU/KVM).
*   **Thu được:** Xem mã độc tạo ra file gì, đổi Registry ra sao, gọi ra ngoài Internet bằng IP nào. Kết hợp Tĩnh (Static) + Động (Dynamic) tạo ra một hệ thống hoàn hảo.

### 3.2. Áp dụng Trí tuệ nhân tạo (AI/Machine Learning)
*   **Bài toán:** Kẻ tấn công liên tục đổi code để lách YARA và Hash. YARA dựa trên quy tắc (Rule-based) sẽ dần lỗi thời.
*   **Giải pháp:** Đưa file đã trích xuất PE và Entropy vào một mô hình Học Máy (Random Forest hoặc Deep Neural Network). AI sẽ tự học các mẫu hình nguy hiểm mà mắt người không thấy, nâng tỷ lệ phát hiện các biến thể mã độc mới (Zero-day) lên cao hơn.

### 3.3. Xây dựng Kho dữ liệu (Data Persistence & Threat Intelligence)
*   **Hiện tại:** Tệp tin phân tích xong bị xóa (Vô trạng thái - Stateless).
*   **Tương lai:** Triển khai **PostgreSQL** để lưu trữ lịch sử phân tích, và **MinIO/S3** để lưu trữ tệp độc hại.
*   **Lợi ích:** Xây dựng một bách khoa toàn thư nội bộ về mã độc. Có thể tìm kiếm lại lịch sử, so sánh mã độc tải lên tuần này với tuần trước xem có phải cùng một nhóm Hacker hay không.

### 3.4. Hệ thống CI/CD Hoàn Chỉnh
*   Đưa lên GitHub Actions. Mỗi khi Dev push code mới, GitHub tự động chạy test, tự động Build Image, quét bảo mật trên Image đó (bằng Trivy), và dùng ArgoCD để tự động đồng bộ (pull) cấu hình mới về K8s mà không cần người dùng phải bấm lệnh deploy thủ công.

### 3.5. Nhận diện Thông minh trên Giao diện (RAG / AI Chatbot)
*   Nhúng một mô hình LLM trực tiếp vào Frontend. Người dùng không rành kỹ thuật thay vì phải đọc đống thông số (Entropy, Machine Code) khô khan, có thể hỏi trực tiếp: *"Chatbot, tóm tắt cho tôi biết vì sao file này nguy hiểm bằng ngôn ngữ dễ hiểu?"* - Hệ thống sẽ đọc JSON report và trả lời như chuyên gia.

---

**Kết luận:** Nền tảng Mijil Analyzer hiện tại là một "Viên ngọc thô" có nền móng kiến trúc Microservices xuất sắc, vững chắc. Nắm vững lý thuyết và bộ khung này sẽ giúp đội ngũ tự tin chinh phục các nấc thang hệ thống quy mô lớn trong tương lai!
