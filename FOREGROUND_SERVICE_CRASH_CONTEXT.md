# Issue Context: Android Foreground Service Crash

## 1. Issue Summary
The application is repeatedly crashing on Android devices (specifically Android 13/14+) immediately upon launching or attempting to start the background pedometer tracking. 

The console outputs a fatal exception:
```
E/AndroidRuntime: FATAL EXCEPTION: main
E/AndroidRuntime: android.app.RemoteServiceException$CannotPostForegroundServiceNotificationException: Bad notification for startForeground
```

## 2. Why it Occurs (Root Causes)
Starting from Android 12 (API 31), and especially Android 14 (API 34+), the OS has implemented extremely strict rules for "Foreground Services" (background tasks that must show a persistent notification so the user knows they are running). If any of these rules are violated, Android instantly kills the app with a `Bad notification` error to prevent invisible background tracking.

In this health monitor application, several overlapping issues triggered this exact crash:

1. **Missing or Mismatched Foreground Service Type:**
   - **The Rule:** Android 14 requires that health-tracking apps explicitly declare their foreground service type as `health` in both the `AndroidManifest.xml` AND programmatically when starting the service. 
   - **The Bug:** While the manifest had `android:foregroundServiceType="health"`, the Dart code for `flutter_background_service` wasn't passing `[AndroidForegroundType.health]` in the `AndroidConfiguration`.

2. **Invalid/Missing Notification Icons:**
   - **The Rule:** A foreground service notification *must* have a valid "small icon".
   - **The Bug:** The configuration referenced an icon (`ic_bg_service_small`) that either didn't exist or was incorrectly formatted in the `android/app/src/main/res/drawable` directories, causing the OS to fail when constructing the notification.

3. **Missing Notification Channel:**
   - **The Rule:** Since Android 8.0, all notifications must belong to an existing Notification Channel.
   - **The Bug:** The app attempted to use a custom channel (`step_tracker_channel`), but due to asynchronous races, the channel sometimes wasn't fully created by `flutter_local_notifications` before the background service tried to use it.

4. **Premature Auto-Start Without Permissions (The Primary Culprit):**
   - **The Rule:** Starting a "health" foreground service requires the user to have already granted the `ACTIVITY_RECOGNITION` and `POST_NOTIFICATIONS` runtime permissions.
   - **The Bug:** `initBackgroundService()` was being called immediately in `main.dart` with `autoStart: true` before the UI even loaded to ask the user for permission. The OS caught an unauthorized background process trying to start and crashed the app.

## 3. Affected Files
* **`lib/main.dart`**: Responsible for app initialization. Calling `initBackgroundService()` here without checking permissions causes startup crashes.
* **`lib/services/background_step_service.dart`**: Contains the configuration for `flutter_background_service`. This is where `foregroundServiceTypes`, `notificationChannelId`, and permission safety checks must be strictly defined.
* **`lib/services/pedometer_service.dart`**: The correct place to initialize the background service, immediately *after* the user accepts the permission prompts via the `permission_handler` logic.
* **`android/app/src/main/AndroidManifest.xml`**: Where `<uses-permission>` tags and the `<service>` declaration for `id.flutter.flutter_background_service.BackgroundService` reside.

## 4. Fixes Implemented
1. **Removed Invalid Manifest Permissions:** Removed the `BIND_JOB_SERVICE` flag from the background service, which conflicts with standard foreground execution.
2. **Channel Auto-Creation:** Changed `notificationChannelId` to `null` inside `AndroidConfiguration` so the library safely generates its own fallback default channel synchronously.
3. **Foreground Service Types:** Explicitly added `foregroundServiceTypes: [AndroidForegroundType.health]` to the Dart configuration to satisfy Android 14 requirements.
4. **Conditional Startup (Permission Gates):** Added explicit checks in `initBackgroundService()` to `return` early if `Permission.activityRecognition` or `Permission.notification` are not granted.
5. **Deferred Startup:** Moved the ultimate invocation of `initBackgroundService()` into `pedometer_service.dart`'s `startListening()` method so it only boots *after* the user clicks "Allow" on the permission popups.

## 5. How to Debug Future Occurrences
If this `CannotPostForegroundServiceNotificationException` crash reappears:
1. Ensure you haven't added a new required permission to Android without asking the user via `permission_handler` first.
2. Check `android/app/src/main/res/drawable` to ensure any requested notification icons actually exist.
3. Verify that the `<service>` tag in `AndroidManifest.xml` perfectly matches the `AndroidForegroundType` requested in `background_step_service.dart`.