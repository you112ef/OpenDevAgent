#!/bin/bash
# 🚀 OpenDevAgent - Vercel Deployment Script (Automated)
# Run this script to deploy to Vercel automatically

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

print_step() {
    echo -e "\n${YELLOW}→${NC} $1"
}

# Start
print_header "🚀 OpenDevAgent Vercel Deployment"

# Step 1: Check prerequisites
print_step "Checking prerequisites..."

if ! command -v node &> /dev/null; then
    print_error "Node.js not installed"
    echo "Install from: https://nodejs.org/"
    exit 1
fi
print_success "Node.js installed ($(node --version))"

if ! command -v npm &> /dev/null; then
    print_error "npm not installed"
    exit 1
fi
print_success "npm installed ($(npm --version))"

if ! command -v git &> /dev/null; then
    print_error "Git not installed"
    exit 1
fi
print_success "Git installed ($(git --version | head -n1))"

# Step 2: Navigate to project
print_step "Navigating to project directory..."
cd /project/workspace/OpenDevAgent_KiloInspired
print_success "In project directory: $(pwd)"

# Step 3: Initialize git if needed
print_step "Setting up Git repository..."
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_step "Initializing new Git repository..."
    git init
    git add .
    git commit -m "Initial commit: OpenDevAgent ready for Vercel deployment"
    print_success "Git repository initialized"
else
    print_success "Git repository already exists"
    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        print_step "Committing local changes..."
        git add .
        git commit -m "Update: OpenDevAgent deployment ready"
    fi
fi

# Step 4: Install Vercel CLI
print_step "Installing Vercel CLI..."
if ! command -v vercel &> /dev/null; then
    npm install -g vercel
    print_success "Vercel CLI installed"
else
    print_success "Vercel CLI already installed ($(vercel --version))"
fi

# Step 5: Check if already logged in
print_step "Checking Vercel authentication..."
if vercel whoami &> /dev/null; then
    VERCEL_USER=$(vercel whoami)
    print_success "Already logged in as: $VERCEL_USER"
else
    print_step "Please login to Vercel in your browser..."
    vercel login
    print_success "Logged in successfully"
fi

# Step 6: Test local build
print_step "Testing frontend build locally..."
cd frontend
npm install
npm run build
print_success "Frontend builds successfully"
cd ..

# Step 7: Deploy to Vercel
print_step "Deploying to Vercel..."
vercel --prod

# Step 8: Add environment variables
print_header "⚙️ Environment Variables"

echo -e "${YELLOW}Enter your environment variables:${NC}\n"

read -p "Enter OpenRouter API Key (sk_live_...): " OPENROUTER_KEY
read -p "Enter Backend API URL (leave empty to skip): " API_URL

if [ -n "$OPENROUTER_KEY" ]; then
    print_step "Adding OPENROUTER_API_KEY..."
    vercel env add OPENROUTER_API_KEY <<< "$OPENROUTER_KEY"
    print_success "Environment variable added"
fi

if [ -n "$API_URL" ]; then
    print_step "Adding NEXT_PUBLIC_API_URL..."
    vercel env add NEXT_PUBLIC_API_URL <<< "$API_URL"
    print_success "Environment variable added"
fi

# Step 9: Redeploy with env vars
print_step "Redeploying with environment variables..."
vercel --prod

# Step 10: Show deployment info
print_header "✅ Deployment Complete!"

echo -e "${GREEN}Your application is now live!${NC}\n"

# Get project info
DEPLOYMENT_URL=$(vercel ls --json | grep -o '"url":"[^"]*' | head -1 | cut -d'"' -f4)

echo -e "📊 ${BLUE}Deployment Information:${NC}"
echo "Frontend URL: https://$DEPLOYMENT_URL"
echo ""

# Show next steps
echo -e "📝 ${BLUE}Next Steps:${NC}"
echo "1. Open: https://$DEPLOYMENT_URL"
echo "2. Test the application"
echo "3. For automatic deployments on git push:"
echo "   git push origin main"
echo ""

echo -e "📚 ${BLUE}Useful Commands:${NC}"
echo "  vercel ls              - Show all deployments"
echo "  vercel logs opendevagent - View deployment logs"
echo "  vercel env ls          - List environment variables"
echo "  vercel env add KEY     - Add new environment variable"
echo ""

print_success "Deployment completed successfully! 🎉"
print_success "Your app is live at: https://$DEPLOYMENT_URL"
