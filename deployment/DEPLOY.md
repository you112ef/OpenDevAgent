# OpenDevAgent - Production Deployment Guide

## 🚀 Quick Start (Choose Your Path)

### Option 1: AWS ECS (Recommended for AWS Users)
**Time: 20-30 minutes | Cost: ~$150-250/month | Managed service**

```bash
# 1. Setup AWS credentials
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_REGION=us-east-1

# 2. Initialize Terraform
cd deployment/aws-ecs
terraform init

# 3. Plan and apply
terraform plan -out=tfplan
terraform apply tfplan

# 4. Get deployment info
terraform output -json
```

### Option 2: Kubernetes (Recommended for Multi-Cloud)
**Time: 15-25 minutes | Cost: Varies | Flexible, portable**

```bash
# 1. Ensure kubectl is configured
kubectl cluster-info

# 2. Create namespace and secrets
kubectl apply -f deployment/kubernetes-manifests.yaml
kubectl create secret generic opendevagent-secrets \
  --from-literal=openrouter_api_key=$OPENROUTER_KEY \
  -n opendevagent

# 3. Verify deployment
kubectl get pods -n opendevagent
kubectl logs -f deployment/backend -n opendevagent
```

### Option 3: Docker Compose (Local Development/Testing)
**Time: 5 minutes | Cost: Free | Single machine**

```bash
# 1. Setup environment
cp deployment/.env.example .env
# Edit .env with your OpenRouter API key

# 2. Start services
docker-compose up -d

# 3. Verify
docker ps
curl http://localhost:3000
curl http://localhost:8000/api/health
```

---

## 📋 Pre-Deployment Checklist

### Prerequisites
- [ ] AWS account (for ECS) OR Kubernetes cluster configured
- [ ] Docker installed (for Docker Compose option)
- [ ] GitHub account (for CI/CD)
- [ ] OpenRouter API key obtained
- [ ] Domain name registered (for production)

### Infrastructure Decisions
- [ ] Choose deployment target (ECS/K8s/Docker Compose)
- [ ] Determine environment (dev/staging/prod)
- [ ] Plan for high availability requirements
- [ ] Define monitoring and alerting needs
- [ ] Setup backup and disaster recovery strategy

### Configuration
- [ ] Review and update `deployment/.env.production`
- [ ] Configure database connection strings
- [ ] Setup email/Slack notifications
- [ ] Generate SSL certificates
- [ ] Configure custom domain names

### Security
- [ ] Rotate API keys before deployment
- [ ] Setup AWS Secrets Manager or equivalent
- [ ] Configure VPC security groups/network policies
- [ ] Enable container image scanning
- [ ] Setup audit logging

---

## 🏗️ Deployment Architecture

```
┌─────────────────────────────────────────────────────┐
│                  CDN / Load Balancer                 │
│                   (CloudFront / ALB)                 │
└────────────┬────────────────────────────┬────────────┘
             │                            │
    ┌────────▼──────────┐        ┌────────▼──────────┐
    │   Frontend (2-10)  │        │  Backend (2-20)   │
    │   Next.js + React  │        │   FastAPI + Crew  │
    │   256m/512MB RAM   │        │   1024m/2GB RAM   │
    └────────┬──────────┘        └────────┬──────────┘
             │                            │
    ┌────────▼────────────────────────────▼──────────┐
    │          Shared Storage (EFS/PVC)              │
    │       Work Directory + Build Artifacts        │
    └────────────────────────────────────────────────┘
             │              │              │
    ┌────────▼──┐   ┌───────▼──┐   ┌──────▼────┐
    │  Monitor  │   │   Log    │   │  Secrets  │
    │ (Prom/CW) │   │(CW/Stack)│   │ (Manager) │
    └───────────┘   └──────────┘   └───────────┘
```

---

## 📦 Deployment Files Overview

| File | Purpose | Target |
|------|---------|--------|
| `aws-ecs-terraform.tf` | Infrastructure as Code | AWS ECS |
| `kubernetes-manifests.yaml` | Kubernetes configuration | Kubernetes |
| `github-actions-workflows.yaml` | CI/CD pipeline | GitHub Actions |
| `deployment-configuration.md` | Setup scripts & env vars | All |
| `PRODUCTION_DEPLOYMENT.md` | Step-by-step procedures | All |
| `README-DEPLOYMENT.md` | Quick reference guide | All |

---

## 🔐 Secure API Key Handling

### Frontend
```javascript
// 1. User enters OpenRouter API key
// 2. Transmitted to backend via HTTPS POST
// 3. Backend validates and stores in Secrets Manager
// 4. Frontend receives auth token
// 5. All LLM calls use backend (key never exposed)
```

### Backend Configuration
```python
# Initialize with user's OpenRouter key
client = openai.AsyncClient(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1"
)
```

---

## 🔄 CI/CD Pipeline Setup

### 1. Connect GitHub Repository
```bash
git remote add origin https://github.com/your-org/OpenDevAgent.git
git push -u origin main
```

### 2. Configure GitHub Secrets
```
OPENROUTER_API_KEY          # Your OpenRouter API key
AWS_ACCESS_KEY_ID           # AWS credentials (for ECS)
AWS_SECRET_ACCESS_KEY
ECR_REPOSITORY_BACKEND      # ECR repo names
ECR_REPOSITORY_FRONTEND
KUBERNETES_CONFIG           # K8s config (for K8s deployments)
SLACK_WEBHOOK_URL           # Notifications
```

### 3. Workflow Triggers
- **Push to main**: Deploy to staging
- **Tag release (v1.0.0)**: Deploy to production
- **Pull requests**: Run tests & security scans
- **Schedule**: Daily backups & health checks

---

## ⚙️ Environment Configuration

### Required Variables (AWS ECS)
```env
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012
AWS_ENVIRONMENT=production

# Application
OPENROUTER_API_KEY=sk_live_...
DATABASE_URL=postgresql://...
REDIS_URL=redis://...

# Deployment
BACKEND_REPLICAS=3
FRONTEND_REPLICAS=2
BACKEND_CPU=1024
BACKEND_MEMORY=2048
FRONTEND_CPU=256
FRONTEND_MEMORY=512

# Monitoring
ENABLE_CLOUDWATCH=true
ENABLE_JAEGER=true
LOG_LEVEL=info
```

### Required Variables (Kubernetes)
```env
# K8s Configuration
KUBE_CONTEXT=production
KUBE_NAMESPACE=opendevagent
IMAGE_REGISTRY=ghcr.io/your-org

# Application (same as ECS)
OPENROUTER_API_KEY=sk_live_...
# ... other vars
```

---

## 🚨 Monitoring & Alerts

### Key Metrics to Monitor
- **API Response Time**: < 2 seconds
- **CPU Usage**: < 70%
- **Memory Usage**: < 80%
- **Error Rate**: < 0.1%
- **Task Success Rate**: > 99%

### Setup Alerts
```bash
# AWS CloudWatch
aws cloudwatch put-metric-alarm \
  --alarm-name backend-high-cpu \
  --metric-name CPUUtilization \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold

# Kubernetes
kubectl apply -f deployment/monitoring/prometheus-rules.yaml
```

---

## 🔄 Scaling & Performance

### Auto-Scaling Rules

**Backend Service:**
- Min: 2 pods | Max: 20 pods
- CPU target: 70% utilization
- Memory target: 80% utilization

**Frontend Service:**
- Min: 2 pods | Max: 10 pods
- CPU target: 70% utilization

### Performance Baseline
- **Throughput**: 100+ requests/second
- **P99 Latency**: 500ms
- **Error Rate**: < 0.1%
- **Availability**: 99.9%

---

## 🔧 Troubleshooting

### Issue: Pods failing to start
```bash
# Check logs
kubectl logs <pod-name> -n opendevagent

# Check events
kubectl describe pod <pod-name> -n opendevagent

# Verify resources
kubectl top nodes
kubectl top pods -n opendevagent
```

### Issue: High latency
```bash
# Check service endpoints
kubectl get endpoints -n opendevagent

# Test connectivity
kubectl exec -it <pod> -- curl http://backend:8000/health

# Check load balancer
aws elbv2 describe-load-balancers
```

### Issue: Memory leaks
```bash
# Monitor memory over time
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes | jq

# Check for resource limits
kubectl describe deployment backend -n opendevagent
```

---

## 📊 Disaster Recovery

### Backup Strategy
- **Frequency**: Hourly
- **Retention**: 30 days
- **Location**: S3 / Backup storage
- **Automation**: Automated via CI/CD

### Recovery Time Objectives
- **RTO (Recovery Time)**: 4 hours
- **RPO (Recovery Point)**: 1 hour
- **Backup Restore**: Tested monthly

### Failover Procedure
```bash
# 1. Verify backup integrity
aws s3 sync s3://opendevagent-backups /tmp/verify --dry-run

# 2. Restore database
psql -h new-endpoint < backup.sql

# 3. Restore EFS
# Mount backup volume and copy data

# 4. Update DNS/Load Balancer
# Point traffic to new infrastructure

# 5. Verify application
curl https://api.opendevagent.com/health
```

---

## 📚 Additional Resources

- **Full Deployment Guide**: See `PRODUCTION_DEPLOYMENT.md`
- **Configuration Reference**: See `deployment-configuration.md`
- **Architecture Details**: See `README-DEPLOYMENT.md`
- **GitHub Actions Setup**: See `github-actions-workflows.yaml`

---

## 🎯 Next Steps

1. **Choose your deployment platform** (AWS ECS, Kubernetes, or Docker Compose)
2. **Prepare your environment** (API keys, domains, SSL certificates)
3. **Follow the Quick Start** for your chosen platform
4. **Setup monitoring and alerting**
5. **Configure backup and disaster recovery**
6. **Run smoke tests** to verify deployment
7. **Monitor production** and adjust as needed

---

## 💬 Support & Questions

- **Documentation**: Check `deployment/` folder
- **Issues**: GitHub Issues repository
- **Community**: GitHub Discussions
- **Security**: See SECURITY.md for responsible disclosure

**Status**: ✅ Production Ready | Last Updated: 2024
