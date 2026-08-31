#!/bin/bash
# Runs once on first boot. Installs Docker + Docker Compose and starts the app.
# ${db_host}, ${db_name}, ${db_username}, ${db_password} are filled in by Terraform.

set -e
exec > /var/log/user-data.log 2>&1
echo "=== Bootstrap started at $(date) ==="

apt-get update -y
apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# Install Docker Compose plugin
apt-get install -y docker-compose-plugin

mkdir -p /home/ubuntu/app
cd /home/ubuntu/app

# Docker Compose file for the app (uses RDS for Postgres, not a local container)
# NOTE: $${DOCKERHUB_USERNAME} is escaped so Terraform leaves it as-is;
# docker compose fills it in from the .env file below.
cat > docker-compose.yml << 'COMPOSE'
services:
  backend:
    image: $${DOCKERHUB_USERNAME}/app-backend:latest
    container_name: app_backend
    restart: always
    environment:
      DB_URL: jdbc:postgresql://${db_host}/${db_name}
      DB_USER: ${db_username}
      DB_PASSWORD: ${db_password}
    ports:
      - "8080:8080"

  frontend:
    image: $${DOCKERHUB_USERNAME}/app-frontend:latest
    container_name: app_frontend
    restart: always
    ports:
      - "3000:80"
COMPOSE

# Set your DockerHub username before the images can be pulled
cat > .env << 'ENV'
DOCKERHUB_USERNAME=REPLACE_WITH_YOUR_DOCKERHUB_USERNAME
ENV

docker compose pull || echo "Image pull skipped - update .env and run docker compose up -d"
docker compose up -d

echo "=== Bootstrap complete at $(date) ==="
