#!/bin/bash
set -euo pipefail

# ✅ Log everything for debugging
exec > >(tee /var/log/user-data.log) 2>&1
echo "=== user_data started at $(date) ==="

apt-get update -y
apt-get install -y nginx curl

# Docker install
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu || true

# ✅ Remove default nginx site to avoid conflicts
rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/app <<'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass         http://localhost:8000;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://localhost:8000/health;
        access_log off;
    }
}
EOF

# ✅ Use -sf (force) to avoid error if symlink exists
ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/

# ✅ Test config before restarting
nginx -t && systemctl restart nginx

echo "=== user_data complete at $(date) ==="