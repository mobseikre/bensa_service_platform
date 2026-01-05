# API URL Configuration Fix for Chrome & iOS Simulator

## ✅ What Was Fixed

The app now automatically detects the platform and uses the correct API URL:
- **Chrome (Web)**: Uses `http://localhost/api`
- **iOS Simulator**: Uses `http://localhost/api`
- **Android Emulator**: Uses `http://10.0.2.2/api` (special emulator IP)

## 🚀 Quick Start

The configuration is now automatic! Just run your app:
- In Chrome: `flutter run -d chrome`
- In iOS Simulator: `flutter run -d ios`
- In Android Emulator: `flutter run -d android`

## 🔧 If localhost Doesn't Work with Herd

If you get connection errors, Herd might not be responding to `localhost` requests. Here's how to fix it:

### Option 1: Use Your Machine's IP Address (Recommended)

1. **Find your Mac's IP address**:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   Example output: `inet 192.168.1.100`

2. **Update the config** in `lib/core/api_config.dart`:
   ```dart
   // Change this line:
   static const String? _manualOverride = null;

   // To this (replace with your IP):
   static const String? _manualOverride = 'http://192.168.1.100/api';
   ```

3. **Restart your Flutter app**

### Option 2: Configure Herd to Respond to localhost

Herd should respond to `localhost` by default, but if it doesn't:

1. Open **Herd** app
2. Go to **Settings**
3. Make sure **Port** is set to `80`
4. Restart Herd: `herd restart`

### Option 3: Use ngrok (For Testing)

If you need to test from external devices:

1. **Start ngrok**:
   ```bash
   ngrok http bensa.test:80
   ```

2. **Copy the HTTPS URL** (e.g., `https://abc123.ngrok-free.app`)

3. **Update the config** in `lib/core/api_config.dart`:
   ```dart
   static const String? _manualOverride = 'https://abc123.ngrok-free.app/api';
   ```

## 📝 How It Works

The app uses `lib/core/api_config.dart` to automatically detect:
- **Platform** (Web, iOS, Android)
- **Environment** (Development, Production)

And selects the appropriate URL automatically.

## 🧪 Testing

After making changes, test the connection:

1. **Run the app** in your target platform
2. **Check the console** - you should see:
   - `🌐 Platform: Web (Chrome) - Using localhost` (for web)
   - `📱 Platform: iOS Simulator - Using localhost` (for iOS)
   - `🤖 Platform: Android Emulator - Using 10.0.2.2` (for Android)

3. **Try logging in or registering** - if it works, you're all set!

## 🔍 Troubleshooting

### Issue: "Connection refused" or "Failed to connect"

**Solution**: Herd might not be running or not responding to localhost.

1. Check if Herd is running: Open Herd app
2. Verify your site is linked: `herd sites` (should show `bensa.test`)
3. Test in browser: Open `http://bensa.test/api` - should show JSON or error (not connection refused)
4. If browser works but app doesn't, use Option 1 above (machine IP)

### Issue: "CORS error" (web only)

**Solution**: Backend CORS is already configured to allow all origins. If you still see CORS errors:

1. Check `backend_api/config/cors.php` - should have `'allowed_origins' => ['*']`
2. Clear Laravel cache: `php artisan config:clear`
3. Restart Herd: `herd restart`

### Issue: Works in browser but not in app

**Solution**: The app might be using a different URL. Check the console logs to see which URL is being used.

## 📱 Platform-Specific Notes

### Chrome (Web)
- Uses `http://localhost/api`
- Make sure Herd is running on port 80
- CORS must be enabled (already configured)

### iOS Simulator
- Uses `http://localhost/api`
- Simulator shares the host machine's network
- Should work out of the box

### Android Emulator
- Uses `http://10.0.2.2/api` (special IP that maps to host's localhost)
- This is the standard way to access host machine from Android emulator
- Should work automatically

## 🎯 Next Steps

1. **Test the app** in Chrome and iOS Simulator
2. **If it works**: You're done! 🎉
3. **If it doesn't**: Use Option 1 above to set your machine's IP address

## 💡 Pro Tip

You can check which URL is being used by looking at the debug console when the app starts. The platform detection message will show you exactly which URL is selected.

---

**Need help?** Check the console logs - they'll tell you which platform and URL are being used!





