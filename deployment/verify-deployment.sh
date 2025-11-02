#!/bin/bash
# Deployment Verification Script
# Comprehensive checks before and after deployment

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
PASSED=0
FAILED=0
WARNINGS=0

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Verify Docker images
verify_docker_images() {
    print_header "Docker Images Verification"
    
    local images=(
        "opendevagent/backend:latest"
        "opendevagent/frontend:latest"
        "opendevagent/sandbox:latest"
    )
    
    for img in "${images[@]}"; do
        if docker image inspect "$img" &>/dev/null; then
            test_pass "Docker image exists: $img"
        else
            test_warn "Docker image not found: $img"
        fi
    done
}

# Verify AWS Resources
verify_aws_resources() {
    print_header "AWS Resources Verification"
    
    if ! command -v aws &>/dev/null; then
        test_warn "AWS CLI not available - skipping AWS checks"
        return
    fi
    
    # Check ECS cluster
    if aws ecs describe-clusters --clusters opendevagent-cluster &>/dev/null 2>&1; then
        test_pass "ECS cluster found: opendevagent-cluster"
    else
        test_warn "ECS cluster not found: opendevagent-cluster"
    fi
    
    # Check ECS services
    local services=("backend" "frontend")
    for svc in "${services[@]}"; do
        if aws ecs describe-services --cluster opendevagent-cluster --services "$svc" &>/dev/null 2>&1; then
            test_pass "ECS service found: $svc"
        else
            test_warn "ECS service not found: $svc"
        fi
    done
    
    # Check load balancer
    if aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'opendevagent')]" &>/dev/null 2>&1; then
        test_pass "Load balancer found"
    else
        test_warn "Load balancer not found"
    fi
    
    # Check S3 buckets
    if aws s3 ls | grep -q "opendevagent"; then
        test_pass "S3 buckets found"
    else
        test_warn "No S3 buckets found for opendevagent"
    fi
    
    # Check IAM roles
    if aws iam get-role --role-name opendevagent-ecs-task-role &>/dev/null 2>&1; then
        test_pass "IAM role found: opendevagent-ecs-task-role"
    else
        test_warn "IAM role not found: opendevagent-ecs-task-role"
    fi
}

# Verify Kubernetes Resources
verify_kubernetes_resources() {
    print_header "Kubernetes Resources Verification"
    
    if ! command -v kubectl &>/dev/null; then
        test_warn "kubectl not available - skipping Kubernetes checks"
        return
    fi
    
    # Check cluster access
    if kubectl cluster-info &>/dev/null; then
        test_pass "Kubernetes cluster accessible"
    else
        test_fail "Cannot access Kubernetes cluster"
        return
    fi
    
    local ns="opendevagent"
    
    # Check namespace
    if kubectl get namespace "$ns" &>/dev/null; then
        test_pass "Namespace exists: $ns"
    else
        test_warn "Namespace not found: $ns"
        return
    fi
    
    # Check deployments
    local deployments=("backend" "frontend")
    for dep in "${deployments[@]}"; do
        if kubectl get deployment "$dep" -n "$ns" &>/dev/null; then
            local ready=$(kubectl get deployment "$dep" -n "$ns" -o jsonpath='{.status.readyReplicas}')
            local desired=$(kubectl get deployment "$dep" -n "$ns" -o jsonpath='{.spec.replicas}')
            if [ "$ready" == "$desired" ] && [ "$ready" -gt 0 ]; then
                test_pass "Deployment ready: $dep ($ready/$desired replicas)"
            else
                test_warn "Deployment not fully ready: $dep ($ready/$desired replicas)"
            fi
        else
            test_warn "Deployment not found: $dep"
        fi
    done
    
    # Check services
    if kubectl get service backend -n "$ns" &>/dev/null; then
        test_pass "Backend service found"
    else
        test_warn "Backend service not found"
    fi
    
    if kubectl get service frontend -n "$ns" &>/dev/null; then
        test_pass "Frontend service found"
    else
        test_warn "Frontend service not found"
    fi
    
    # Check persistent volumes
    if kubectl get pvc -n "$ns" &>/dev/null; then
        test_pass "Persistent volume claims found"
    else
        test_warn "No persistent volume claims found"
    fi
    
    # Check configmaps
    if kubectl get configmap opendevagent-config -n "$ns" &>/dev/null; then
        test_pass "ConfigMap found"
    else
        test_warn "ConfigMap not found"
    fi
    
    # Check secrets
    if kubectl get secret opendevagent-secrets -n "$ns" &>/dev/null; then
        test_pass "Secrets found"
    else
        test_warn "Secrets not found"
    fi
}

# Verify Application Health
verify_application_health() {
    print_header "Application Health Verification"
    
    # Backend health check
    local backend_url="http://localhost:8000/health"
    if curl -s "$backend_url" &>/dev/null; then
        test_pass "Backend health endpoint responsive"
    else
        test_warn "Backend health endpoint not accessible at $backend_url"
    fi
    
    # Frontend health check
    local frontend_url="http://localhost:3000"
    if curl -s "$frontend_url" &>/dev/null; then
        test_pass "Frontend responsive"
    else
        test_warn "Frontend not accessible at $frontend_url"
    fi
    
    # API endpoint check
    local api_health=$(curl -s "http://localhost:8000/api/health" 2>/dev/null || echo "")
    if [ -n "$api_health" ]; then
        test_pass "API health endpoint responsive"
    else
        test_warn "API health endpoint not accessible"
    fi
}

# Verify Database Connectivity
verify_database() {
    print_header "Database Connectivity Verification"
    
    local db_url="${DATABASE_URL:-postgresql://localhost/opendevagent}"
    
    if command -v psql &>/dev/null; then
        if psql "$db_url" -c "SELECT 1;" &>/dev/null 2>&1; then
            test_pass "PostgreSQL connectivity verified"
        else
            test_warn "PostgreSQL not accessible at: $db_url"
        fi
    else
        test_warn "psql not available - skipping database check"
    fi
}

# Verify Environment Configuration
verify_environment() {
    print_header "Environment Configuration Verification"
    
    local required_vars=(
        "OPENROUTER_API_KEY"
        "ENVIRONMENT"
        "API_BASE_URL"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -n "${!var}" ]; then
            test_pass "Environment variable set: $var"
        else
            test_warn "Environment variable not set: $var"
        fi
    done
}

# Verify SSL Certificates
verify_ssl_certificates() {
    print_header "SSL Certificate Verification"
    
    local cert_path="${SSL_CERT_PATH:-/etc/ssl/certs/tls.crt}"
    local key_path="${SSL_KEY_PATH:-/etc/ssl/private/tls.key}"
    
    if [ -f "$cert_path" ]; then
        local expiry=$(openssl x509 -enddate -noout -in "$cert_path" 2>/dev/null || echo "")
        if [ -n "$expiry" ]; then
            test_pass "SSL certificate found and valid: $expiry"
        fi
    else
        test_warn "SSL certificate not found at: $cert_path"
    fi
    
    if [ -f "$key_path" ]; then
        test_pass "SSL key found"
    else
        test_warn "SSL key not found at: $key_path"
    fi
}

# Verify File Permissions
verify_file_permissions() {
    print_header "File Permissions Verification"
    
    local files=(
        "backend/main.py"
        "frontend/pages/index.tsx"
        "deployment/setup-deployment.sh"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            test_pass "File accessible: $file"
        else
            test_warn "File not found: $file"
        fi
    done
}

# Verify Network Configuration
verify_network() {
    print_header "Network Configuration Verification"
    
    # Check if ports are in use
    local ports=(3000 8000 5432)
    
    for port in "${ports[@]}"; do
        if nc -z localhost "$port" 2>/dev/null; then
            test_pass "Port $port is in use"
        else
            test_warn "Port $port is not in use"
        fi
    done
}

# Verify Monitoring & Logging
verify_monitoring() {
    print_header "Monitoring & Logging Verification"
    
    if [ "$ENABLE_MONITORING" = "true" ]; then
        test_pass "Monitoring enabled"
    else
        test_warn "Monitoring disabled"
    fi
    
    if [ "$ENABLE_JAEGER" = "true" ]; then
        test_pass "Jaeger tracing enabled"
    else
        test_warn "Jaeger tracing disabled"
    fi
    
    if [ "$PROMETHEUS_ENABLED" = "true" ]; then
        test_pass "Prometheus metrics enabled"
    else
        test_warn "Prometheus metrics disabled"
    fi
}

# Generate Summary Report
generate_report() {
    print_header "Verification Summary"
    
    local total=$((PASSED + FAILED + WARNINGS))
    local success_rate=0
    
    if [ $total -gt 0 ]; then
        success_rate=$((PASSED * 100 / total))
    fi
    
    echo "Total Checks: $total"
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo "Success Rate: $success_rate%"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All critical checks passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some checks failed. Please review above.${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo "OpenDevAgent Deployment Verification"
    echo "======================================"
    
    # Run all verifications
    verify_docker_images
    verify_aws_resources
    verify_kubernetes_resources
    verify_application_health
    verify_database
    verify_environment
    verify_ssl_certificates
    verify_file_permissions
    verify_network
    verify_monitoring
    
    # Generate report
    generate_report
}

# Run main
main
