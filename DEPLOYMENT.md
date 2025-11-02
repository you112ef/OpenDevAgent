# Deployment Guide - OpenDevAgent

## Local Development Setup

### Prerequisites Check

```bash
# Check Docker
docker --version  # >= 20.10
docker-compose --version  # >= 1.29

# Check Python
python3 --version  # >= 3.11

# Check Node
node --version  # >= 18
npm --version  # >= 9
```

### Step 1: Clone Repository

```bash
cd /project/workspace
git clone <repository-url> OpenDevAgent_KiloInspired
cd OpenDevAgent_KiloInspired
```

### Step 2: Environment Configuration

```bash
cp .env.example .env

# Edit .env with your OpenRouter API key
# OPENROUTER_API_KEY=sk-or-v1-<your-key>
nano .env
```

### Step 3: Build Docker Images

```bash
# Build all services
docker-compose build

# Output should show:
# Successfully built <image-id> for sandbox, backend, frontend
```

### Step 4: Start Services

```bash
# Start all services
docker-compose up -d

# Monitor startup
docker-compose logs -f

# Expected output:
# sandbox-builder exited with code 0 (normal)
# backend running on 0.0.0.0:8000
# frontend running on 0.0.0.0:3000
```

### Step 5: Verify Installation

```bash
# Health check - Backend
curl http://localhost:8000/health

# Expected response:
# {"status":"healthy","service":"OpenDevAgent Backend"}

# Frontend accessibility
curl http://localhost:3000

# Expected: HTML page
```

### Step 6: Access Application

- **Frontend**: Open browser to http://localhost:3000
- **API Documentation**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Docker Compose Configuration Details

### Services

#### Backend Service
```yaml
backend:
  build: ./backend/Dockerfile
  ports:
    - "8000:8000"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock  # Docker access
    - ./backend/work_dir:/app/work_dir             # Sandbox output
  environment:
    - SANDBOX_DOCKER_SOCKET=/var/run/docker.sock
    - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
```

#### Frontend Service
```yaml
frontend:
  build: ./frontend/Dockerfile
  ports:
    - "3000:3000"
  environment:
    - NEXT_PUBLIC_BACKEND_URL=http://localhost:8000
  depends_on:
    - backend
```

#### Sandbox Builder
```yaml
sandbox-builder:
  build: ./sandbox_templates/Dockerfile.python
  image: opendev-sandbox:python
```

### Networking

All services communicate via the `opendev` bridge network:
- Backend ↔ Frontend: Internal Docker DNS
- Localhost ↔ Services: Exposed ports

## Manual Setup (Without Docker)

### Backend Setup

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
cd backend
pip install -r requirements.txt

# Run backend
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Frontend Setup

```bash
cd frontend
npm install
npm run dev  # Runs on http://localhost:3000
```

### Sandbox Note
Manual setup requires Docker for sandbox execution:
```bash
# Build sandbox image separately
docker build -f sandbox_templates/Dockerfile.python -t opendev-sandbox:python .
```

## Production Deployment

### Cloud Platforms

#### AWS ECS (Recommended)

1. **Push Docker Images to ECR**
   ```bash
   aws ecr get-login-password | docker login --username AWS --password-stdin <aws-account>.dkr.ecr.<region>.amazonaws.com
   
   docker tag opendev-backend:latest <account>.dkr.ecr.<region>.amazonaws.com/opendev-backend:latest
   docker push <account>.dkr.ecr.<region>.amazonaws.com/opendev-backend:latest
   ```

2. **Create ECS Task Definition**
   ```json
   {
     "family": "opendev-backend",
     "containerDefinitions": [
       {
         "name": "backend",
         "image": "<account>.dkr.ecr.<region>.amazonaws.com/opendev-backend:latest",
         "memory": 2048,
         "cpu": 1024,
         "essential": true,
         "portMappings": [
           {
             "containerPort": 8000,
             "hostPort": 8000,
             "protocol": "tcp"
           }
         ]
       }
     ]
   }
   ```

3. **Create ECS Cluster & Service**
   ```bash
   aws ecs create-cluster --cluster-name opendev-cluster
   
   aws ecs create-service \
     --cluster opendev-cluster \
     --service-name opendev-backend \
     --task-definition opendev-backend \
     --desired-count 2 \
     --load-balancers targetGroupArn=<target-group-arn>,containerName=backend,containerPort=8000
   ```

#### Google Cloud Run

```bash
# Build and push image
gcloud builds submit --tag gcr.io/<project>/opendev-backend

# Deploy
gcloud run deploy opendev-backend \
  --image gcr.io/<project>/opendev-backend \
  --platform managed \
  --memory 2Gi \
  --cpu 2 \
  --set-env-vars OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
```

#### Azure Container Instances

```bash
az acr build --registry <registry-name> \
  --image opendev-backend:latest .

az container create \
  --resource-group opendev-rg \
  --name opendev-backend \
  --image <registry>.azurecr.io/opendev-backend:latest \
  --cpu 2 \
  --memory 2
```

### Kubernetes Deployment

#### Docker Desktop Kubernetes

```bash
# Enable Kubernetes in Docker Desktop

# Create namespace
kubectl create namespace opendev

# Create secrets
kubectl create secret generic openrouter-secret \
  --from-literal=api-key=${OPENROUTER_API_KEY} \
  -n opendev

# Apply deployment
kubectl apply -f k8s/deployment.yaml -n opendev

# Check status
kubectl get pods -n opendev
```

#### Kubernetes Manifest Example

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opendev-backend
  namespace: opendev
spec:
  replicas: 3
  selector:
    matchLabels:
      app: opendev-backend
  template:
    metadata:
      labels:
        app: opendev-backend
    spec:
      containers:
      - name: backend
        image: opendev-backend:latest
        ports:
        - containerPort: 8000
        env:
        - name: OPENROUTER_API_KEY
          valueFrom:
            secretKeyRef:
              name: openrouter-secret
              key: api-key
        resources:
          requests:
            memory: "2Gi"
            cpu: "2"
          limits:
            memory: "4Gi"
            cpu: "4"

---
apiVersion: v1
kind: Service
metadata:
  name: opendev-backend-service
  namespace: opendev
spec:
  type: LoadBalancer
  selector:
    app: opendev-backend
  ports:
  - port: 80
    targetPort: 8000
```

## Configuration Management

### Environment Variables

**Backend**:
```bash
OPENROUTER_API_KEY=sk-or-v1-...          # Required
SANDBOX_DOCKER_SOCKET=/var/run/docker.sock
SANDBOX_TIMEOUT=60
SANDBOX_MEMORY=2g
SANDBOX_CPUS=2
```

**Frontend**:
```bash
NEXT_PUBLIC_BACKEND_URL=http://localhost:8000
```

### Scaling Configuration

**For Increased Load**:

1. **Backend**
   ```yaml
   # docker-compose.yml
   backend:
     deploy:
       replicas: 3  # Run 3 instances
   ```

2. **Load Balancing**
   - Use Nginx as reverse proxy
   - Configure round-robin

3. **Docker Socket**
   - Ensure Docker daemon can handle multiple containers
   - Monitor: `docker stats`

## Monitoring & Logging

### Docker Logs

```bash
# View logs for all services
docker-compose logs -f

# View specific service
docker-compose logs -f backend
docker-compose logs -f frontend

# Save logs to file
docker-compose logs > logs.txt
```

### Health Checks

```bash
# Backend health
curl -s http://localhost:8000/health | jq

# Frontend
curl -I http://localhost:3000

# Task status
curl http://localhost:8000/api/tasks
```

### Performance Monitoring

```bash
# Monitor container resource usage
docker stats --no-stream

# Check specific container
docker stats opendev-backend --no-stream
```

## Troubleshooting

### Issue: Backend won't connect to Docker

**Solution**:
```bash
# Check Docker socket permissions
ls -l /var/run/docker.sock

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Restart Docker
sudo systemctl restart docker
```

### Issue: Frontend API connection fails

**Solution**:
```bash
# Verify backend is running
docker-compose ps

# Check network connectivity
docker-compose exec frontend curl http://backend:8000/health

# Update NEXT_PUBLIC_BACKEND_URL if needed
```

### Issue: Sandbox image not found

**Solution**:
```bash
# Build sandbox image explicitly
docker build -f sandbox_templates/Dockerfile.python -t opendev-sandbox:python .

# Verify image exists
docker images | grep opendev-sandbox
```

### Issue: Out of disk space

**Solution**:
```bash
# Clean up unused Docker resources
docker system prune -a

# Remove specific volume
docker volume rm opendev_workdir

# Clear container logs
docker logs --tail 0 <container-id>
```

### Issue: High memory usage

**Solution**:
```bash
# Monitor memory
docker stats

# Adjust resource limits in docker-compose.yml
backend:
  environment:
    - SANDBOX_MEMORY=1g  # Reduce from 2g

# Restart services
docker-compose restart
```

## Backup & Recovery

### Backup Procedure

```bash
# Backup Docker volumes
docker run --rm -v opendev_workdir:/data -v $(pwd):/backup \
  alpine tar czf /backup/workdir-backup.tar.gz -C /data .

# Backup configurations
cp .env .env.backup
tar czf configs-backup.tar.gz frontend/next.config.js backend/requirements.txt
```

### Recovery Procedure

```bash
# Restore volume
docker run --rm -v opendev_workdir:/data -v $(pwd):/backup \
  alpine tar xzf /backup/workdir-backup.tar.gz -C /data

# Restore from backup
cp .env.backup .env

# Restart services
docker-compose restart
```

## Security Hardening

### SSL/TLS Configuration

```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365

# Update docker-compose.yml to use HTTPS
backend:
  environment:
    - SSL_CERT_FILE=/app/cert.pem
    - SSL_KEY_FILE=/app/key.pem
```

### API Key Rotation

```bash
# Update .env with new key
OPENROUTER_API_KEY=sk-or-v1-new-key

# Restart backend
docker-compose restart backend
```

### Network Security

```yaml
# docker-compose.yml - Expose only necessary ports
services:
  backend:
    ports:
      - "127.0.0.1:8000:8000"  # Localhost only
  frontend:
    ports:
      - "0.0.0.0:3000:3000"    # Public (if needed)
```

## Maintenance

### Regular Tasks

1. **Daily**
   - Monitor error logs
   - Check resource usage
   - Verify API key validity

2. **Weekly**
   - Update dependencies
   - Review security logs
   - Backup configurations

3. **Monthly**
   - Update Docker images
   - Review performance metrics
   - Audit API key usage

### Updates

```bash
# Update dependencies
docker-compose down
git pull
docker-compose build --no-cache
docker-compose up -d

# Verify post-update
curl http://localhost:8000/health
```

---

**Deployment Guide Version**: 1.0
**Last Updated**: 2024
