# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN if [ -f package.json ]; then npm ci --silent || true; fi

# Copy app source
COPY . .

# Build the app if "build" script exists
RUN if [ -f package.json ] && grep -q "\"build\"" package.json; then \
      npm run build --silent; \
    fi

# Stage 2: Final image
FROM nginx:stable-alpine
# Copy only the build output (dist) from the builder stage
COPY --chown=nginx:nginx --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
