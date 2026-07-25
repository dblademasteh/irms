FROM nginx:alpine

# Cache bust trigger v3: fresh web-dist COPY
COPY web-dist /usr/share/nginx/html

RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        add_header Cache-Control "no-cache, no-store, must-revalidate"; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
