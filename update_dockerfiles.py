import os
import glob

services = {
    'auth': 3001,
    'gateway': 3000,
    'notification': 3004,
    'payment': 3003,
    'profile': 3002,
    'storage': 3005
}

for service, port in services.items():
    dockerfile_path = f"services/{service}/Dockerfile"
    with open(dockerfile_path, "w") as f:
        f.write(f"""FROM node:20-alpine
WORKDIR /app

# Copy root package.json and lock
COPY package.json package-lock.json ./

# Copy package.jsons for workspaces
COPY packages/shared/package.json ./packages/shared/
COPY services/{service}/package.json ./services/{service}/

# Install dependencies (workspaces will link automatically)
RUN npm install --workspace=services/{service} --omit=dev

# Copy source code
COPY packages/shared ./packages/shared
COPY services/{service} ./services/{service}

# Set workdir to the service
WORKDIR /app/services/{service}

EXPOSE {port}
CMD ["npm", "start"]
""")

print("Dockerfiles updated.")
