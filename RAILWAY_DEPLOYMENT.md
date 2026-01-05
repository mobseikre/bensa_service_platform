# Deploy Backend to Railway - Step by Step Guide

## ✅ Why Deploy to Railway?
- **Solves all tunneling/redirect issues** - No more Expose, ngrok, or IP address problems
- **Stable HTTPS URL** - Your Flutter app can connect directly
- **Production-ready** - Real server infrastructure

## 📋 Steps to Deploy

### 1. In Railway Dashboard (https://railway.com)

#### Option A: Deploy from GitHub (Recommended)
1. Go to your project: https://railway.com/project/9b1762e4-6c3b-48e6-a728-6a3e9d4793e4
2. Click **"+ Create"** or **"New"**
3. Select **"GitHub Repo"**
4. Choose your repository: `mobseikre/Bensa`
5. Railway will automatically detect Laravel and start deploying

#### Option B: Deploy via Railway CLI
If you want to use the CLI (from the modal you saw):
```bash
# Install Railway CLI (if not already installed)
curl -fsSL https://railway.com/install.sh | sh

# Login to Railway
railway login

# Link to your project
cd /Users/mohammedhweedi/Downloads/Bensa
railway link -p 9b1762e4-6c3b-48e6-a728-6a3e9d4793e4

# Deploy
railway up
```

### 2. Configure Environment Variables

In Railway dashboard → Your service → **Variables** tab:

Add these required variables:
```
APP_NAME=Bensa
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:YOUR_APP_KEY_HERE
APP_URL=https://YOUR_RAILWAY_URL.up.railway.app
```

**To get APP_KEY:**
```bash
cd /Users/mohammedhweedi/Downloads/Bensa
php artisan key:generate --show
```
Copy the output and paste it as `APP_KEY` value.

### 3. Database Setup (if needed)

If your app uses a database:
1. In Railway, click **"+ Create"** → **"Database"** → **"PostgreSQL"** or **"MySQL"**
2. Railway will automatically create connection variables
3. Add them to your Laravel service's environment variables

### 4. Get Your Railway URL

After deployment:
1. Go to your service in Railway
2. Click on **"Settings"** tab
3. Under **"Domains"**, you'll see your public URL
   - Example: `https://bensa-production.up.railway.app`
   - Or: `https://YOUR_SERVICE_NAME.up.railway.app`

### 5. Update Flutter App

Once you have your Railway URL, update `lib/core/api_service.dart`:

**Replace line 9:**
```dart
static const String baseUrl = 'https://YOUR_RAILWAY_URL.up.railway.app/api';
```

**Example:**
```dart
static const String baseUrl = 'https://bensa-production.up.railway.app/api';
```

Then **remove all the redirect/tunneling hacks** (the InterceptorsWrapper code).

## 🎯 What to Do Now

1. **Go to Railway** and deploy your backend from GitHub
2. **Copy your Railway URL** after deployment finishes
3. **Tell me the URL** and I'll update your Flutter app code

That's it! No more tunneling issues! 🎉























