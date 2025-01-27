FROM node:20-alpine as builder

WORKDIR /app

COPY package*.json .

RUN npm install

FROM node:20-alpine as development

WORKDIR /app

COPY . .
COPY --from=builder /app/node_modules /app/node_modules

EXPOSE 3000

CMD ["npm", "run", "dev"]

FROM node:20-alpine as builder-production

WORKDIR /app

COPY --from=development /app/node_modules /app/node_modules

COPY . .

# RUN npm run build

FROM caddy:2.9.1-alpine as production

WORKDIR /usr/share/caddy

RUN apk add --no-cache acl

RUN addgroup -g 1001 caddygroup && \
    adduser -u 1001 -G caddygroup -s /bin/sh -D caddyuser

# COPY --from=builder-production /app/out .

RUN chown -R caddyuser:caddygroup /usr/share/caddy && \
    chown -R caddyuser:caddygroup /data

USER caddyuser

COPY caddy/Caddyfile /etc/caddy/Caddyfile

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]