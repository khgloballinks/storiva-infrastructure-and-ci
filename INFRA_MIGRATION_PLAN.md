# Infrastructure Migration Plan: Split Staging and Production

This document outlines the step-by-step plan to update the environment based on your requirements:
1. Separating the staging and production environments into their own EC2 instances.
2. Managing the `docker-compose` files locally and in CI/CD.
3. Updating Terraform to automatically install Docker, Nginx, and Certbot.

## Phase 0: Prerequisites & Domain Confirmation
Before applying terraform changes or updating the CI/CD pipeline, we must explicitly confirm the domains and ensure the hosted zone or DNS manager is correctly configured.
- The actual domain is `storivainc.com`. Note: Since Cloudflare IPs were detected for the apex domain, DNS may be managed in Cloudflare.
- Update `variables.tf` domain to `storivainc.com` if it's currently hardcoded or using something else.
- Confirm the subdomains required: `staging.storivainc.com` and `api.storivainc.com` map to the respective Elastic IPs either via AWS Route53 (if it manages the zone) or via Cloudflare.

## Phase 1: Docker Compose Reorganization

We will organize the local `docker/` folder so it properly defines each environment's services.
- **Local Dev:** `docker/docker-compose.dev.yml` remains locally for development.
- **Staging:** Ensure `docker/docker-compose.staging.yml` is prepared. This file will be responsible for defining services running on the `staging` EC2 instance (`staging.storivainc.com`).
- **Production:** Ensure `docker/docker-compose.prod.yml` is prepared. This file will be responsible for defining services running on the `production` EC2 instance (`api.storivainc.com`).

## Phase 2: Terraform Updates (`infra/terraform/main.tf`)

Currently, Terraform is spinning up a single instance (`storiva_server`). We will modify this to deploy two distinct instances.

### 1. Split EC2 Instances & Elastic IPs
- Create `aws_instance.prod_server` for Production.
- Create `aws_instance.staging_server` for Staging.
- Create two Elastic IPs: `aws_eip.prod_eip` and `aws_eip.staging_eip`.

### 2. Domain Name Verification and Update DNS Records
- **Verify Target Domain:** Confirm the exact domain `storivainc.com`. If DNS is in Cloudflare, make sure to add/update A records in Cloudflare pointing to the new Elastic IPs, or via Route53 if delegated.
- Map `staging.storivainc.com` -> `aws_eip.staging_eip`.
- Map `api.storivainc.com` -> `aws_eip.prod_eip` (and ensure variables handle this subdomain appropriately).

### 3. Update the Provisioning Script (`user_data`)
We will rewrite the `user_data` bash script on both EC2 instances to automate the complete setup:
- **Docker:** Continue installing Docker and `docker-compose-plugin` (as it currently does).
- **NGINX:** Add `apt-get install -y nginx` to install the Nginx web server.
- **Certbot:** Add `apt-get install -y certbot python3-certbot-nginx` for SSL generation.
- **NGINX Configuration:** Pre-inject a basic NGINX reverse proxy configuration file that proxies requests from port 80/443 directly to the Docker containers (e.g. running on port 8080 or 3000 locally on the server).

**Example User Data Addition:**
```bash
# Install NGINX and Certbot
apt-get install -y nginx certbot python3-certbot-nginx

# Create default NGINX configuration
cat << 'EOF' > /etc/nginx/sites-available/api
server {
    listen 80;
    server_name api.storivainc.com; # (or staging.storivainc.com depending on the instance)
    
    location / {
        proxy_pass http://localhost:8080; # Assuming API container runs on 8080
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -s /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
systemctl restart nginx
```
*(Note: Actual Certbot SSL certificate generation requires the DNS to propagate first, so `certbot --nginx -d api.storivainc.com --non-interactive --agree-tos -m admin@storivainc.com` can be run post-deployment or triggered via CI/CD).*

### 4. Adjust Security Groups
- Ensure `aws_security_group.storiva_sg` permits traffic on Ports 80 (HTTP) and 443 (HTTPS) for the public so Certbot and the API can serve traffic. 

## Phase 3: CI/CD Workflows (`.github/workflows`)

Once Terraform applies these changes, we need to adjust the Github actions to deploy to the correct targets:
- `.github/workflows/deploy-staging.yml` will deploy `docker-compose.staging.yml` to the `staging` EC2 IP.
- `.github/workflows/deploy-prod.yml` will deploy `docker-compose.prod.yml` to the `production` EC2 IP.

---
### Next Steps
If you approve this plan, we can switch from Plan Mode to normal mode and start implementing these terraform and docker configuration changes!