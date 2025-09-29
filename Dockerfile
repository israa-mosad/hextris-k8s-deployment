FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN if [ -f package.json ]; then npm ci --silent || true; fi
COPY . .
RUN if [ -f package.json ] && grep -q "\"build\"" package.json; then \
      npm run build --silent; \
      mkdir -p /app/dist && cp -r ./dist/* /app/dist/ || true; \
    else \
      mkdir -p /app/dist && cp -r . /app/dist/ ; \
    fi

FROM nginx:stable-alpine
COPY --chown=nginx:nginx --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
