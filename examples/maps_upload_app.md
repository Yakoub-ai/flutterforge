# Recipe: Maps, Location, and Photo Upload App

## What We're Building

An app that shows the user's current location on an interactive Google Map, lets them drop pins at custom locations with notes, and allows them to attach a photo to each pin — uploaded to Firebase Storage. The app demonstrates the three most common platform-integration challenges in Flutter: location permissions, camera/gallery permissions, and platform-specific configuration for Google Maps. This recipe specifically shows how `/flutterforge:improve-ux` fits into the workflow after the core features are working.

## Prerequisites

- Flutter 3.19+ and Dart on `PATH`
- FlutterForge plugin installed in Claude Code
- A Google Cloud project with the **Maps SDK for Android**, **Maps SDK for iOS**, and **Places API** enabled
- A Google Maps API key (restrict it to your app's package name/bundle ID in production)
- A Firebase project with **Firebase Storage** enabled
- Android emulator with Google Play Services, or a physical device
- iOS simulator or physical device

---

## Step-by-Step Workflow

### Step 1 — Plan the App

```
/flutterforge:plan-flutter-app "I want to build a Flutter app that shows the user's current location on a Google Map. Users can long-press anywhere on the map to drop a pin, add a title and note to the pin, and attach a photo (camera or gallery). Photos are uploaded to Firebase Storage. All pins are saved locally with Isar and shown on the map as custom markers. Tapping a marker shows a bottom sheet with the pin details and photo."
```

**What happens:** The product-strategist frames this as a location journaling app — users drop pins to capture moments or places. Personas: traveler, urban explorer, field researcher. User stories cover pin creation, pin viewing, photo attachment, offline viewing of cached pins, and pin deletion.

The UX designer maps out the interaction: map-first UI (the map fills the screen), a floating action button to center on location, a long-press gesture to initiate pin creation, a bottom sheet for the pin form (title, note, photo picker), and a detail bottom sheet when tapping existing pins. No separate screen list view for v1.

The Flutter architect recommends:
- `google_maps_flutter` for the map widget
- `geolocator` + `permission_handler` for location
- `image_picker` for camera/gallery access
- `firebase_storage` for photo upload
- `isar` for local pin persistence
- `riverpod` for state management
- Custom marker bitmaps (converting widget screenshots to `BitmapDescriptor`)

**Decision point:** Custom markers (rendered from widgets) are more complex than asset-based markers. If you want to keep it simple for v1, reply:

> "Use simple asset-based markers for v1 — a custom colored pin icon from the assets folder. Skip widget-to-bitmap conversion."

---

### Step 2 — Set Up Firebase and Google Maps

These are manual configuration steps that must happen before scaffolding.

**Firebase Storage:**
1. Go to [console.firebase.google.com](https://console.firebase.google.com) and open your project (or create one)
2. Enable **Storage** under Build → Storage. Choose a region close to your users.
3. Set Storage rules for authenticated access (or public for development — tighten before release):
   ```
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /pins/{allPaths=**} {
         allow read, write: if true; // Tighten before production
       }
     }
   }
   ```
4. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

**Google Maps API key:**
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Enable Maps SDK for Android, Maps SDK for iOS, and Geocoding API
3. Create an API key. For development, leave it unrestricted. Before release, restrict it.
4. Keep the key handy — you will add it to platform-specific config files, not to Dart code

---

### Step 3 — Scaffold the Project

```
/flutterforge:new-flutter-app
```

After scaffolding, add the Firebase and Google Maps platform configuration — this is the most tedious part and must be done correctly before any code works.

**Android — add Google Maps API key:**

Open `android/app/src/main/AndroidManifest.xml` and add inside `<application>`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

Also add the Firebase config file:
```bash
cp ~/Downloads/google-services.json android/app/google-services.json
```

**iOS — add Google Maps API key:**

Open `ios/Runner/AppDelegate.swift` and add:
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Also add the Firebase config file:
```bash
cp ~/Downloads/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
```

**iOS — add usage descriptions to `Info.plist`:**

These are required by Apple — the app will crash on launch without them:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses your location to show where you are on the map.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app uses your location to show where you are on the map.</string>
<key>NSCameraUsageDescription</key>
<string>This app uses your camera to attach photos to map pins.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app accesses your photo library to attach photos to map pins.</string>
```

Run `flutterfire configure` to generate `lib/firebase_options.dart`:
```bash
flutterfire configure --project=your-firebase-project-id
```

Verify the app compiles:
```bash
flutter run
```

---

### Step 4 — Build Location Permission and Current Location

```
/flutterforge:build-flutter-feature "Location service: use permission_handler to request 'location when in use' permission. On first launch, show a pre-permission rationale dialog explaining why location is needed before calling the system permission dialog. If denied, show a non-blocking banner with a 'Open Settings' button. If granted, use geolocator to get the current position and continuously stream position updates. Expose the current position as a Riverpod StreamProvider. Handle the case where location services are disabled (not just permission denied)."
```

**What happens:** The inspect phase checks for existing permission handling patterns. The plan phase shows the full permission flow including the three states: granted, denied, and permanently denied (which requires opening system settings).

**Approval gate:** The plan should include the pre-permission rationale dialog. This pattern significantly improves permission grant rates on iOS. If the plan skips it, ask:

> "Add a pre-permission dialog that explains why we need location access before the system dialog appears."

After implementation, test on a real device (permission flows behave differently on simulators):
- Fresh install → rationale dialog → system dialog → location appears on map
- Deny permission → banner appears → tapping "Open Settings" opens device settings
- Grant permission in settings → return to app → location loads automatically

---

### Step 5 — Build the Map Screen

```
/flutterforge:build-flutter-feature "Main map screen using google_maps_flutter. Show a GoogleMap widget filling the screen. Center the camera on the user's current location when it first becomes available (animate the camera, do not snap). Show the user's location as the default blue dot (myLocationEnabled: true). Add a floating action button in the bottom-right to re-center on current location. The map should update as the user moves (follow location stream from Step 4's provider). Long-press on the map emits the tapped LatLng to a Riverpod StateProvider for use in the next step."
```

**What happens:** A focused map setup step. The agent keeps this screen simple — just the map and location tracking, no pin creation yet. This is intentional: get the map working perfectly before adding interactivity.

Test camera animation, the re-center button, and that long-press coordinates are captured (log them to console for now).

---

### Step 6 — Build Pin Creation

```
/flutterforge:build-flutter-feature "Pin creation flow: when a long-press LatLng is received (from the StateProvider set in Step 5), show a bottom sheet with a title field, a notes field, a photo attachment button (opens a dialog to choose Camera or Gallery using image_picker), and Save/Cancel buttons. Photo preview shows inline if selected. On Save, create a MapPin record (title, notes, latitude, longitude, optional photoPath) and save it to an Isar database. Add the pin to the map as a marker immediately (optimistic UI). The Isar pins collection is exposed as a Riverpod StreamProvider that the map screen watches to display all markers."
```

**What happens:** This is the most complex step. The plan will show:
- The `MapPin` Isar model with `@Collection` annotation
- The `PinRepository` wrapping the Isar database
- The `pinsProvider` as a `StreamProvider` (Isar supports reactive streams natively)
- The bottom sheet widget with form validation
- Image picker integration

**Approval gate:** Verify the plan uses optimistic UI — the pin should appear on the map immediately when the user taps Save, before the Isar write completes. This makes the app feel fast.

After implementation, run the Isar code generator:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

Test the full flow: long-press the map, fill in the form, attach a photo, save, and verify the marker appears immediately.

---

### Step 7 — Build Photo Upload to Firebase Storage

```
/flutterforge:build-flutter-feature "Upload pin photos to Firebase Storage. When a pin is saved with a photo, upload the local file to Firebase Storage at path 'pins/{pinId}/{filename}'. Store the returned download URL in the MapPin record (update the Isar record after upload). Show an upload progress indicator in the pin detail bottom sheet while uploading. If upload fails, keep the local photo path and show a retry button. Handle offline: queue failed uploads and retry when connectivity is restored using connectivity_plus."
```

**What happens:** The offline retry queue is the complexity here. The plan will show a simple approach: store a `pendingUpload` boolean on the `MapPin` model and check for pending uploads when the app comes online.

**Decision point:** The offline queue implementation can get complex. If the plan proposes a full background upload queue, simplify it:

> "Keep the offline handling simple: if upload fails, mark the pin as 'upload pending' and show a warning icon on the marker. Add a 'Retry failed uploads' button in the app bar that triggers a manual retry. Skip automatic retry on connectivity restore for v1."

---

### Step 8 — Build Pin Detail Bottom Sheet

```
/flutterforge:build-flutter-feature "Pin detail bottom sheet shown when tapping a map marker. Display the pin title, notes, creation date/time, and the photo (loaded from Firebase Storage download URL using CachedNetworkImage, or from local path if upload is still pending). Add a delete button with a confirmation dialog. Deleting removes the marker from the map immediately, deletes the Isar record, and deletes the Firebase Storage file if it was uploaded."
```

Test the full lifecycle: create a pin with photo → tap the marker → view the detail → delete → verify the marker is gone and the Isar record is removed.

---

### Step 9 — UX Improvement Pass

Now that the core features are working, run the UX agent. This is the recommended point — before testing coverage is complete but after the feature set is stable.

```
/flutterforge:improve-ux "map interactions and pin creation flow"
```

**What the UX agent typically returns for a maps app:**

1. **Marker clustering:** When many pins are close together, they overlap. The agent may suggest `google_maps_cluster_manager` or a custom clustering approach.
2. **Map long-press feedback:** A brief haptic vibration when a long-press is detected improves discoverability.
3. **Bottom sheet drag handle:** The pin creation sheet should have a visible drag handle and support dismiss-by-dragging-down.
4. **Photo loading states:** Shimmer placeholder while the Firebase Storage URL resolves.
5. **Empty state:** First-time users see an empty map with no instruction. The agent may suggest a one-time tooltip: "Long-press anywhere to add a pin."

For each suggestion, decide what to implement now vs later. Haptic feedback and the drag handle are quick wins. Marker clustering can wait until you have more test data.

After the UX agent's implementation, retest the full flow on a physical device — haptic and gesture feel cannot be verified on simulators.

---

### Step 10 — Generate Tests

```
/flutterforge:generate-tests "Maps app: unit tests for PinRepository (Isar in-memory), upload logic (mock Firebase Storage), permission handler (mock permission_handler), and widget tests for PinCreationSheet and PinDetailSheet. Integration test for the full pin creation flow."
```

```bash
flutter test
```

Note: `google_maps_flutter` cannot be rendered in widget tests (it requires a native map view). The test engineer will replace it with a mock or stub in the test environment. This is expected behavior.

---

### Step 11 — Final Audit

```
/flutterforge:audit-flutter-app
```

Key findings to expect for this app type:

- **Security:** The Maps API key is embedded in `AndroidManifest.xml` and `AppDelegate.swift`. The security reviewer will flag this. Before release, restrict the key in Google Cloud Console to your app's package name (Android) and bundle ID (iOS).
- **Performance:** Loading all markers at once will cause jitter with many pins. The performance engineer will suggest loading markers within the current map viewport bounds only.
- **Storage rules:** The `allow read, write: if true` Firebase Storage rules set in Step 2 will be flagged. Replace with authenticated user rules before release.

```
/flutterforge:prepare-release
```

The release engineer will flag iOS-specific items:
- `NSLocationAlwaysAndWhenInUseUsageDescription` in addition to the keys already added
- Background location mode in Xcode capabilities (only if you enable background tracking)
- Privacy manifest for iOS 17+ (`PrivacyInfo.xcprivacy`) covering location and photo library usage

---

## Tips for This App Type

**API key restrictions:** In development, an unrestricted Maps key is fine. Before your first TestFlight or Play Store internal test, restrict the key. An unrestricted key in a published app will eventually be scraped and abused.

**`google_maps_flutter` iOS performance:** On older iPhones, the map view can cause frame drops when combined with bottom sheets. Use `mapType: MapType.normal` (not satellite) and minimize the number of custom marker bitmaps in memory.

**Isar code generation:** Every time you change an `@Collection` class, re-run:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```
Forgetting this causes confusing type errors that look like Isar is corrupted.

**Location accuracy vs battery:** `geolocator` defaults to high accuracy. For a pin-dropping app where the user is stationary when pinning, use `LocationAccuracy.medium` — it is sufficient and uses less battery.

**Firebase Storage download URLs:** Download URLs from Firebase Storage do not expire by default (they use a token that persists as long as the file exists). If you delete a file from Storage, the URL returns 403. Handle this in the detail sheet with an error state that falls back to the local file if available.

**Camera permission on Android 13+:** On Android 13+, `READ_EXTERNAL_STORAGE` is replaced by granular media permissions. `image_picker` handles this automatically as of version 0.8.8+. Ensure you are on a recent version of `image_picker` and do not manually declare the old permission in `AndroidManifest.xml`.

**Testing location on simulators:** Android emulator supports simulated GPS coordinates via the Extended Controls menu. iOS simulator supports location simulation via Debug → Location. Set a fixed location before testing — "None" will cause the location stream to never emit and your app will appear to hang.
