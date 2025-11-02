# Production Deployment Guide

## deployment/PRODUCTION_DEPLOYMENT.md

```markdown
# OpenDevAgent Production Deployment Guide

## Pre-Deployment Checklist

### Infrastructure Setup
- [ ] AWS Account created and configured
- [ ] IAM roles and policies set up
- [ ] VPC created with proper subnets
- [ ] Security groups configured
- [ ] Load balancers created
- [ ] SSL certificates provisioned
- [ ] Database initialized

### Application Preparation
- [ ] Code reviewed and tested
- [ ] Version tag created (e.g., v1.0.0)
- [ ] Docker images built and pushed
- [ ] Docker images scanned for vulnerabilities
- [ ] Configuration files updated
- [ ] Environment variables configured

### Deployment Verification
- [ ] Health checks configured
- [ ] Monitoring alerts set up
- [ ] Logging configured
- [ ] Backup procedures tested
- [ ] Rollback procedure tested
- [ ] Team notified of deployment window

## AWS ECS Deployment

### Step 1: Initialize Terraform State

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket opendevagent-tf-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket opendevagent-tf-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locks
aws dynamodb create-table \
  --table-name opendevagent-tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### Step 2: Plan Deployment

```bash
cd deployment/terraform

terraform init \
  -backend-config="bucket=opendevagent-tf-state" \
  -backend-config="key=prod/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=opendevagent-tf-locks"

terraform plan \
  -var-file="environments/prod.tfvars" \
  -out=tfplan

# Review plan output
terraform show tfplan
```

### Step 3: Apply Deployment

```bash
# Apply configuration
terraform apply tfplan

# Get outputs
terraform output -json > outputs.json

# Store outputs for reference
cat outputs.json
```

### Step 4: Configure ECS Services

```bash
# Set API key in Secrets Manager
aws secretsmanager put-secret-value \
  --secret-id opendevagent/openrouter-key-prod \
  --secret-string "sk-or-v1-YOUR-KEY-HERE"

# Update ECS task definitions
aws ecs register-task-definition \
  --cli-input-json file://ecs-task-definition-backend.json

aws ecs register-task-definition \
  --cli-input-json file://ecs-task-definition-frontend.json

# Update ECS services
aws ecs update-service \
  --cluster opendevagent-prod \
  --service opendevagent-backend \
  --task-definition opendevagent-backend-prod:LATEST \
  --force-new-deployment

aws ecs update-service \
  --cluster opendevagent-prod \
  --service opendevagent-frontend \
  --task-definition opendevagent-frontend-prod:LATEST \
  --force-new-deployment
```

### Step 5: Verify Deployment

```bash
# Check service status
aws ecs describe-services \
  --cluster opendevagent-prod \
  --services opendevagent-backend opendevagent-frontend

# Check task status
aws ecs list-tasks \
  --cluster opendevagent-prod \
  --service-name opendevagent-backend

# Check CloudWatch logs
aws logs tail /ecs/opendevagent-prod --follow
```

## Kubernetes Deployment

### Step 1: Prepare Kubernetes Cluster

```bash
# Create namespace
kubectl create namespace opendevagent-prod
kubectl label namespace opendevagent-prod \
  name=opendevagent-prod \
  monitoring=enabled

# Install prerequisites
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/instance=cert-manager \
  -n cert-manager \
  --timeout=120s
```

### Step 2: Create Secrets

```bash
# Create Kubernetes secrets from environment variables
kubectl create secret generic opendevagent-secrets \
  --from-literal=openrouter-api-key="sk-or-v1-YOUR-KEY-HERE" \
  -n opendevagent-prod

# Verify secret creation
kubectl get secrets -n opendevagent-prod
```

### Step 3: Deploy Storage

```bash
# Create storage class
kubectl apply -f kubernetes/storage-class.yaml

# Create persistent volume claim
kubectl apply -f kubernetes/pvc.yaml

# Verify PVC is bound
kubectl get pvc -n opendevagent-prod
```

### Step 4: Deploy Applications

```bash
# Apply configurations
kubectl apply -f kubernetes/configmap.yaml

# Apply RBAC
kubectl apply -f kubernetes/rbac.yaml

# Deploy backend
kubectl apply -f kubernetes/backend-deployment.yaml
kubectl apply -f kubernetes/backend-service.yaml

# Deploy frontend
kubectl apply -f kubernetes/frontend-deployment.yaml
kubectl apply -f kubernetes/frontend-service.yaml

# Deploy HPA
kubectl apply -f kubernetes/hpa.yaml

# Deploy network policies
kubectl apply -f kubernetes/networkpolicy.yaml

# Deploy ingress
kubectl apply -f kubernetes/ingress.yaml
```

### Step 5: Monitor Rollout

```bash
# Watch deployment rollout
kubectl rollout status deployment/opendevagent-backend \
  -n opendevagent-prod \
  --timeout=600s

kubectl rollout status deployment/opendevagent-frontend \
  -n opendevagent-prod \
  --timeout=600s

# Check pod status
kubectl get pods -n opendevagent-prod -w

# Check services
kubectl get svc -n opendevagent-prod

# Check ingress
kubectl get ingress -n opendevagent-prod
```

## Health Checks and Verification

### API Health Check

```bash
# Backend health check
curl https://api.opendevagent.com/health

# Expected response:
# {"status":"healthy","service":"OpenDevAgent Backend"}
```

### Database Connectivity

```bash
# Check backend pod logs
kubectl logs -n opendevagent-prod \
  -l component=backend \
  --tail=50 | grep -i "database\|connection"

# Check for errors
kubectl logs -n opendevagent-prod \
  -l component=backend \
  --tail=50 | grep -i "error\|exception"
```

### Load Testing

```bash
# Install k6
brew install k6  # macOS
# or download from https://k6.io/open-source

# Run load test
k6 run deployment/k6-test.js \
  --vus 100 \
  --duration 5m \
  -e API_URL=https://api.opendevagent.com
```

## Monitoring and Alerting

### CloudWatch Metrics

```bash
# Get CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=opendevagent-backend \
                Name=ClusterName,Value=opendevagent-prod \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z \
  --period 300 \
  --statistics Average

# Get memory utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ServiceName,Value=opendevagent-backend \
                Name=ClusterName,Value=opendevagent-prod \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z \
  --period 300 \
  --statistics Average
```

### Kubernetes Metrics

```bash
# Install metrics-server (if not present)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View pod metrics
kubectl top pods -n opendevagent-prod

# View node metrics
kubectl top nodes
```

## Rollback Procedures

### ECS Rollback

```bash
# List previous task definitions
aws ecs list-task-definitions \
  --family-prefix opendevagent-backend-prod \
  --sort DESC

# Revert to previous task definition
aws ecs update-service \
  --cluster opendevagent-prod \
  --service opendevagent-backend \
  --task-definition opendevagent-backend-prod:PREVIOUS \
  --force-new-deployment

# Wait for rollback to complete
aws ecs wait services-stable \
  --cluster opendevagent-prod \
  --services opendevagent-backend
```

### Kubernetes Rollback

```bash
# View rollout history
kubectl rollout history deployment/opendevagent-backend \
  -n opendevagent-prod

# Rollback to previous revision
kubectl rollout undo deployment/opendevagent-backend \
  -n opendevagent-prod

# Verify rollback
kubectl rollout status deployment/opendevagent-backend \
  -n opendevagent-prod
```

## Disaster Recovery

### Backup Strategy

```bash
# Backup EFS
aws backup start-backup-job \
  --backup-vault-name opendevagent-vault \
  --resource-arn arn:aws:elasticfilesystem:us-east-1:ACCOUNT_ID:file-system/FILESYSTEM_ID \
  --iam-role-arn arn:aws:iam::ACCOUNT_ID:role/AWSBackupRole

# Backup RDS (if using)
aws rds create-db-snapshot \
  --db-instance-identifier opendevagent-db \
  --db-snapshot-identifier opendevagent-db-backup-$(date +%Y%m%d)

# List backups
aws backup list-backup-jobs \
  --by-account-id ACCOUNT_ID
```

### Restore Procedure

```bash
# Restore EFS
aws backup start-restore-job \
  --recovery-point-arn arn:aws:backup:us-east-1:ACCOUNT_ID:recovery-point:RECOVERY_POINT_ID \
  --iam-role-arn arn:aws:iam::ACCOUNT_ID:role/AWSBackupRole

# Restore from RDS snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier opendevagent-db-restored \
  --db-snapshot-identifier opendevagent-db-backup-20240101

# Verify restoration
aws rds describe-db-instances \
  --db-instance-identifier opendevagent-db-restored
```

## Post-Deployment

### Smoke Tests

```bash
#!/bin/bash
set -e

API_URL="https://api.opendevagent.com"
APP_URL="https://app.opendevagent.com"

echo "Running post-deployment smoke tests..."

# Test API health
echo "Testing API health..."
curl -f $API_URL/health || exit 1

# Test frontend accessibility
echo "Testing frontend accessibility..."
curl -f $APP_URL || exit 1

# Test API endpoints
echo "Testing task submission..."
curl -f -X POST $API_URL/api/submit_task \
  -H "Content-Type: application/json" \
  -d '{
    "task_description": "Test task",
    "target_language": "python",
    "target_framework": null,
    "openrouter_api_key": "test-key"
  }' || exit 1

echo "All smoke tests passed!"
```

### Documentation Updates

- [ ] Update deployment status dashboard
- [ ] Document any manual configuration
- [ ] Update runbooks with new endpoints
- [ ] Update capacity planning documents
- [ ] Send deployment summary to team

## Monitoring Dashboard

### Key Metrics to Monitor

1. **Application Metrics**
   - API response time
   - Error rate
   - Request throughput
   - Task completion rate

2. **Infrastructure Metrics**
   - CPU utilization
   - Memory utilization
   - Disk utilization
   - Network throughput

3. **Business Metrics**
   - Active tasks
   - Completed tasks
   - Average task duration
   - Cost per task

## Troubleshooting

### Common Issues

**Issue**: Pods not starting
**Solution**:
```bash
kubectl describe pod POD_NAME -n opendevagent-prod
kubectl logs POD_NAME -n opendevagent-prod
```

**Issue**: High CPU usage
**Solution**:
```bash
kubectl top pods -n opendevagent-prod
kubectl get hpa -n opendevagent-prod
```

**Issue**: No connectivity to backend
**Solution**:
```bash
kubectl logs -n opendevagent-prod -l component=backend
kubectl get svc -n opendevagent-prod
```

## Support Contacts

- DevOps Team: devops@example.com
- On-Call: oncall@example.com
- Escalation: engineering-manager@example.com
```

## deployment/LOAD_TESTING.md

```markdown
# Load Testing Guide

## K6 Load Test Script

```javascript
// deployment/k6-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  vus: 100,
  duration: '5m',
  stages: [
    { duration: '1m', target: 20 },
    { duration: '2m', target: 100 },
    { duration: '1m', target: 50 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000', 'p(99)<2000'],
    http_req_failed: ['rate<0.1'],
  },
};

export default function() {
  // Test health check
  let res = http.get(__ENV.API_URL + '/health');
  check(res, {
    'health status is 200': (r) => r.status === 200,
  });
  sleep(1);

  // Test task submission
  res = http.post(__ENV.API_URL + '/api/submit_task', JSON.stringify({
    task_description: 'Test task',
    target_language: 'python',
    target_framework: null,
    openrouter_api_key: 'test-key',
  }), {
    headers: { 'Content-Type': 'application/json' },
  });
  check(res, {
    'submit task status is 202': (r) => r.status === 202,
  });
  sleep(1);
}
```

## Running Tests

```bash
# Run with cloud collection
k6 run deployment/k6-test.js \
  --vus 100 \
  --duration 5m \
  -e API_URL=https://api.opendevagent.com \
  --cloud

# Run locally
k6 run deployment/k6-test.js \
  -e API_URL=http://localhost:8000 \
  --out json=results.json
```
```

## deployment/MONITORING_SETUP.md

```markdown
# Monitoring and Observability Setup

## Prometheus Configuration

```yaml
# deployment/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
- job_name: 'backend'
  kubernetes_sd_configs:
  - role: pod
    namespaces:
      names:
      - opendevagent-prod
  relabel_configs:
  - source_labels: [__meta_kubernetes_pod_label_component]
    action: keep
    regex: backend
  - source_labels: [__meta_kubernetes_pod_ip]
    action: replace
    target_label: __address__
    regex: ([^:]+)(?::\d+)?
    replacement: ${1}:8000

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - alertmanager:9093
```

## Alert Rules

```yaml
# deployment/alert-rules.yml
groups:
- name: opendevagent
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
    for: 5m
    annotations:
      summary: "High error rate detected"
  
  - alert: HighLatency
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
    for: 5m
    annotations:
      summary: "High latency detected"
  
  - alert: PodRestarts
    expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
    for: 5m
    annotations:
      summary: "Pod restarting frequently"
```

## Grafana Dashboards

See `deployment/grafana-dashboards/` for pre-built dashboards.

## Logging Stack

### ELK Stack Configuration

```yaml
# deployment/elasticsearch-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: elasticsearch-config
  namespace: opendevagent-prod
data:
  elasticsearch.yml: |
    cluster.name: opendevagent
    node.name: ${HOSTNAME}
    discovery.seed_hosts: ["elasticsearch-0", "elasticsearch-1", "elasticsearch-2"]
    cluster.initial_master_nodes: ["elasticsearch-0", "elasticsearch-1", "elasticsearch-2"]
```

### Logstash Configuration

```conf
# deployment/logstash.conf
input {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "logstash-%{+YYYY.MM.dd}"
  }
}

filter {
  if [message] =~ /error|exception|ERROR/ {
    mutate {
      add_tag => ["error"]
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "logstash-%{+YYYY.MM.dd}"
  }
}
```
```
