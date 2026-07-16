# PharmConnect

A Flutter/Firebase pharmacy management prototype, Mobile
Application Development (Recess Term). See `PharmConnect_Full_Proposal.pdf`
for the requirements (FR1–FR12, NFR1–NFR7) and UML diagrams this build
implements against.

## What changed in this pass

Four gaps identified in a code review of the pre-Firebase build were fixed:

1. **No persistence** → `DrugProvider`, `OrderProvider`, and `RefillProvider`
   now stream from Cloud Firestore instead of holding hardcoded lists.
   Data survives an app restart.
2. **No real auth / no RBAC routing** → `AuthProvider` uses Firebase
   Authentication. Registration requires picking a role (Customer or
   Pharmacy Staff), stored in a `users/{uid}` Firestore doc. `AuthGate`
   (the app's root widget) restores the session on cold start and routes
   straight to the correct home screen for that role. Staff-only routes
   are wrapped in `StaffOnly`, which bounces a non-staff session back to
   Home instead of rendering the screen.
3. **Drug vs Medicine split** → collapsed into a single `Drug` model
   (`lib/models/drug.dart`) backed by one `drugs` Firestore collection.
   Both the customer catalog and the staff Inventory screen read/write
   the same record, so a stock edit in Inventory is immediately visible
   as "units available" to customers. Placing an order also decrements
   `stockQuantity` in the same Firestore transaction as the order write.
4. **No automated tests** → `test/` now has real unit tests for the
   `Drug` low-stock logic, `Order`/`OrderItem` total calculations, and
   `CartProvider`, plus widget tests for `DrugCard`. Run with:
   ```
   flutter test
   ```

## Firebase setup (do this before running the app)

You need your own Firebase project — this can't be pre-configured for
you since it's tied to a Google account.

1. Go to the [Firebase Console](https://console.firebase.google.com) and
   create a new project (any name, e.g. `pharmconnect-g13`).
2. Enable **Authentication → Sign-in method → Email/Password**.
3. Enable **Firestore Database** (start in production mode; you'll paste
   in the rules below).
4. In Firestore → Rules, paste the contents of `firestore.rules` from
   this repo and publish.
5. Install the FlutterFire CLI (one-time, needs the Firebase CLI too):
   ```
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```
6. From the project root, run:
   ```
   flutterfire configure
   ```
   Select your Firebase project, then select **android** as the
   platform. This overwrites `lib/firebase_options.dart` with your real
   config and drops a `google-services.json` into `android/app/`.
7. `flutter pub get`, then run the app on a device/emulator.
8. Register once as **Pharmacy Staff**, open Inventory, and tap
   **"Seed sample data"** to populate the catalog (12 sample drugs across
   Pain Relief / Antibiotics / Vitamins / Cold & Flu) — matches Day 3 of
   the coding outline. Register a second account as **Customer** to test
   the full FR1–FR12 flow end to end.

## Known follow-ups (not in this pass)

- Widget tests for screens wired to `AuthProvider`/`DrugProvider`/etc.
  need a Firebase test harness (`firebase_auth_mocks`,
  `fake_cloud_firestore`) to run without hitting a real project —
  worth adding before Day 19 of the outline.
- `Order`/`RefillRequest` deletes are hard deletes; consider soft-delete
  (a `cancelled` status) if the rubric wants a full audit trail.
- Firestore rules assume a `users/{uid}` doc always exists before other
  writes — `AuthProvider.register()` guarantees that ordering, so don't
  reorder those calls if you touch that code.
