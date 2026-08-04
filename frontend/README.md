# frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Local web Firebase phone OTP

Firebase Authentication already authorizes `localhost` for this project. SHIELD
keeps its own localhost guard enabled by default so a local browser cannot
accidentally send real SMS OTPs.

Use this only for debug testing with real Firebase authentication:

```powershell
flutter run -d chrome --dart-define=ALLOW_LOCAL_WEB_PHONE_AUTH=true
```

To disable local browser OTP, omit the flag or pass `false`:

```powershell
flutter run -d chrome --dart-define=ALLOW_LOCAL_WEB_PHONE_AUTH=false
```

This is a compile-time setting, so stop and restart Flutter after changing it.
It does not create a mock user or bypass Firebase, backend JWT, or session
authorization. The repository guard also requires `kDebugMode`, so release
builds remain blocked from local web phone OTP.

## Deployment

This Flutter Web application is configured for deployment on Vercel.

* **Vercel Project Name**: `shield-zabnix`
* **Vercel Project ID**: `prj_iZUPqbwbQbudPB6If2YcD06GfUEN`
* **Live Production URL**: `https://shield-zabnix.vercel.app`
* **Production API URL**: `https://shield-backend.vercel.app`

For manual CLI deployments:
```bash
$ npm install -g vercel
$ vercel deploy --prod
```
