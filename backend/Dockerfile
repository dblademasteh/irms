FROM node:20-alpine AS build

RUN apk add --no-cache python3 make g++

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .

FROM node:20-alpine

RUN apk add --no-cache tini curl

RUN addgroup -S irms && adduser -S irms -G irms

WORKDIR /app

ENV PG_HOST=o12udbauba2yuuxjdyfhnl3x
ENV PG_PORT=5432
ENV PG_DATABASE=postgres
ENV PG_USER=postgres
ENV REDIS_HOST=upqpm50jdf1f6itk8atdaay9
ENV REDIS_PORT=6379

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/src ./src
COPY --from=build /app/migrations ./migrations
COPY --from=build /app/package.json ./

RUN mkdir -p public/uploads && chown -R irms:irms /app

USER irms

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -sf http://localhost:4000/health || exit 1

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["sh", "-c", "npm run migrate && npm start"]
