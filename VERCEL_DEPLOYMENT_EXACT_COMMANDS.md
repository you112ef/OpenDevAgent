# 🚀 Deploy to Vercel NOW - Exact Commands

## ✅ Prerequisites (1 minute)

```bash
# Check if you have these installed
node --version          # Should be 18+ 
npm --version          # Should be 8+
git --version          # Should be 2+

# If not installed:
# Node: https://nodejs.org/
# Git: https://git-scm.com/
```

---

## 📋 Step 1: Prepare Local Project (2 minutes)

```bash
# Navigate to project directory
cd /project/workspace/OpenDevAgent_KiloInspired

# Verify structure
ls -la
# Should show: backend/, frontend/, vercel.json, etc.

# Check git status
git status

# If not a git repo, initialize it
git init
git add .
git commit -m "Initial commit: OpenDevAgent ready for Vercel deployment"
```

---

## 🔑 Step 2: Create GitHub Repository (3 minutes)

```bash
# Go to GitHub and create new repository
# https://github.com/new

# Name: OpenDevAgent
# Description: AI Software Engineer with Plan-Act-Observe-Fix loop
# Public (so Vercel can access it)
# NO README, .gitignore, or license (we have these)

# Then run these commands:

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/OpenDevAgent.git

# Rename branch to main
git branch -M main

# Push to GitHub
git push -u origin main
# (You may be prompted for GitHub credentials or SSH key)
```

**Verify:** Go to https://github.com/YOUR_USERNAME/OpenDevAgent
Should see your code there ✅

---

## 📦 Step 3: Install Vercel CLI (1 minute)

```bash
# Install Vercel CLI globally
npm install -g vercel

# Verify installation
vercel --version
# Should show version number
```

---

## 🔐 Step 4: Login to Vercel (2 minutes)

```bash
# Login to Vercel
vercel login

# Choose login method:
# → GitHub (recommended)
# → GitLab
# → Bitbucket
# → Email

# Follow prompts and authorize
```

**Verify:** You should be logged in ✅

---

## ⚙️ Step 5: Create Environment Variables File (2 minutes)

```bash
# Create .env.local for local testing
cat > .env.local << 'EOF'
# Backend
OPENROUTER_API_KEY=sk_live_YOUR_KEY_HERE
DATABASE_URL=mongodb+srv://user:pass@cluster.mongodb.net/db

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:8000
NODE_ENV=development
EOF

# DO NOT commit this file!
# GitHub already has .env.local in .gitignore
```

---

## 🧪 Step 6: Test Locally (Optional but Recommended)

```bash
# Test frontend build
cd frontend
npm install
npm run build
# Should complete without errors

# If errors, fix them before deploying to Vercel

# Go back
cd ..
```

---

## 🚀 Step 7: Deploy to Vercel (THE MAIN STEP)

### Option A: Using CLI (Automatic)

```bash
# From project root
vercel --prod

# Vercel will ask you questions:
# 1. "Set up and deploy? [Y/n]" → Enter: Y
# 2. "Link to existing project? [y/N]" → Enter: N
# 3. "What's your project's name?" → Enter: opendevagent
# 4. "In which directory is your code?" → Enter: .
# 5. "Want to modify these settings? [y/N]" → Enter: N

# Wait for deployment...
# You'll see:
# ✓ Linked to your-username/opendevagent
# ✓ Building...
# ✓ Production: https://opendevagent-xxxxx.vercel.app
```

### Option B: Using Web Dashboard (More Control)

```bash
# Go to Vercel dashboard
open https://vercel.com/dashboard

# Click "Add New"
# Select "Import Project"
# Paste GitHub URL: https://github.com/YOUR_USERNAME/OpenDevAgent
# Click "Import"

# Configure:
# - Framework: Next.js (auto-detected)
# - Build command: npm run build (default)
# - Output directory: .next (default)
# - Root directory: ./ (default)

# Click "Deploy"
# Wait 2-3 minutes...
```

---

## ⚙️ Step 8: Configure Environment Variables on Vercel

```bash
# If using CLI:
vercel env add OPENROUTER_API_KEY
# Paste your OpenRouter API key
# Select: All environments (production, preview, development)

vercel env add NEXT_PUBLIC_API_URL
# Enter: https://api.opendevagent.vercel.app (or your backend URL)

vercel env add DEBUG
# Enter: false

vercel env add LOG_LEVEL
# Enter: info

# If using Web Dashboard:
# Go to: https://vercel.com/dashboard/YOUR_PROJECT
# Settings → Environment Variables
# Add each variable above
```

---

## 🔄 Step 9: Redeploy with Environment Variables

```bash
# After adding env vars, redeploy to production
vercel --prod

# Vercel will ask:
# "Redeploy to production? [y/N]" → Enter: y

# Wait for deployment...
```

---

## 🌐 Step 10: Get Your URLs

```bash
# After deployment, you'll have:

# Frontend URL (automatic)
# https://opendevagent-xxxxx.vercel.app

# To see all details:
vercel ls

# Shows:
# Project: opendevagent
# Production: https://opendevagent-xxxxx.vercel.app
# Created: just now
```

---

## ✅ Step 11: Verify Deployment

```bash
# Test frontend is loading
curl https://opendevagent-xxxxx.vercel.app

# Should return HTML (not error)

# If backend is deployed, test API:
curl https://your-backend-url/health

# Should return: {"status": "ok"}
```

---

## 🎯 All Commands in One Block (Copy-Paste Ready)

```bash
# ============================================
# DEPLOYMENT SCRIPT - COPY & RUN ALL
# ============================================

# 1. Navigate to project
cd /project/workspace/OpenDevAgent_KiloInspired

# 2. Initialize git (if not already)
git init
git add .
git commit -m "Initial: OpenDevAgent for Vercel" 2>/dev/null || true

# 3. Install Vercel CLI
npm install -g vercel

# 4. Login to Vercel
vercel login

# 5. Test build locally
cd frontend
npm install
npm run build
cd ..

# 6. Deploy to Vercel (interactive)
vercel --prod

# 7. Add environment variables
vercel env add OPENROUTER_API_KEY
vercel env add NEXT_PUBLIC_API_URL

# 8. Redeploy with env vars
vercel --prod

echo "✅ Deployment complete!"
vercel ls
```

---

## 🐛 Troubleshooting

### Build Failed: "npm: command not found"
```bash
# Solution: Install Node.js
# https://nodejs.org/
# Then try again
```

### Build Failed: "Module not found"
```bash
# Solution: Install dependencies
cd frontend
npm install
npm run build

cd ../backend
pip install -r requirements.txt
cd ..

vercel --prod
```

### Deployment stuck
```bash
# Cancel current deployment
vercel --prod --force

# Try again
vercel --prod
```

### Environment variables not working
```bash
# 1. Verify they're set
vercel env ls

# 2. Redeploy after adding them
vercel --prod

# 3. Check they appear in logs
vercel logs opendevagent
```

### Frontend shows blank page
```bash
# 1. Check browser console for errors
# Open: https://your-app.vercel.app
# Press: F12 (Developer Tools)
# Check: Console tab for errors

# 2. Verify NEXT_PUBLIC_API_URL is set
vercel env ls

# 3. Rebuild if needed
vercel --prod --force
```

---

## 📊 Expected Output

### Successful Deployment
```
✓ Linked to your-username/opendevagent
✓ Inspecting files of the project
✓ Handling Build Cache with hashes
✓ Installing dependencies
✓ Running "npm run build"
✓ Production: https://opendevagent-xxxxx.vercel.app
✓ Deployed to production
```

### Your URLs
```
Frontend: https://opendevagent-xxxxx.vercel.app
Backend: https://your-backend-url (if deployed)
Dashboard: https://vercel.com/your-username/opendevagent
```

---

## 🔄 Setting Up Automatic Deployments

Once deployed, every `git push` will auto-deploy:

```bash
# Push to GitHub (auto-triggers Vercel deployment)
git add .
git commit -m "Update: new features"
git push origin main

# Vercel automatically:
# ✓ Detects the push
# ✓ Builds your project
# ✓ Deploys to production
# ✓ Shows status

# No manual steps needed! 🎉
```

---

## 🎊 You're Live!

After following these steps:
- ✅ Frontend is live at: https://opendevagent-xxxxx.vercel.app
- ✅ Auto-deploys on every git push
- ✅ Environment variables configured
- ✅ Production-ready
- ✅ $0 cost

---

## 📞 Next Steps

### 1. Deploy Backend (if separate)
- Option A: Deploy on Railway (same process)
- Option B: Deploy on Render (same process)
- See: QUICK_FREE_START.md

### 2. Connect Database
- Use MongoDB Atlas (free 512MB)
- Or use PostgreSQL (if using Railway/Render)

### 3. Test Application
```bash
# Test frontend loads
curl https://your-app.vercel.app

# Test API endpoint
curl https://your-api.vercel.app/health
```

### 4. Monitor Deployments
```bash
# View recent deployments
vercel ls

# View deployment logs
vercel logs opendevagent

# View in dashboard
open https://vercel.com/your-username/opendevagent
```

---

## 🆘 Quick Help

| Issue | Command |
|-------|---------|
| Check deployment status | `vercel ls` |
| View logs | `vercel logs opendevagent` |
| Show env variables | `vercel env ls` |
| Add env variable | `vercel env add KEY` |
| View dashboard | `open https://vercel.com/dashboard` |
| Redeploy | `vercel --prod --force` |

---

## ✨ Complete Workflow Summary

```
1. cd /project/workspace/OpenDevAgent_KiloInspired
2. git init && git add . && git commit -m "Initial"
3. npm install -g vercel
4. vercel login (GitHub)
5. npm --prefix frontend run build (test)
6. vercel --prod (deploy)
7. vercel env add OPENROUTER_API_KEY
8. vercel env add NEXT_PUBLIC_API_URL
9. vercel --prod (redeploy with env vars)
10. Done! ✅
```

**Total Time: 10-15 minutes**
**Cost: $0**
**Result: Live production app** 🚀

---

## 🎉 That's It!

Your OpenDevAgent is now live on Vercel!

**Check it out:**
```bash
# Get your URL
vercel ls

# Open in browser
open https://your-app.vercel.app
```

---

**Status**: ✅ Ready to Deploy
**Next**: Watch your app go live! 🚀
