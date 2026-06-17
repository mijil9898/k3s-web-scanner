FROM nginx:1.25-alpine

# Xóa sạch cấu hình mặc định của Nginx để tránh xung đột
RUN rm -rf /etc/nginx/conf.d/*

# Copy file tùy chỉnh của chúng ta vào
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
