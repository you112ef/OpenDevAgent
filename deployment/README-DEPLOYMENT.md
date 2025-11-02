# Deployment Quick Reference Guide

## deployment/README-DEPLOYMENT.md

```markdown
# OpenDevAgent Production Deployment

Complete production deployment guide with AWS ECS, Kubernetes, and CI/CD pipeline configuration.

## 📁 Deployment Files Overview

### Infrastructure as Code
- **aws-ecs-terraform.tf** - Complete AWS ECS infrastructure (500+ lines)
  - VPC, subnets, security groups
  - ECS cluster, services, task definitions
  - Auto-scaling configuration
  - Load balancing setup
  - IAM roles and policies

- **kubernetes-manifests.yaml** - K8s manifests (400+ lines)
  - Deployments (backend & frontend)
  - Services and ingress
  - Horizontal pod autoscaler
  - Network policies
  - RBAC configuration
  - Persistent volume claims

### CI/CD Pipeline
- **github-actions-workflows.yaml** - GitHub Actions workflows
  - Build and test pipeline
  - Docker image building
  - Security scanning
  - Performance testing
  - Deployment workflows
  - Health checks and rollback

### Configuration & Secrets
- **docker-registry-setup.sh** - ECR registry setup
- **build-and-push.sh** - Docker image build & push
- **.env.production** - Production environment variables
- **secrets-management.sh** - AWS Secrets Manager setup

### Deployment Guides
- **PRODUCTION_DEPLOYMENT.md** - Step-by-step deployment guide
- **deployment-configuration.md** - Configuration details
- **deployment-checklist.md** - Pre/post deployment checklist
- **disaster-recovery-plan.md** - DR procedures
- **performance-benchmarks.md** - Performance metrics

## 🚀 Quick Start Deployment

### AWS ECS Deployment (15-20 minutes)

```bash
# 1. Setup Terraform state
cd deployment/terraform
aws s3api create-bucket --bucket opendevagent-tf-state
aws s3api put-bucket-versioning --bucket opendevagent-tf-state --versioning-configuration Status=Enabled

# 2. Initialize and plan
terraform init
terraform plan -var-file="environments/prod.tfvars" -out=tfplan

# 3. Apply infrastructure
terraform apply tfplan

# 4. Deploy application
aws ecs update-service \
  --cluster opendevagent-prod \
  --service opendevagent-backend \
  --force-new-deployment

# 5. Verify deployment
curl https://api.opendevagent.com/health
```

### Kubernetes Deployment (10-15 minutes)

```bash
# 1. Create namespace
kubectl create namespace opendevagent-prod

# 2. Create secrets
kubectl create secret generic opendevagent-secrets \
  --from-literal=openrouter-api-key="sk-or-v1-..." \
  -n opendevagent-prod

# 3. Deploy applications
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/backend-deployment.yaml
kubectl apply -f kubernetes/frontend-deployment.yaml
kubectl apply -f kubernetes/ingress.yaml

# 4. Verify deployment
kubectl get pods -n opendevagent-prod -w
```

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│              GitHub / GitLab                       │
│  (Code Push) → GitHub Actions CI/CD Pipeline       │
└────────────────┬────────────────────────────────────┘
                 │
                 ├──→ Build Docker Images
                 ├──→ Run Tests
                 ├──→ Security Scan
                 ├──→ Push to ECR/Docker Hub
                 └──→ Deploy to Target
                      │
         ┌────────────┼────────────┐
         │            │            │
    AWS ECS    Kubernetes    Docker Compose
    (Fargate)  (Self-Hosted) (Dev/Local)
         │            │            │
    ┌────┴───┐  ┌────┴───┐    ┌──┴───┐
    │Backend │  │Backend │    │Backend│
    │Frontend│  │Frontend│    │Front. │
    │Sandbox │  │Sandbox │    │Sandbox│
    └────────┘  └────────┘    └───────┘
         │            │            │
    AWS ALB    Ingress Controller  Local LB
         │            │            │
    ┌────┴───────────────┴─────────┴─┐
    │   User / Application           │
    └────────────────────────────────┘
```

## 🔑 Key Features

### High Availability
- ✅ Multi-zone deployment
- ✅ Load balancing
- ✅ Auto-scaling (2-20 pods)
- ✅ Health checks
- ✅ Automatic recovery

### Security
- ✅ Network policies
- ✅ RBAC configuration
- ✅ Secrets management
- ✅ Encryption at rest
- ✅ Encryption in transit
- ✅ Security scanning

### Monitoring & Observability
- ✅ Prometheus metrics
- ✅ CloudWatch logging
- ✅ Jaeger tracing
- ✅ Health checks
- ✅ Alert rules

### Scalability
- ✅ Horizontal pod autoscaling
- ✅ ECS auto-scaling
- ✅ Load balancer distribution
- ✅ Database connection pooling
- ✅ Caching layer

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] Code reviewed and tested
- [ ] Version tag created
- [ ] Security scan passed
- [ ] Infrastructure validated
- [ ] Secrets configured
- [ ] Monitoring setup
- [ ] Team notified
- [ ] Backups created

### Deployment
- [ ] Build Docker images
- [ ] Push to registry
- [ ] Update infrastructure
- [ ] Deploy application
- [ ] Monitor rollout
- [ ] Run smoke tests
- [ ] Verify health checks

### Post-Deployment
- [ ] Monitor error rate
- [ ] Check performance metrics
- [ ] Verify data integrity
- [ ] Test core features
- [ ] Document deployment
- [ ] Notify stakeholders

## 🔄 CI/CD Pipeline Stages

### Build Stage
```
Code Push → Code Checkout → Lint → Test → Build
```

### Test Stage
```
Unit Tests → Integration Tests → Security Scan → Performance Test
```

### Deploy Stage
```
Build Images → Push to Registry → Deploy to Env → Health Check → Verify
```

### Rollback (if needed)
```
Trigger Rollback → Restore Previous → Verify → Monitor
```

## 📚 Files in This Directory

```
deployment/
├── README-DEPLOYMENT.md                 (This file)
├── PRODUCTION_DEPLOYMENT.md             (Step-by-step guide)
├── deployment-configuration.md          (Config details)
├── deployment-checklist.md              (Pre/post checklist)
├── disaster-recovery-plan.md            (DR procedures)
├── performance-benchmarks.md            (Metrics & benchmarks)
│
├── aws-ecs-terraform.tf                 (AWS infrastructure)
├── kubernetes-manifests.yaml            (K8s deployment)
├── github-actions-workflows.yaml        (CI/CD pipelines)
│
├── docker-registry-setup.sh             (ECR setup script)
├── build-and-push.sh                    (Build & push script)
├── secrets-management.sh                (Secrets setup)
│
├── .env.production                      (Env variables)
├── docker-compose.yml                   (Local testing)
│
└── [environments/]
    ├── prod.tfvars                      (Production config)
    ├── staging.tfvars                   (Staging config)
    └── dev.tfvars                       (Dev config)
```

## 🌐 Deployment Targets

### AWS ECS (Recommended for AWS)
- **Type**: Container orchestration (AWS-managed)
- **Scaling**: Auto-scaling groups
- **Load Balancing**: Application Load Balancer
- **Storage**: EFS for persistence
- **Monitoring**: CloudWatch native
- **Cost**: Pay-per-use (Fargate)
- **Effort**: Low (managed service)

### Kubernetes (Recommended for multi-cloud)
- **Type**: Container orchestration (open-source)
- **Scaling**: Horizontal Pod Autoscaler
- **Load Balancing**: Ingress controllers
- **Storage**: Persistent Volumes
- **Monitoring**: Prometheus/Grafana
- **Cost**: Infrastructure dependent
- **Effort**: Medium (requires management)

### Docker Compose (Development only)
- **Type**: Container orchestration (simple)
- **Scaling**: Manual or docker-compose scale
- **Load Balancing**: Local only
- **Storage**: Volume mounts
- **Monitoring**: Basic logging
- **Cost**: Free
- **Effort**: Minimal

## 🔐 Security Best Practices

### Secrets Management
```bash
# Use AWS Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id opendevagent/openrouter-api-key

# Rotate regularly
aws secretsmanager rotate-secret \
  --secret-id opendevagent/database-password \
  --rotation-rules AutomaticallyAfterDays=30
```

### Network Security
```bash
# Network policies restrict traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: opendevagent-backend-policy
spec:
  podSelector:
    matchLabels:
      component: backend
  # Only ingress from frontend and ingress-nginx
  # Only egress to frontend and external APIs
```

### Container Security
```bash
# Scan images before deployment
trivy image opendevagent-backend:latest

# Run with minimal privileges
securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
```

## 📈 Monitoring & Alerts

### Key Metrics to Monitor
- API response time (p50, p95, p99)
- Error rate (5xx errors)
- Request throughput
- CPU/Memory utilization
- Task completion rate
- Database connection count

### Alert Thresholds
| Metric | Warning | Critical |
|--------|---------|----------|
| Error Rate | > 0.5% | > 1% |
| Response Time (p95) | > 1s | > 5s |
| CPU Utilization | > 70% | > 85% |
| Memory Utilization | > 80% | > 95% |
| Pod Restarts | > 1 in 1h | > 2 in 1h |

## 🔄 Rollback Procedures

### ECS Rollback
```bash
# List previous task definitions
aws ecs list-task-definitions --family-prefix opendevagent-backend-prod --sort DESC

# Revert to previous
aws ecs update-service \
  --cluster opendevagent-prod \
  --service opendevagent-backend \
  --task-definition opendevagent-backend-prod:PREVIOUS \
  --force-new-deployment
```

### Kubernetes Rollback
```bash
# View rollout history
kubectl rollout history deployment/opendevagent-backend -n opendevagent-prod

# Rollback to previous revision
kubectl rollout undo deployment/opendevagent-backend -n opendevagent-prod
```

## 📞 Support & Troubleshooting

### Common Issues

**Pods not starting?**
```bash
kubectl describe pod POD_NAME -n opendevagent-prod
kubectl logs POD_NAME -n opendevagent-prod
```

**High CPU usage?**
```bash
kubectl top pods -n opendevagent-prod
kubectl get hpa -n opendevagent-prod
```

**Database connection issues?**
```bash
# Check backend logs
kubectl logs -l component=backend -n opendevagent-prod | grep -i database
```

## 🎓 Learning Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions](https://docs.github.com/en/actions)

## 📝 Next Steps

1. **Review** AWS ECS and Kubernetes documentation
2. **Prepare** AWS account and Kubernetes cluster
3. **Configure** Terraform variables and environment
4. **Test** deployment in staging environment
5. **Deploy** to production following checklist
6. **Monitor** deployment and system metrics
7. **Optimize** based on performance data

## Version Information

- **Deployment Suite Version**: 1.0.0
- **Last Updated**: 2024
- **Maintained By**: DevOps Team
- **Supported Platforms**: AWS, Kubernetes, Docker Compose

---

**Ready to deploy? Start with the PRODUCTION_DEPLOYMENT.md guide →**
```

## Final Summary

Let me create one comprehensive index file:
