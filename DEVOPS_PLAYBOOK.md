# Storiva DevOps & Infrastructure Playbook

This playbook documents the architecture, infrastructure, CI/CD pipelines, and operational procedures for the Storiva Backend API. It serves as a reference for managing the environments and outlines a roadmap for future scaling.

---

## 1. Architecture Overview

Storiva utilizes a containerized microservices architecture:
*   **Services:** 6 isolated Node.js microservices (`gateway`, `auth`, `profile`, `payment`, `notification`, `storage`).
*   **Routing:** The `gateway` service acts as the central entry point, routing requests to the respective backend services via synchronous HTTP over the internal Docker network.
*   **Database:** A single shared PostgreSQL database instance is used across all services.
*   **Reverse Proxy:** Nginx routes external traffic to the `gateway`.

---

## 2. Infrastructure Setup (AWS via Terraform)

The infrastructure is codified using Terraform and deployed to AWS. Currently, the architecture favors a cost-effective "All-in-One" approach.

*   **Compute:** A single `t3.large` EC2 instance hosts all three environments (Dev, Staging, Production).
*   **Storage:** 50 GB `gp3` EBS root volume to accommodate Docker images and the PostgreSQL database.
*   **Networking:** 
    *   Elastic IP (EIP) assigned to ensure the IP survives reboots.
    *   Route 53 records map the root domain, `www`, `dev`, and `staging` subdomains to the EIP.
*   **Security Group:**
    *   Port `80` & `443`: Production HTTP/HTTPS
    *   Port `8080`: Development environment
    *   Port `8081`: Staging environment
    *   Port `22`: SSH Access
*   **Bootstrapping:** Terraform `user_data` automatically installs Docker, Docker Compose, and provisions the `/srv/myapp` directory on boot.

---

## 3. Environments & Docker Strategy

All environments are containerized using Docker and Docker Compose. Images are hosted on **Docker Hub**.

### Development & Staging (`docker-compose.dev.yml`)
*   Shares a single Compose file to maintain DRY principles.
*   Differentiated at runtime using environment variables:
    *   **Dev:** `NGINX_PORT=8080`, `IMAGE_TAG=dev`
    *   **Staging:** `NGINX_PORT=8081`, `IMAGE_TAG=staging`

### Production (`docker-compose.prod.yml`)
*   Hardcoded to `NODE_ENV=production`.
*   Uses strict restart policies (`restart: always`).
*   Integrates an automated `certbot` container to handle SSL certificate generation and renewal every 12 hours.

---

## 4. CI/CD Pipeline (GitHub Actions)

### Continuous Integration (`ci.yml`)
*   **Triggers:** Push to `dev`, `staging`, or `main`.
*   **Build Matrix:** Compiles and builds all 6 service images concurrently.
*   **Registry:** Pushes to Docker Hub tagged with both the environment branch name and the `github.sha` for traceability.

### Continuous Deployment (`deploy-prod.yml`, etc.)
*   **Triggers:** Successful completion of the CI workflow.
*   **Execution:** SSHs into the EC2 instance, pulls the latest repository code and updated Docker Hub images.
*   **Rolling Restarts:** Uses a `for` loop to restart services sequentially (`docker compose up -d --no-deps $SERVICE`) to avoid sudden CPU/RAM spikes and minimize downtime.
*   **Cleanup:** Runs `docker image prune -f` at the end to free up EBS volume space.

---

## 5. Operational Runbook

### Connecting to the Server
```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<EC2_ELASTIC_IP>
cd /srv/myapp
```

### Viewing Logs
```bash
# View all production logs
docker compose -p storiva-prod -f docker/docker-compose.prod.yml logs -f

# View logs for a specific service (e.g., auth)
docker compose -p storiva-prod -f docker/docker-compose.prod.yml logs -f auth
```

### Manual Restart / Deployment
```bash
# Pull latest images
docker compose -p storiva-prod -f docker/docker-compose.prod.yml --env-file prod.env pull

# Restart everything
docker compose -p storiva-prod -f docker/docker-compose.prod.yml --env-file prod.env up -d
```

### Emergency Disk Cleanup
If the 50GB EBS volume is full, clean up all unused Docker data:
```bash
docker system prune -af --volumes
```

---

## 6. Infrastructure Roadmap & Security Recommendations

As Storiva scales, the following technical debt and risks should be addressed:

### Phase 1: Security Hardening (Immediate)
*   **Lock Down SSH:** Restrict Port 22 in the Terraform Security Group to your specific IP address, or migrate to AWS SSM Session Manager to close Port 22 entirely.
*   **Protect Dev/Staging:** Add Nginx HTTP Basic Authentication to ports `8080` and `8081` to prevent public access to unfinished features.

### Phase 2: Data Safety & Fault Tolerance (Short-Term)
*   **Migrate Database:** Move PostgreSQL off the EC2 instance and into **AWS RDS**. This provides automated backups, point-in-time recovery, and removes the risk of losing production data if the EC2 instance goes down.
*   **Cron Job Pruning:** Ensure `docker system prune` runs automatically via a cron job on the EC2 instance to prevent the 50GB disk from filling up from Dev/Staging deployments.

### Phase 3: Scaling & Decoupling (Long-Term)
*   **Environment Isolation:** Move the Dev and Staging environments to a separate, cheaper EC2 instance (e.g., `t3.small`) to prevent "noisy neighbor" resource contention where a development bug could crash the production server.
*   **Message Broker:** Introduce RabbitMQ or Redis Pub/Sub to move away from purely synchronous HTTP calls (especially for the `notification` service), increasing system fault tolerance.
*   **VPC Separation:** Move away from the default AWS VPC. Create a custom VPC with public and private subnets, placing the database in the private subnet.