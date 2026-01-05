# API Connection Setup for iOS Simulator

## Problem
The iOS Simulator cannot connect to `bensa.test` because Laravel Valet only listens on localhost (127.0.0.1).

## Solutions

### Option 1: Use ngrok (Recommended for testing)

1. **Install ngrok**:
   ```bash
   brew install ngrok
   ```

2. **Start ngrok tunnel**:
   ```bash
   ngrok http bensa.test:80
   ```

3. **Copy the HTTPS URL** from ngrok output (e.g., `https://abc123.ngrok-free.app`)

4. **Update API URL** in `lib/core/api_service.dart`:
   ```dart
   static const String baseUrl = 'https://abc123.ngrok-free.app/api';
   ```

5. **Hot reload** your Flutter app

### Option 2: Test on physical iPhone

Physical iPhones on the same WiFi can access your Mac's IP address.

1. **Get your Mac's IP** address:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   Example output: `192.168.2.37`

2. **Add to /etc/hosts** on your iPhone (requires jailbreak) OR use IP directly

3. **Update API URL** in `lib/core/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://192.168.2.37/api';
   ```

   But this won't work with Valet's host-based routing.

### Option 3: Deploy backend to production server

1. Deploy your Laravel backend to a real server (e.g., DigitalOcean, AWS, Heroku)

2. Update API URL in `lib/core/api_service.dart`:
   ```dart
   static const String baseUrl = 'https://your-domain.com/api';
   ```

### Option 4: Use environment-based configuration (Best for production)

1. Create `lib/config/environment.dart`:
   ```dart
   class Environment {
     static const bool isDevelopment = bool.fromEnvironment('dev', defaultValue: true);

     static String get apiBaseUrl {
       if (isDevelopment) {
         // Use ngrok URL for development
         return 'https://YOUR_NGROK_URL.ngrok-free.app/api';
       } else {
         // Use production URL
         return 'https://api.bensa.app/api';
       }
     }
   }
   ```

2. Update `lib/core/api_service.dart`:
   ```dart
   import '../config/environment.dart';

   class ApiService {
     static final String baseUrl = Environment.apiBaseUrl;
     // ...
   }
   ```

## Current Status

Your backend is running on `http://bensa.test` (via Valet) but **iOS Simulator cannot access it**.

You need to use one of the options above to make your API accessible to the simulator.

## Quick Fix (Right Now)

Run this command in terminal:
```bash
ngrok http bensa.test:80
```

Then update `lib/core/api_service.dart` line 9 with the ngrok URL:
```dart
static const String baseUrl = 'https://YOUR_NGROK_URL/api';
```

Hot reload your app and try registering again.
























