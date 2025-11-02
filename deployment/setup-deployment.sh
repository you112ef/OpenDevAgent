#!/bin/bash
# OpenDevAgent Deployment Setup Script
# Comprehensive setup for AWS ECS, Kubernetes, or Docker Compose deployment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Functions
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is not installed"
        return 1
    fi
    print_success "$1 is installed"
    return 0
}

# Main menu
show_menu() {
    echo -e "${BLUE}Choose deployment option:${NC}"
    echo "1) AWS ECS Deployment"
    echo "2) Kubernetes Deployment"
    echo "3) Docker Compose (Local/Dev)"
    echo "4) Setup GitHub Actions CI/CD"
    echo "5) Verify All Prerequisites"
    echo "6) Generate Configuration Files"
    echo "7) Exit"
    echo ""
    read -p "Enter your choice [1-7]: " choice
}

# Verify prerequisites
verify_prerequisites() {
    print_header "Verifying Prerequisites"
    
    local failed=0
    
    # Check for required commands
    if ! check_command docker; then
        failed=$((failed + 1))
    fi
    
    if ! check_command git; then
        failed=$((failed + 1))
    fi
    
    # Optional checks
    echo ""
    echo -e "${YELLOW}Optional tools:${NC}"
    
    if command -v aws &> /dev/null; then
        print_success "AWS CLI is installed ($(aws --version))"
    else
        print_warning "AWS CLI not installed (needed for ECS deployment)"
    fi
    
    if command -v kubectl &> /dev/null; then
        print_success "kubectl is installed ($(kubectl version --client --short 2>/dev/null || echo 'version check failed'))"
    else
        print_warning "kubectl not installed (needed for Kubernetes deployment)"
    fi
    
    if command -v terraform &> /dev/null; then
        print_success "Terraform is installed ($(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4 || echo 'version check failed'))"
    else
        print_warning "Terraform not installed (needed for ECS infrastructure setup)"
    fi
    
    if [ $failed -gt 0 ]; then
        print_error "Missing $failed required tool(s)"
        echo "Please install Docker and Git to continue"
        exit 1
    fi
    
    print_success "All required tools verified!"
}

# Setup AWS ECS
setup_ecs() {
    print_header "AWS ECS Deployment Setup"
    
    # Check prerequisites
    if ! check_command aws; then
        print_error "AWS CLI is required for ECS deployment"
        echo "Install from: https://aws.amazon.com/cli/"
        return 1
    fi
    
    if ! check_command terraform; then
        print_error "Terraform is required for ECS infrastructure setup"
        echo "Install from: https://www.terraform.io/downloads"
        return 1
    fi
    
    # Get AWS configuration
    read -p "Enter AWS Region [us-east-1]: " aws_region
    aws_region=${aws_region:-us-east-1}
    
    read -p "Enter Environment [production]: " aws_env
    aws_env=${aws_env:-production}
    
    read -p "Enter Backend Replicas [3]: " backend_replicas
    backend_replicas=${backend_replicas:-3}
    
    read -p "Enter Frontend Replicas [2]: " frontend_replicas
    frontend_replicas=${frontend_replicas:-2}
    
    # Verify AWS credentials
    print_warning "Verifying AWS credentials..."
    if aws sts get-caller-identity &> /dev/null; then
        print_success "AWS credentials verified"
        local aws_account=$(aws sts get-caller-identity --query Account --output text)
        echo "Account ID: $aws_account"
    else
        print_error "AWS credentials not configured. Run 'aws configure'"
        return 1
    fi
    
    # Create terraform.tfvars
    print_warning "Creating terraform.tfvars..."
    cat > "$SCRIPT_DIR/aws-ecs/terraform.tfvars" << EOF
aws_region            = "$aws_region"
environment           = "$aws_env"
backend_replicas      = $backend_replicas
frontend_replicas     = $frontend_replicas
backend_cpu           = 1024
backend_memory        = 2048
frontend_cpu          = 256
frontend_memory       = 512
enable_monitoring     = true
enable_autoscaling    = true
EOF
    print_success "terraform.tfvars created"
    
    # Initialize Terraform
    print_warning "Initializing Terraform..."
    cd "$SCRIPT_DIR/aws-ecs" || return 1
    terraform init
    
    print_success "AWS ECS setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Review terraform.tfvars"
    echo "2. Run: terraform plan"
    echo "3. Review and run: terraform apply"
    echo ""
    cd - > /dev/null
}

# Setup Kubernetes
setup_kubernetes() {
    print_header "Kubernetes Deployment Setup"
    
    if ! check_command kubectl; then
        print_error "kubectl is required for Kubernetes deployment"
        echo "Install from: https://kubernetes.io/docs/tasks/tools/"
        return 1
    fi
    
    # Verify cluster access
    print_warning "Verifying Kubernetes cluster access..."
    if kubectl cluster-info &> /dev/null; then
        print_success "Kubernetes cluster accessible"
        kubectl cluster-info
    else
        print_error "Cannot connect to Kubernetes cluster"
        echo "Ensure KUBECONFIG is set or kubectl is configured"
        return 1
    fi
    
    read -p "Enter Kubernetes Namespace [opendevagent]: " k8s_namespace
    k8s_namespace=${k8s_namespace:-opendevagent}
    
    read -p "Enter Docker Registry [ghcr.io/your-org]: " docker_registry
    docker_registry=${docker_registry:-ghcr.io/your-org}
    
    read -sp "Enter OpenRouter API Key: " openrouter_key
    echo ""
    
    # Create namespace
    print_warning "Creating Kubernetes namespace..."
    kubectl create namespace "$k8s_namespace" 2>/dev/null || print_warning "Namespace already exists"
    print_success "Namespace '$k8s_namespace' ready"
    
    # Create secrets
    print_warning "Creating secrets..."
    kubectl create secret generic opendevagent-secrets \
        --from-literal=openrouter_api_key="$openrouter_key" \
        -n "$k8s_namespace" \
        --dry-run=client -o yaml | kubectl apply -f -
    print_success "Secrets created"
    
    # Update manifests with namespace
    print_warning "Updating manifests..."
    sed -i "s/namespace: opendevagent/namespace: $k8s_namespace/g" "$SCRIPT_DIR/kubernetes-manifests.yaml"
    sed -i "s|image: ghcr.io/your-org|image: $docker_registry|g" "$SCRIPT_DIR/kubernetes-manifests.yaml"
    print_success "Manifests updated"
    
    print_success "Kubernetes setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Build and push Docker images to $docker_registry"
    echo "2. Update image tags in kubernetes-manifests.yaml"
    echo "3. Run: kubectl apply -f kubernetes-manifests.yaml"
    echo "4. Verify: kubectl get pods -n $k8s_namespace"
    echo ""
}

# Setup Docker Compose
setup_docker_compose() {
    print_header "Docker Compose Setup (Local/Development)"
    
    read -sp "Enter OpenRouter API Key: " openrouter_key
    echo ""
    
    # Create .env file
    print_warning "Creating .env file..."
    cat > "$PROJECT_ROOT/.env" << EOF
# OpenDevAgent Environment Configuration

# OpenRouter API
OPENROUTER_API_KEY=$openrouter_key

# Backend Configuration
BACKEND_PORT=8000
BACKEND_LOG_LEVEL=info
BACKEND_WORKERS=4

# Frontend Configuration
FRONTEND_PORT=3000
NEXT_PUBLIC_API_URL=http://localhost:8000

# Database (optional)
DATABASE_URL=postgresql://user:password@db:5432/opendevagent
REDIS_URL=redis://redis:6379/0

# Sandbox Configuration
SANDBOX_TIMEOUT=60
SANDBOX_MAX_MEMORY=2048

# Development
DEBUG=true
EOF
    
    print_success ".env file created"
    
    # Create docker-compose override for development
    print_warning "Creating docker-compose.override.yml..."
    cat > "$PROJECT_ROOT/docker-compose.override.yml" << 'EOF'
version: '3.8'

services:
  backend:
    environment:
      - DEBUG=true
      - LOG_LEVEL=debug
    volumes:
      - ./backend:/app/backend
    ports:
      - "8000:8000"

  frontend:
    environment:
      - NODE_ENV=development
    volumes:
      - ./frontend:/app/frontend
    ports:
      - "3000:3000"
EOF
    
    print_success "docker-compose.override.yml created"
    
    print_success "Docker Compose setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Review .env file and update if needed"
    echo "2. Run: docker-compose up -d"
    echo "3. Access: http://localhost:3000 (Frontend)"
    echo "4. Access: http://localhost:8000 (Backend)"
    echo "5. Monitor: docker-compose logs -f"
    echo ""
}

# Setup GitHub Actions
setup_github_actions() {
    print_header "GitHub Actions CI/CD Setup"
    
    if ! check_command git; then
        print_error "Git is required for GitHub setup"
        return 1
    fi
    
    # Check if in git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        echo "Run 'git init' first"
        return 1
    fi
    
    read -p "Enter GitHub Repository URL: " github_repo
    read -p "Enter GitHub Organization/Username: " github_org
    read -sp "Enter OpenRouter API Key: " openrouter_key
    echo ""
    
    # Create .github/workflows directory
    print_warning "Creating workflows directory..."
    mkdir -p "$PROJECT_ROOT/.github/workflows"
    print_success "Workflows directory created"
    
    # Copy workflow file
    print_warning "Setting up CI/CD workflows..."
    if [ -f "$SCRIPT_DIR/github-actions-workflows.yaml" ]; then
        cp "$SCRIPT_DIR/github-actions-workflows.yaml" "$PROJECT_ROOT/.github/workflows/ci-cd.yml"
        print_success "Workflows configured"
    fi
    
    # Create workflow for secrets setup
    cat > "$PROJECT_ROOT/.github/SECRETS_SETUP.md" << EOF
# GitHub Actions Secrets Setup

Add these secrets to your GitHub repository:
Settings > Secrets and variables > Actions > New repository secret

## Required Secrets

1. **OPENROUTER_API_KEY**
   - Value: Your OpenRouter API key
   - Used for: LLM calls

2. **AWS_ACCESS_KEY_ID** (for ECS deployment)
   - Value: Your AWS access key

3. **AWS_SECRET_ACCESS_KEY** (for ECS deployment)
   - Value: Your AWS secret key

4. **KUBERNETES_CONFIG** (for K8s deployment)
   - Value: Your kubeconfig file contents (base64 encoded)

## Setup Commands

\`\`\`bash
# Add OpenRouter key
gh secret set OPENROUTER_API_KEY --body "\$OPENROUTER_KEY"

# Add AWS credentials (for ECS)
gh secret set AWS_ACCESS_KEY_ID --body "\$AWS_ACCESS_KEY_ID"
gh secret set AWS_SECRET_ACCESS_KEY --body "\$AWS_SECRET_ACCESS_KEY"

# Add Kubernetes config (for K8s)
gh secret set KUBERNETES_CONFIG --body "\$(base64 ~/.kube/config | tr -d '\\n')"
\`\`\`

## Workflow Triggers

- **Push to main**: Runs tests, builds, deploys to staging
- **Pull request**: Runs tests and security scans
- **Tag release (v*)**: Builds and deploys to production
- **Schedule**: Daily health checks and backups

EOF
    
    print_success "Secrets setup guide created"
    
    print_success "GitHub Actions setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Push to GitHub: git push -u origin main"
    echo "2. Follow: .github/SECRETS_SETUP.md"
    echo "3. Add required secrets to GitHub"
    echo "4. Monitor: Actions tab in GitHub"
    echo ""
}

# Generate configuration
generate_config() {
    print_header "Generate Configuration Files"
    
    read -p "Enter Environment Name [production]: " env_name
    env_name=${env_name:-production}
    
    read -p "Enter Domain Name [api.example.com]: " domain_name
    domain_name=${domain_name:-api.example.com}
    
    read -p "Enter AWS Region [us-east-1]: " aws_region
    aws_region=${aws_region:-us-east-1}
    
    read -sp "Enter OpenRouter API Key: " openrouter_key
    echo ""
    
    # Generate comprehensive .env.${env_name} file
    print_warning "Generating .env.$env_name..."
    cat > "$SCRIPT_DIR/.env.$env_name" << EOF
# OpenDevAgent Environment: $env_name
# Generated on $(date)

# Application
APP_NAME=OpenDevAgent
ENVIRONMENT=$env_name
DEBUG=false

# API & Domain
API_BASE_URL=https://$domain_name
API_PORT=8000
FRONTEND_PORT=3000

# OpenRouter Configuration
OPENROUTER_API_KEY=$openrouter_key
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1

# Backend Configuration
BACKEND_WORKERS=4
LOG_LEVEL=info
REQUEST_TIMEOUT=300
MAX_RETRIES=3

# Frontend Configuration
NEXT_PUBLIC_API_URL=https://$domain_name/api
NEXT_PUBLIC_LOG_LEVEL=info

# Database Configuration
DATABASE_URL=postgresql://user:password@db.example.com:5432/opendevagent
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=40

# Cache Configuration
REDIS_URL=redis://cache.example.com:6379/0
CACHE_TTL=3600

# AWS Configuration (for ECS/S3)
AWS_REGION=$aws_region
AWS_ACCESS_KEY_ID=your_key_here
AWS_SECRET_ACCESS_KEY=your_secret_here
AWS_ACCOUNT_ID=123456789012

# ECS Configuration
ECS_CLUSTER_NAME=opendevagent-cluster
ECS_TASK_DEFINITION=opendevagent-task
ECS_SERVICE_NAME=opendevagent-service

# Kubernetes Configuration
KUBE_NAMESPACE=opendevagent
KUBE_CONTEXT=production
IMAGE_REGISTRY=ghcr.io/your-org

# Sandbox Configuration
SANDBOX_TIMEOUT=60
SANDBOX_MAX_MEMORY=2048
SANDBOX_MAX_CPU=1000
SANDBOX_IMAGE=opendevagent/sandbox:latest

# Monitoring & Logging
ENABLE_MONITORING=true
ENABLE_JAEGER=true
JAEGER_COLLECTOR_URL=http://jaeger-collector:14268/api/traces
PROMETHEUS_ENABLED=true
PROMETHEUS_PORT=9090

# CloudWatch Configuration
CLOUDWATCH_ENABLED=true
CLOUDWATCH_LOG_GROUP=/opendevagent/$env_name
CLOUDWATCH_REGION=$aws_region

# Notification Configuration
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
EMAIL_NOTIFICATIONS_ENABLED=true
SMTP_SERVER=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your_email@example.com
SMTP_PASSWORD=your_password

# Security Configuration
ENABLE_SSL=true
SSL_CERT_PATH=/etc/ssl/certs/tls.crt
SSL_KEY_PATH=/etc/ssl/private/tls.key
CORS_ORIGINS=https://$domain_name
SESSION_SECRET=generate_secure_random_string_here

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 * * * *
BACKUP_RETENTION_DAYS=30
BACKUP_S3_BUCKET=opendevagent-backups-$env_name
BACKUP_S3_PREFIX=$env_name/

# Feature Flags
FEATURE_CODE_GENERATION=true
FEATURE_AUTO_FIX=true
FEATURE_MULTI_LANGUAGE=true
FEATURE_TEAM_COLLABORATION=false

# Version
VERSION=1.0.0
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
    
    print_success ".env.$env_name generated"
    
    # Generate Kubernetes ConfigMap template
    print_warning "Generating Kubernetes ConfigMap..."
    cat > "$SCRIPT_DIR/k8s-configmap.yaml" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: opendevagent-config
  namespace: opendevagent
data:
  environment: "$env_name"
  api-base-url: "https://$domain_name"
  backend-workers: "4"
  log-level: "info"
  sandbox-timeout: "60"
  sandbox-max-memory: "2048"
  prometheus-enabled: "true"
  jaeger-enabled: "true"
  monitoring-enabled: "true"
EOF
    
    print_success "Kubernetes ConfigMap template generated"
    
    print_success "Configuration files generated!"
    echo ""
    echo "Generated files:"
    echo "- .env.$env_name (Main environment variables)"
    echo "- k8s-configmap.yaml (Kubernetes configuration)"
    echo ""
    echo "⚠️  Security Notice:"
    echo "- Replace placeholder values with real values"
    echo "- Add .env.$env_name to .gitignore"
    echo "- Store sensitive values in Secrets Manager"
    echo ""
}

# Main loop
main() {
    clear
    print_header "OpenDevAgent Deployment Setup"
    
    while true; do
        show_menu
        
        case $choice in
            1)
                setup_ecs
                ;;
            2)
                setup_kubernetes
                ;;
            3)
                setup_docker_compose
                ;;
            4)
                setup_github_actions
                ;;
            5)
                verify_prerequisites
                ;;
            6)
                generate_config
                ;;
            7)
                print_success "Deployment setup completed!"
                echo "For detailed instructions, see deployment/DEPLOY.md"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                ;;
        esac
        
        read -p "Press Enter to continue..."
    done
}

# Run main
main
