# Flutter Frontend Environment Configuration

## Overview
The Flutter frontend now uses environment variables for configuration instead of hardcoded values. This improves security and allows easy configuration for different environments (development, staging, production).

## Configuration Method

### Using --dart-define (Recommended for Development)
You can pass environment variables when running the Flutter app:

```bash
# For development with local backend
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1 \
            --dart-define=WS_BASE_URL=ws://localhost:8000/ws

# For production/staging
flutter run --dart-define=API_BASE_URL=https://your-production-domain.com/api/v1 \
            --dart-define=WS_BASE_URL=wss://your-production-domain.com/ws
```

### Using Build Flavors
You can also configure build flavors in your `android/app/build.gradle` or `ios/Runner.xcworkspace` for more permanent configurations.

### Environment Variables in CI/CD
For automated builds, pass the variables through your CI/CD pipeline:
- GitHub Actions: Use `flutter build` with `--dart-define`
- Codemagic: Set environment variables in the UI
- GitLab CI: Use variables in `.gitlab-ci.yml`

## Required Variables

### API_BASE_URL
- Purpose: Base URL for all REST API calls
- Format: `http://host:port/api/v1` or `https://host/api/v1`
- Example: `http://localhost:8000/api/v1`

### WS_BASE_URL
- Purpose: Base URL for WebSocket connections (chat functionality)
- Format: `ws://host:port/ws` or `wss://host/ws`
- Example: `ws://localhost:8000/ws`

## Security Notes
1. Never commit actual API keys or secrets to the frontend code
2. All authentication tokens are handled securely via secure storage
3. Environment variables should be managed carefully in production
4. Consider using certificate pinning for production builds

## Troubleshooting
If you see connection errors:
1. Verify the environment variables are correctly passed
2. Check that the backend is running and accessible
3. Ensure proper CORS configuration on the backend
4. Verify network permissions in AndroidManifest.xml and Info.plist