# Storiva Backend API - Infrastructure & CI/CD Documentation

> **Last Updated:** April 2026

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Infrastructure Setup](#infrastructure-setup)
3. [Microservices](#microservices)
4. [CI/CD Pipeline](#cicd-pipeline)
5. [Environment Configuration](#environment-configuration)
6. [Deployment Guide](#deployment-guide)
7. [DNS & SSL Setup](#dns--ssl-setup)
8. [Troubleshooting](#troubleshooting)
9. [Roadmap](#roadmap)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AWS CLOUD                                         │
│                                                                              │
│  ┌──────────────────────────────┐     ┌──────────────────────────────┐      │
│  │      STAGING SERVER          │     │       PRODUCTION SERVER      │      │
│  │      (EC2 - t3.micro)       │     │       (EC2 - t3.micro)       │      │
│  │                              │     │                              │      │
│  │  ┌────────────────────┐    │     │  ┌────────────────────┐     │      │
│  │  │  Host Nginx :8080  │    │     │  │  Host Nginx :8080 │     │      │
│  │  └─────────┬──────────┘    │     │  │  └─────────┬────────┘     │      │
│  │            │               │     │  │            │              │      │
│  │            ▼               │     │  │            ▼              │      │
│  │  ┌────────────────────┐    │     │  │  ┌────────────────┐    │      │
│  │  │   Docker Nginx     │    │     │  │  │  Docker Nginx  │    │      │
│  │  │      :8080         │    │     │  │  │     :8080      │    │      │
│  │  └─────────┬──────────┘    │     │  │  └────────┬────────┘    │      │
│  │            │               │     │  │           │              │      │
│  │            ▼               │     │  │           ▼              │      │
│  │  ┌────────────────────┐    │     │  │  ┌────────────────┐    │      │
│  │  │     Gateway        │    │     │  │  │    Gateway     │    │      │
│  │  │   (Port 3000)     │    │     │  │  │  (Port 3000)  │    │      │
│  │  └─────────┬──────────┘    │     │  │  └───────┬────────┘    │      │
│  │            │               │     │  │          │             │      │
│  │            ▼               │     │  │          ▼             │      │
│  │  ┌────────────────────┐    │     │  │  ┌────────────────┐  │      │
│  │  │  Auth | Profile    │    │     │  │  │ Auth | Profile  │ │      │
│  │  │  Payment | Notif   │    │     │  │  │Payment| Notif   │ │      │
│  │  │  Storage          │    │     │  │  │ Storage        │ │      │
│  │  └─────────┬──────────┘    │     │  │  └───────┬────────┘  │      │
│  │            │               │     │  │          │           │      │
│  │            ▼               │     │  │          ▼           │      │
│  │  ┌────────────────────┐    │     │  │  ┌────────────────┐ │      │
│  │  │  PostgreSQL        │    │     │  │  │ AWS RDS        │ │      │
│  │  │  (Local Docker)   │    │     │  │  │ PostgreSQL    │  │      │
│  │  └────────────────────┘    │     │  │  └────────────────┘ │      │
│  └──────────────────────────────┘     │  └────────────────────┘      │
│                                        │                              │
│  Route53: staging.storivainc.com       │  Route53: api.storivainc.com │      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Infrastructure Setup

### AWS Resources

| Resource | Type | Staging | Production |
|----------|------|---------|------------|
| **EC2 Instance** | t3.micro | ✅ | ✅ |
| **Elastic IP** | EIP | ✅ | ✅ |
| **Security Group** | SG | Shared | Shared |
| **RDS PostgreSQL** | db.t3.micro | ❌ (Local) | ✅ |
| **Route53** | Hosted Zone | ✅ | ✅ |

### EC2 Specifications

```yaml
Staging Server:
  Instance Type: t3.micro
  Volume: 30GB gp3
  OS: Ubuntu 22.04 LTS
  Ports: 22 (SSH), 80 (HTTP), 8080 (App)

Production Server:
  Instance Type: t3.micro
  Volume: 50GB gp3
  OS: Ubuntu 22.04 LTS
  Ports: 22 (SSH), 80 (HTTP), 8080 (App)
```

### Terraform Structure

```
infra/
├── terraform/
│   ├── main.tf          # EC2, EIP, RDS, Route53
│   ├── variables.tf     # Input variables
│   ├── outputs.tf       # Output values
│   └── terraform.tfvars # Variable values
└── scripts/
    └── deploy.sh        # Manual deployment script
```

### SSH Access

```bash
# Staging
ssh -i ~/.ssh/your-key.pem ubuntu@<STAGING_EIP>

# Production
ssh -i ~/.ssh/your-key.pem ubuntu@<PROD_EIP>
```

---

## Microservices

### Service Architecture

| Service | Port | Purpose | Protected |
|---------|------|---------|-----------|
| **Gateway** | 3000 | API Gateway / Proxy | No |
| **Auth** | 3001 | User authentication | No |
| **Profile** | 3002 | User profiles | Yes |
| **Payment** | 3003 | Payment processing | Yes |
| **Notification** | 3004 | Email/SMS notifications | Yes |
| **Storage** | 3005 | File storage | Yes |

### Services Structure

```
services/
├── gateway/          # API Gateway (Express.js)
├── auth/             # Authentication service
├── profile/          # User profile service
├── payment/          # Payment processing
├── notification/     # Notification service
└── storage/          # Storage service

packages/
└── shared/           # Shared Prisma client & utilities
```

### Database Schema

```prisma
// packages/shared/prisma/schema.prisma

model User {
  id        String   @id @default(uuid())
  email     String   @unique
  password  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

---

## CI/CD Pipeline

### GitHub Actions Workflows

```
.github/workflows/
├── ci.yml              # Build & push Docker images
├── deploy-staging.yml  # Deploy to staging server
└── deploy-prod.yml     # Deploy to production server
```

### CI Workflow (`ci.yml`)

**Triggers:**
- Push to `staging` or `main` branches
- Changes to: `services/**`, `packages/shared/**`, `docker/**`
- Manual trigger (`workflow_dispatch`)

**Process:**
1. Detect changed services (using paths-filter)
2. Install dependencies (`npm ci`)
3. Generate Prisma client
4. Run tests (`npm test --if-present`)
5. Build Docker images (per service)
6. Push to Docker Hub with tags:
   - `staging` or `latest`
   - Git commit SHA

**Build Matrix:**
```yaml
services:
  - gateway
  - auth
  - profile
  - payment
  - notification
  - storage
```

### Deploy Staging Workflow

**Trigger:** CI workflow completes on `staging` branch

**Process:**
1. SSH into staging server
2. Pull latest code from `staging` branch
3. Create environment file with secrets
4. Login to Docker Hub
5. Pull latest images
6. Start services with `docker compose`
7. Reload host nginx
8. Health check validation
9. Cleanup

### Deploy Production Workflow

**Trigger:** CI workflow completes on `main` branch

**Process:**
1. SSH into production server
2. Pull latest code from `main` branch
3. Create environment file with secrets
4. Save current image state (for rollback)
5. Rolling restart (one service at a time)
6. Reload host nginx
7. Health check validation
8. Cleanup

---

## Environment Configuration

### Docker Compose Files

```
docker/
├── docker-compose.staging.yml  # Staging environment
├── docker-compose.prod.yml     # Production environment
└── nginx/
    ├── staging.conf           # Staging nginx config
    ├── internal.conf          # Internal docker nginx
    └── prod.conf             # Production nginx config
```

### GitHub Secrets

#### Staging Secrets

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `STAGING_SERVER_HOST` | Staging EC2 Elastic IP |
| `STAGING_SERVER_USER` | SSH username (`ubuntu`) |
| `STAGING_SSH_KEY` | SSH private key |
| `STAGING_POSTGRES_USER` | Postgres username |
| `STAGING_POSTGRES_PASSWORD` | Postgres password |
| `STAGING_POSTGRES_DB` | Database name |
| `STAGING_JWT_SECRET` | JWT signing secret |
| `STAGING_STRIPE_SECRET_KEY` | Stripe test key |

#### Production Secrets

| Secret | Description |
|--------|-------------|
| `PROD_SERVER_HOST` | Production EC2 Elastic IP |
| `PROD_SERVER_USER` | SSH username (`ubuntu`) |
| `PROD_SSH_KEY` | SSH private key |
| `PROD_POSTGRES_USER` | RDS username |
| `PROD_POSTGRES_PASSWORD` | RDS password |
| `PROD_POSTGRES_DB` | RDS database name |
| `PROD_DB_HOST` | RDS endpoint |
| `PROD_JWT_SECRET` | JWT signing secret |
| `PROD_STRIPE_SECRET_KEY` | Stripe live key |

---

## Deployment Guide

### Automatic Deployment (Recommended)

1. **Staging:**
   ```bash
   git checkout staging
   git push origin staging
   ```
   - CI builds images
   - Deploy workflow runs automatically
   - Access: `http://staging.storivainc.com`

2. **Production:**
   ```bash
   git checkout main
   git push origin main
   ```
   - CI builds images with `latest` tag
   - Deploy workflow runs automatically
   - Access: `http://api.storivainc.com`

### Manual Deployment

1. **SSH into server:**
   ```bash
   ssh -i ~/.ssh/key.pem ubuntu@<SERVER_IP>
   ```

2. **Navigate to app directory:**
   ```bash
   cd /srv/myapp
   ```

3. **Pull and restart:**
   ```bash
   # Staging
   docker compose -p storiva-staging -f docker/docker-compose.staging.yml pull
   docker compose -p storiva-staging -f docker/docker-compose.staging.yml up -d

   # Production
   docker compose -p storiva-prod -f docker/docker-compose.prod.yml pull
   docker compose -p storiva-prod -f docker/docker-compose.prod.yml up -d
   ```

### Health Check

```bash
# Check service status
docker compose -p storiva-staging ps

# Test health endpoint
curl http://localhost:8080/health

# View logs
docker compose -p storiva-staging logs -f auth
```

---

## DNS & SSL Setup

### Current DNS Status

| Domain | Target | Status |
|--------|--------|--------|
| `staging.storivainc.com` | Staging EIP | ✅ Configured |
| `api.storivainc.com` | Production EIP | ✅ Configured |
| `storivainc.com` | Production EIP | ✅ Configured |
| `www.storivainc.com` | Production EIP | ✅ Configured |

### Route53 Nameservers

To find the Route53 nameservers:

1. **AWS Console:**
   - Route53 → Hosted zones → storivainc.com
   - Copy the NS record values

2. **Terraform Output:**
   ```bash
   cd infra/terraform
   terraform output
   ```

### Required Action: Update Domain Registrar

> **Important:** For SSL certificates to work, you must delegate DNS to Route53.

1. Get Route53 NS records
2. Log into your domain registrar (where you bought storivainc.com)
3. Replace existing nameservers with Route53 NS values
4. Wait 24-48 hours for propagation

### SSL Certificate Setup (Pending)

After DNS propagates, SSL will be configured using certbot:

```bash
# Manual SSL setup (example)
certbot --nginx -d api.storivainc.com -d www.storivainc.com --non-interactive
```

**Auto-renewal:** Certbot auto-renews certificates before expiry.

---

## Troubleshooting

### Common Issues

#### 1. Docker Hub Login Failed

**Error:**
```
Error response from daemon: Get "https://registry-1.docker.io/v2/": unauthorized
```

**Fix:**
- Regenerate `DOCKERHUB_TOKEN` in Docker Hub
- Update the secret in GitHub

#### 2. SSH Connection Failed

**Error:**
```
Host key verification failed
```

**Fix:**
- Verify `STAGING_SSH_KEY` is correct
- Ensure key matches `key_name` in Terraform

#### 3. Health Check Failed

**Error:**
```
UNHEALTHY services detected
```

**Fix:**
```bash
# SSH into server
docker compose -p storiva-staging logs

# Restart specific service
docker compose -p storiva-staging restart auth
```

#### 4. Postgres Connection Failed

**Error:**
```
Connection refused to postgres:5432
```

**Fix:**
- Check Postgres is running: `docker compose -p storiva-staging ps postgres`
- Check environment variables are correct
- Wait for `postgres: condition: service_healthy`

### Manual Recovery

```bash
# SSH into server
ssh -i key.pem ubuntu@<SERVER_IP>

# Stop all services
docker compose -p storiva-staging -f docker/docker-compose.staging.yml down

# Clean up
docker system prune -f

# Restart fresh
docker compose -p storiva-staging -f docker/docker-compose.staging.yml up -d

# Check status
docker compose -p storiva-staging ps
```

---

## Roadmap

### Phase 1: Security Hardening ✅
- [x] Lock down SSH (IP-restricted)
- [ ] Add HTTP Basic Auth to staging
- [ ] Implement rate limiting

### Phase 2: Data Safety
- [ ] Migrate staging to RDS
- [ ] Automated database backups
- [ ] Cron job for disk cleanup

### Phase 3: Scaling
- [ ] Separate staging to cheaper instance
- [ ] Add Redis for caching
- [ ] Message queue for notifications

### Phase 4: Monitoring
- [ ] CloudWatch monitoring
- [ ] Alerting for unhealthy services
- [ ] Log aggregation

---

## Useful Commands

```bash
# Terraform
cd infra/terraform
terraform plan
terraform apply
terraform output

# Docker
docker compose -p storiva-staging ps
docker compose -p storiva-staging logs -f
docker compose -p storiva-staging restart <service>

# GitHub Actions
gh run list
gh run watch

# Health Checks
curl http://localhost:8080/health
curl http://localhost:8080/api/auth/health
```

---

## Support

For issues or questions:
- Check GitHub Actions logs
- Review this documentation
- Check AWS EC2 instance status
- Verify GitHub secrets are correct

---

*Document generated: April 2026*
