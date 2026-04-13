FROM node:20-alpine
WORKDIR /app

# Copy root package.json and lock
COPY package.json package-lock.json ./

# Copy all package.jsons to satisfy the workspace lockfile
COPY packages/shared/package.json ./packages/shared/package.json
COPY services/profile/package.json ./services/profile/package.json
COPY services/payment/package.json ./services/payment/package.json
COPY services/gateway/package.json ./services/gateway/package.json
COPY services/auth/package.json ./services/auth/package.json
COPY services/notification/package.json ./services/notification/package.json
COPY services/storage/package.json ./services/storage/package.json

# Install dependencies
RUN npm install --omit=dev

# Copy source code
COPY packages/shared ./packages/shared
COPY services/profile ./services/profile

# Set workdir to the service
WORKDIR /app/services/profile

EXPOSE 3002
CMD ["npm", "start"]
