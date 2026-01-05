# Quick ngrok Setup (30 seconds)

## Step 1: Get Your Authtoken

1. Open this link in your browser: **https://dashboard.ngrok.com/get-started/your-authtoken**

2. Sign up (free) with Google/GitHub or email

3. Copy your authtoken (looks like: `2abc...`)

## Step 2: Add Token to ngrok

In terminal, run:
```bash
ngrok config add-authtoken YOUR_TOKEN_HERE
```

## Step 3: Start Tunnel

```bash
ngrok http --host-header=bensa.test 80
```

## Step 4: Copy the URL

You'll see output like:
```
Forwarding   https://abc123.ngrok-free.app -> http://localhost:80
```

Copy the **https://** URL

## Step 5: I'll Update the App

Tell me the URL and I'll update your Flutter app automatically.

---

**OR - Even Faster:**

Just run these 3 commands (I'll give you the token URL):

```bash
# 1. Open ngrok dashboard
open https://dashboard.ngrok.com/get-started/your-authtoken

# 2. After you get token, run (replace YOUR_TOKEN):
ngrok config add-authtoken YOUR_TOKEN

# 3. Start tunnel:
ngrok http --host-header=bensa.test 80
```

Then share the https URL with me!
























