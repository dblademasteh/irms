FROM node:20-alpine AS build

RUN apk add --no-cache python3 make g++

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:20-alpine

RUN apk add --no-cache tini curl

RUN addgroup -S irms && adduser -S irms -G irms

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=4000
ENV PG_HOST=postgres
ENV PG_PORT=5432
ENV PG_DATABASE=irms
ENV PG_USER=irms
ENV PG_PASSWORD=irms_dev_password
ENV REDIS_HOST=redis
ENV REDIS_PORT=6379

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/migrations ./migrations
COPY --from=build /app/package.json ./

RUN mkdir -p public/uploads && chown -R irms:irms /app

USER irms

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -sf http://localhost:4000/health || exit 1

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["sh", "-c", "npm run migrate && npm start"]
