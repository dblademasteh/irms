FROM node:20-alpine AS build

RUN apk add --no-cache python3 make g++

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .

FROM node:20-alpine

RUN apk add --no-cache tini

RUN addgroup -S irms && adduser -S irms -G irms

WORKDIR /app

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/src ./src
COPY --from=build /app/migrations ./migrations
COPY --from=build /app/package.json ./

RUN mkdir -p public/uploads && chown -R irms:irms /app

USER irms

EXPOSE 4000

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["sh", "-c", "npm run migrate && npm start"]
