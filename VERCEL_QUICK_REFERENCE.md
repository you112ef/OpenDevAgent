# 🚀 VERCEL DEPLOYMENT - QUICK REFERENCE CARD

## 💨 FASTEST WAY (Copy & Paste)

```bash
# Run this ONE command to deploy automatically:
bash /project/workspace/OpenDevAgent_KiloInspired/deploy-vercel.sh
```

**That's it!** The script handles everything.

---

## 📋 MANUAL COMMANDS (if you prefer)

### 1. Install Tools
```bash
npm install -g vercel
```

### 2. Login
```bash
vercel login
# Choose: GitHub
# Authorize in browser
```

### 3. Navigate to Project
```bash
cd /project/workspace/OpenDevAgent_KiloInspired
```

### 4. Deploy
```bash
vercel --prod
# Answer: Y, N, opendevagent, .
```

### 5. Add Env Variables
```bash
vercel env add OPENROUTER_API_KEY
# Paste: sk_live_...

vercel env add NEXT_PUBLIC_API_URL
# Paste: https://api.your-app.vercel.app
```

### 6. Redeploy
```bash
vercel --prod
# Answer: Y
```

### 7. Done! Get URL
```bash
vercel ls
# Copy the production URL
```

---

## 🎯 WHAT YOU NEED TO PROVIDE

1. **OpenRouter API Key**
   - Get from: https://openrouter.ai/
   - Format: `sk_live_...`

2. **Backend URL** (optional)
   - Format: `https://your-backend.vercel.app`
   - Or leave blank if not deploying backend yet

---

## ✅ VERIFICATION

After deployment:

```bash
# 1. Check deployment
vercel ls

# 2. Open in browser
# https://opendevagent-xxxxx.vercel.app

# 3. Test frontend loads (should see your app)

# 4. View logs if issues
vercel logs opendevagent
```

---

## 🔄 AFTER DEPLOYMENT

### Push Updates Automatically
```bash
# Make changes, commit, and push
git add .
git commit -m "Update: new features"
git push origin main

# Vercel auto-deploys! ✅
```

### View Deployments
```bash
# See all deployments
vercel ls

# View recent logs
vercel logs opendevagent

# View in browser
open https://vercel.com/dashboard
```

---

## 🆘 IF SOMETHING GOES WRONG

### Build Failed
```bash
# View detailed logs
vercel logs opendevagent

# Fix issues locally first
cd frontend && npm run build

# Then retry
vercel --prod --force
```

### Blank Page
```bash
# Check browser console (F12)
# Check environment variables
vercel env ls

# Redeploy
vercel --prod
```

### API Not Responding
```bash
# Verify backend is deployed
# Check NEXT_PUBLIC_API_URL

# Redeploy frontend
vercel --prod
```

---

## 📞 HELPFUL COMMANDS

| What | Command |
|------|---------|
| List deployments | `vercel ls` |
| View logs | `vercel logs opendevagent` |
| Env variables | `vercel env ls` |
| Add env var | `vercel env add KEY` |
| Remove deployment | `vercel rm opendevagent` |
| Current user | `vercel whoami` |
| Logout | `vercel logout` |

---

## 🎊 FINAL CHECKLIST

- [ ] OpenRouter API key ready
- [ ] Vercel account created (GitHub)
- [ ] Node.js and npm installed
- [ ] Git initialized
- [ ] Run deploy script OR manual commands
- [ ] Environment variables set
- [ ] Redeployed after env vars
- [ ] Verified app loads in browser
- [ ] Bookmarked your app URL

---

## 🚀 READY?

### Run Automatic Deployment
```bash
bash /project/workspace/OpenDevAgent_KiloInspired/deploy-vercel.sh
```

### Or Manual Step-by-Step
```bash
cd /project/workspace/OpenDevAgent_KiloInspired
vercel login              # Step 1
vercel --prod             # Step 2 (deploy)
vercel env add OPENROUTER_API_KEY  # Step 3
vercel --prod             # Step 4 (redeploy)
```

---

**Status**: ✅ Ready to Deploy
**Time**: 10-15 minutes
**Cost**: $0
**Result**: Live app! 🎉

Let's deploy! 🚀
