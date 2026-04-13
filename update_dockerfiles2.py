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

# Find all package.jsons
all_packages = glob.glob("packages/*/package.json") + glob.glob("services/*/package.json")

for service, port in services.items():
    dockerfile_path = f"services/{service}/Dockerfile"
    with open(dockerfile_path, "w") as f:
        f.write(f"""FROM node:20-alpine
WORKDIR /app

# Copy root package.json and lock
COPY package.json package-lock.json ./

# Copy all package.jsons to satisfy the workspace lockfile
""")
        for pkg in all_packages:
            f.write(f"COPY {pkg} ./{pkg}\n")
            
        f.write(f"""
# Install dependencies
RUN npm ci --omit=dev

# Copy source code
COPY packages/shared ./packages/shared
COPY services/{service} ./services/{service}

# Set workdir to the service
WORKDIR /app/services/{service}

EXPOSE {port}
CMD ["npm", "start"]
""")

print("Dockerfiles updated.")
