# Review of CI/CD, Infrastructure, and IaC

This document provides a comprehensive review of the current CI/CD pipelines, Infrastructure as Code (Terraform), and Docker deployments for the Storiva Backend API.

## 1. Infrastructure as Code (Terraform)

### Current State
*   **Provider:** AWS
*   **Compute:** A single `t3.large` EC2 instance handles Dev, Staging, and Production environments simultaneously.
*   **Storage:** 50 GB `gp3` root volume.
*   **Network:** Default VPC, single Elastic IP.
*   **Security:** Port 22 (SSH), 80/443 (HTTP/HTTPS), 8080 (Dev), and 8081 (Staging) are open to the world (`0.0.0.0/0`).
*   **Bootstrapping:** `user_data` script installs Docker and Docker Compose on boot.

### Findings & Vulnerabilities
*   **CRITICAL RISKS:**
    *   **Single Point of Failure / Resource Contention:** Running Dev, Staging, and Prod on the same EC2 instance is highly dangerous. A memory leak or CPU spike in a dev service will bring down the production environment.
    *   **Data Loss Risk:** PostgreSQL is running in Docker using an EBS volume attached to the EC2 instance. If the instance is accidentally terminated or the volume gets corrupted, all production data is lost (unless manual backups are being taken).
    *   **Security (SSH):** Port 22 is open to the world (`0.0.0.0/0`). This makes the server vulnerable to brute-force attacks.
    *   **Security (Exposed Environments):** Dev (8080) and Staging (8081) environments are publicly accessible.
*   **Technical Debt:**
    *   The `50GB` EBS volume will fill up extremely fast with 3 separate instances of 6 microservices + PostgreSQL databases pulling new Docker images frequently.

## 2. CI/CD (GitHub Actions)

### Current State
*   **CI Pipeline (`ci.yml`):** Triggers on push to `dev`, `staging`, `main`. Uses a matrix to build all 6 microservices via Docker Buildx and pushes them to Docker Hub. Implements GitHub Actions caching.
*   **CD Pipelines (`deploy-dev.yml`, `deploy-staging.yml`, `deploy-prod.yml`):** SSHs into the server, generates a `.env` file using GitHub secrets, and runs `docker compose up -d` (for dev/staging) or a rolling restart (for prod).

### Findings & Vulnerabilities
*   **Strengths:**
    *   Docker caching is implemented well, which speeds up builds.
    *   Branch-based image tagging (`dev`, `staging`, `latest` + `sha`) is robust for traceability.
*   **Areas for Improvement:**
    *   **Zero-Downtime Deployment Issues:** The production deployment uses `docker compose up -d --no-deps $SERVICE` in a loop. Because there are no health checks on the microservices themselves (only on Postgres), Docker immediately kills the old container and starts the new one, resulting in a few seconds of downtime per service. 
    *   **No Rollback Mechanism:** If a newly deployed service crashes on startup, the CD pipeline still reports "success," and production is left in a broken state.
    *   **Over-building:** `ci.yml` builds all 6 services on every push, even if only one service was modified. This wastes GitHub Actions minutes.

## 3. Docker & Compose Setup

### Current State
*   `docker-compose.dev.yml` is reused for both dev and staging via project names (`-p storiva-dev`, `-p storiva-staging`).
*   `docker-compose.prod.yml` includes an auto-renewing Certbot container.
*   Services communicate internally via the Docker bridge network.

### Findings & Vulnerabilities
*   **Strengths:**
    *   Services are well isolated.
    *   Using Project Names (`-p`) to isolate Dev and Staging from the same compose file is a smart, DRY approach.
*   **Areas for Improvement:**
    *   The node applications run as the `root` user inside the container (assumed, unless `USER node` is specified in the Dockerfiles).
    *   Missing health checks for the microservices in the compose files.

---

## 4. Recommended Action Plan

### Immediate / High Priority (Phase 1)
1.  **Secure the Infrastructure (`main.tf`):**
    *   Restrict Port 22, 8080, and 8081 to specific developer IP addresses.
    *   Alternatively, remove Port 22 and implement AWS SSM Session Manager.
2.  **Optimize CI (`ci.yml`):**
    *   Implement path filtering so that a service's Docker image is only built if the code in its specific directory (`services/<service-name>`) has changed.

### Medium Priority (Phase 2)
1.  **Isolate Production Data:**
    *   Provision an AWS RDS instance for PostgreSQL via Terraform.
    *   Update `deploy-prod.yml` and `docker-compose.prod.yml` to connect to RDS instead of the Dockerized PostgreSQL container.
2.  **Improve Production Deployments:**
    *   Add Docker health checks to the Node.js services.
    *   Investigate using Docker Swarm or a simpler Blue/Green deployment script to achieve true zero-downtime deployments.

### Long Term (Phase 3)
1.  **Environment Separation:**
    *   Update Terraform to provision a separate, smaller EC2 instance (e.g., `t3.small`) specifically for Dev and Staging, leaving the `t3.large` solely for Production.
