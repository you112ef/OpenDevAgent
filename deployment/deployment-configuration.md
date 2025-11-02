# CI/CD and Environment Configuration

## deployment/docker-registry-setup.sh

```bash
#!/bin/bash
set -e

# AWS ECR Setup for Docker Registry

AWS_ACCOUNT_ID=${1:-"123456789"}
AWS_REGION=${2:-"us-east-1"}
REGISTRY_NAME="opendevagent"

echo "Setting up ECR registry..."

# Create ECR repositories
create_ecr_repo() {
    local repo_name=$1
    echo "Creating ECR repository: $repo_name"
    
    aws ecr create-repository \
        --repository-name "$repo_name" \
        --region "$AWS_REGION" \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES \
        2>/dev/null || echo "Repository $repo_name already exists"
}

# Create repositories
create_ecr_repo "$REGISTRY_NAME/backend"
create_ecr_repo "$REGISTRY_NAME/frontend"
create_ecr_repo "$REGISTRY_NAME/sandbox"

# Configure lifecycle policies
configure_lifecycle_policy() {
    local repo_name=$1
    
    echo "Configuring lifecycle policy for $repo_name"
    
    aws ecr put-lifecycle-policy \
        --repository-name "$repo_name" \
        --lifecycle-policy-text '{
            "rules": [
                {
                    "rulePriority": 1,
                    "description": "Keep last 10 images",
                    "selection": {
                        "tagStatus": "any",
                        "countType": "imageCountMoreThan",
                        "countNumber": 10
                    },
                    "action": {
                        "type": "expire"
                    }
                }
            ]
        }' \
        --region "$AWS_REGION"
}

configure_lifecycle_policy "$REGISTRY_NAME/backend"
configure_lifecycle_policy "$REGISTRY_NAME/frontend"
configure_lifecycle_policy "$REGISTRY_NAME/sandbox"

# Get ECR login credentials
echo "Logging in to ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "ECR setup complete!"
echo "Registry: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REGISTRY_NAME"
```

## deployment/build-and-push.sh

```bash
#!/bin/bash
set -e

# Build and push Docker images to registry

AWS_ACCOUNT_ID=${1:-"123456789"}
AWS_REGION=${2:-"us-east-1"}
IMAGE_TAG=${3:-"latest"}
REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "Building and pushing Docker images..."
echo "Image tag: $IMAGE_TAG"

# Build backend
echo "Building backend image..."
docker build \
    -t "$REGISTRY/opendevagent/backend:$IMAGE_TAG" \
    -t "$REGISTRY/opendevagent/backend:latest" \
    -f backend/Dockerfile \
    .

echo "Pushing backend image..."
docker push "$REGISTRY/opendevagent/backend:$IMAGE_TAG"
docker push "$REGISTRY/opendevagent/backend:latest"

# Build frontend
echo "Building frontend image..."
docker build \
    -t "$REGISTRY/opendevagent/frontend:$IMAGE_TAG" \
    -t "$REGISTRY/opendevagent/frontend:latest" \
    -f frontend/Dockerfile \
    frontend/

echo "Pushing frontend image..."
docker push "$REGISTRY/opendevagent/frontend:$IMAGE_TAG"
docker push "$REGISTRY/opendevagent/frontend:latest"

# Build sandbox
echo "Building sandbox image..."
docker build \
    -t "$REGISTRY/opendevagent/sandbox:$IMAGE_TAG" \
    -t "$REGISTRY/opendevagent/sandbox:latest" \
    -f sandbox_templates/Dockerfile.python \
    .

echo "Pushing sandbox image..."
docker push "$REGISTRY/opendevagent/sandbox:$IMAGE_TAG"
docker push "$REGISTRY/opendevagent/sandbox:latest"

echo "All images built and pushed successfully!"
```

## deployment/.env.production

```bash
# Production Environment Configuration

# Application
ENVIRONMENT=production
LOG_LEVEL=INFO
DEBUG=False

# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012
AWS_ECR_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com

# Backend Configuration
BACKEND_PORT=8000
BACKEND_WORKERS=4
BACKEND_CPU=1000m
BACKEND_MEMORY=2Gi
BACKEND_DESIRED_REPLICAS=3
BACKEND_MIN_REPLICAS=2
BACKEND_MAX_REPLICAS=20

# Frontend Configuration
FRONTEND_PORT=3000
FRONTEND_CPU=512m
FRONTEND_MEMORY=1Gi
FRONTEND_DESIRED_REPLICAS=2
NEXT_PUBLIC_BACKEND_URL=https://api.opendevagent.com

# Database Configuration
DATABASE_TYPE=postgresql
DATABASE_HOST=db.opendevagent.com
DATABASE_PORT=5432
DATABASE_NAME=opendevagent_prod
DATABASE_POOL_SIZE=20

# Cache Configuration
REDIS_HOST=cache.opendevagent.com
REDIS_PORT=6379
REDIS_DB=0

# Sandbox Configuration
SANDBOX_TIMEOUT=60
SANDBOX_MEMORY=2g
SANDBOX_CPUS=2
SANDBOX_MAX_CONCURRENT=10

# Security
CORS_ORIGINS=https://app.opendevagent.com,https://api.opendevagent.com
SESSION_TIMEOUT=3600

# Monitoring
PROMETHEUS_ENABLED=true
JAEGER_ENABLED=true
JAEGER_ENDPOINT=http://jaeger:6831

# Logging
LOG_FORMAT=json
LOG_RETENTION_DAYS=30

# Backup
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30
```

## deployment/secrets-management.sh

```bash
#!/bin/bash
set -e

# Secure secrets management using AWS Secrets Manager

AWS_REGION=${1:-"us-east-1"}

echo "Setting up secrets in AWS Secrets Manager..."

# Create OpenRouter API key secret
echo "Creating OpenRouter API key secret..."
aws secretsmanager create-secret \
    --name opendevagent/openrouter-api-key \
    --region "$AWS_REGION" \
    --kms-key-id "alias/aws/secretsmanager" \
    --secret-string "sk-or-v1-YOUR-KEY-HERE" \
    2>/dev/null || echo "Secret already exists"

# Create database password secret
echo "Creating database password secret..."
aws secretsmanager create-secret \
    --name opendevagent/database-password \
    --region "$AWS_REGION" \
    --secret-string "$(openssl rand -base64 32)" \
    2>/dev/null || echo "Secret already exists"

# Create Redis password secret
echo "Creating Redis password secret..."
aws secretsmanager create-secret \
    --name opendevagent/redis-password \
    --region "$AWS_REGION" \
    --secret-string "$(openssl rand -base64 32)" \
    2>/dev/null || echo "Secret already exists"

# Create JWT secret
echo "Creating JWT secret..."
aws secretsmanager create-secret \
    --name opendevagent/jwt-secret \
    --region "$AWS_REGION" \
    --secret-string "$(openssl rand -base64 64)" \
    2>/dev/null || echo "Secret already exists"

# Configure rotation for sensitive secrets
echo "Configuring secret rotation..."
aws secretsmanager rotate-secret \
    --secret-id opendevagent/database-password \
    --rotation-lambda-arn arn:aws:lambda:$AWS_REGION:ACCOUNT_ID:function:SecretsManagerRotation \
    --rotation-rules AutomaticallyAfterDays=30 \
    --region "$AWS_REGION" \
    2>/dev/null || echo "Rotation already configured"

echo "Secrets setup complete!"
```

## deployment/deployment-checklist.md

```markdown
# Production Deployment Checklist

## Pre-Deployment Phase

### Code Review & Testing
- [ ] All code merged to main branch
- [ ] Pull request reviews completed
- [ ] Automated tests passing (CI/CD)
- [ ] Security scanning passed
- [ ] Code coverage acceptable (>80%)
- [ ] Performance testing completed
- [ ] Load testing acceptable
- [ ] No critical security issues
- [ ] Documentation updated

### Infrastructure Review
- [ ] Infrastructure as Code reviewed
- [ ] Security groups configured correctly
- [ ] Network policies defined
- [ ] SSL/TLS certificates valid
- [ ] Backup strategy in place
- [ ] Disaster recovery plan tested
- [ ] Capacity planning completed
- [ ] Cost estimation approved

### Configuration Review
- [ ] Environment variables configured
- [ ] Secrets securely stored
- [ ] Database migrations ready
- [ ] Feature flags set appropriately
- [ ] Logging configuration correct
- [ ] Monitoring setup verified
- [ ] Alert thresholds configured
- [ ] Escalation paths defined

### Team Preparation
- [ ] Deployment window scheduled
- [ ] Team members notified
- [ ] Stakeholders informed
- [ ] Communications plan ready
- [ ] Rollback procedure documented
- [ ] On-call support assigned
- [ ] Support tickets categorized
- [ ] Documentation updated

## Deployment Phase

### Pre-Deployment
- [ ] Backup current production state
- [ ] Backup database
- [ ] Backup configuration files
- [ ] Enable maintenance mode (if applicable)
- [ ] Notify users of deployment
- [ ] Close new task submissions
- [ ] Monitor system load

### Deployment Execution
- [ ] Pull latest code
- [ ] Build Docker images
- [ ] Push images to registry
- [ ] Run pre-deployment migrations
- [ ] Update infrastructure (Terraform)
- [ ] Update Kubernetes manifests
- [ ] Deploy to staging environment
- [ ] Run smoke tests on staging
- [ ] Get approval to proceed
- [ ] Deploy to production
- [ ] Monitor deployment progress
- [ ] Verify all pods/services running

### Post-Deployment Verification
- [ ] Health checks passing
- [ ] API endpoints responding
- [ ] Frontend accessible
- [ ] Database connectivity verified
- [ ] Cache working correctly
- [ ] Logging functional
- [ ] Monitoring active
- [ ] Alerts configured
- [ ] No errors in logs
- [ ] Performance within expectations
- [ ] Load balancer traffic healthy
- [ ] Auto-scaling responsive

### Smoke Tests
- [ ] `/health` endpoint returns 200
- [ ] `/api/tasks` endpoint accessible
- [ ] Frontend loads successfully
- [ ] API documentation available
- [ ] Sample task submission works
- [ ] Task status retrieval works
- [ ] No 5xx errors in logs

## Post-Deployment Phase

### Immediate Post-Deployment (First Hour)
- [ ] Monitor error logs
- [ ] Monitor performance metrics
- [ ] Monitor alert notifications
- [ ] Check user feedback channels
- [ ] Verify data integrity
- [ ] Test core functionality
- [ ] Validate backup integrity
- [ ] Review CloudWatch/Prometheus metrics

### Extended Monitoring (Next 24 Hours)
- [ ] Monitor system stability
- [ ] Track error rates
- [ ] Monitor resource utilization
- [ ] Check user activity patterns
- [ ] Verify scheduled tasks running
- [ ] Monitor cost metrics
- [ ] Review application logs
- [ ] Check for memory leaks
- [ ] Verify cache effectiveness
- [ ] Monitor database performance

### Documentation & Wrap-up
- [ ] Document deployment details
- [ ] Record any issues encountered
- [ ] Document resolution steps
- [ ] Update runbooks
- [ ] Update playbooks
- [ ] Send deployment summary email
- [ ] Schedule post-mortem (if issues)
- [ ] Update monitoring dashboards
- [ ] Archive deployment logs
- [ ] Close deployment ticket

## Rollback Triggers

Deploy rollback if:
- [ ] Error rate > 1% for 5 minutes
- [ ] Response time p95 > 5 seconds
- [ ] Health checks failing
- [ ] Database corruption detected
- [ ] Security vulnerability discovered
- [ ] Data loss detected
- [ ] Critical business logic broken
- [ ] Unable to scale up under load

## Emergency Contacts

- On-Call Engineer: [phone]
- Engineering Manager: [phone]
- DevOps Lead: [phone]
- Database Administrator: [phone]
- Security Team: [email]

## Deployment Timeline

| Phase | Start | Duration | Owner |
|-------|-------|----------|-------|
| Pre-deployment validation | T-30min | 30min | QA Lead |
| Backup & preparation | T-5min | 5min | DevOps |
| Deployment | T+0 | 15-20min | DevOps |
| Verification | T+15min | 10min | QA |
| Monitoring | T+25min | 60min | On-call |

## Sign-offs Required

- [ ] Engineering Manager approval
- [ ] DevOps Lead approval
- [ ] QA Lead verification
- [ ] Security review completion
- [ ] Product Manager notification

## Version Information

- **Deployment Version**: v1.0.0
- **Release Date**: [date]
- **Deployed By**: [name]
- **Approved By**: [name]
- **Rollback Plan**: Version [previous version]
- **Emergency Contact**: [contact]
```

## deployment/performance-benchmarks.md

```markdown
# Performance Benchmarks

## Baseline Metrics (Production)

### API Response Times
- GET /health: < 50ms (p99)
- POST /api/submit_task: < 500ms (p99)
- GET /api/task_status/{id}: < 100ms (p99)
- GET /api/tasks: < 200ms (p99)

### Throughput
- API: 1000+ requests/second
- Task submission: 100+ tasks/second
- Concurrent tasks: 50+ simultaneous

### Resource Utilization
- Backend CPU: 40-60% average
- Backend Memory: 50-70% average
- Frontend CPU: 20-30% average
- Frontend Memory: 40-60% average

### Task Execution
- Average completion time: 45-60 seconds
- Success rate: > 95%
- Error rate: < 1%

## Performance Test Results

[Regular performance test results with graphs and analysis]

## Optimization Recommendations

1. Cache optimization
2. Database query optimization
3. Container resource tuning
4. Network optimization
```

## deployment/disaster-recovery-plan.md

```markdown
# Disaster Recovery Plan

## RPO (Recovery Point Objective)
- Maximum data loss: 1 hour
- Backup frequency: Hourly

## RTO (Recovery Time Objective)
- Maximum downtime: 4 hours
- Failover time: 30 minutes

## Backup Strategy

### Automated Backups
- Database: Hourly incremental, daily full
- EFS/Storage: Daily snapshots
- Configuration: Real-time replication

### Manual Backups
- Pre-deployment backup (required)
- Weekly full system backup
- Monthly archive backup

## Failover Procedure

### Failover to Backup Region
1. Assess failure severity
2. Notify stakeholders
3. Restore from backups
4. Verify data integrity
5. Switch traffic to backup
6. Monitor stability

### Failback to Primary Region
1. Fix primary region issue
2. Restore latest backups
3. Sync data
4. Switch traffic back
5. Monitor stability

## Testing Schedule
- Monthly: Backup restoration test
- Quarterly: Full disaster recovery drill
- Annually: Failover to backup region drill
```
