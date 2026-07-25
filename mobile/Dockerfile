FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN flutter gen-l10n
RUN flutter build web --release --dart-define=FLUTTER_WEB_AUTO_DETECT=false

FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

RUN sed -i 's/<head>/<head>\n    <base href="\/">/' /usr/share/nginx/html/index.html

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
