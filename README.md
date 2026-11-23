# Pharmacy Inventory & POS (Team 30)

A Flutter + Firebase app for small pharmacies in Rwanda. It tracks stock by
batch and expiry date, sells at the counter with a barcode scanner, and
warns staff about low stock and medicines about to expire.

Built for *Mobile App Development: Front-end & Backend Implementation*,
Cohort 4, Team 30.

---

## What it does

| Tab | What you can do |
|-----|-----------------|
| **Home** | Today's sales, low-stock and expiring counts, recent sales, and the notifications bell. |
| **Sell** | Scan or search a product, build a cart, take payment and show the receipt. Batches are sold **first-expiry, first-out (FEFO)**, and expired batches can't be sold. |
| **Stock** | Inventory list with search and filter chips (All, Low stock, Expiring soon, Expired). Product details with its batches. **Add stock** (scan → batch details → confirm), **Register product**, and **Remove stock** (expired, damaged, ...). |
| **Reports** | Sales history and sale details, Inventory report, and Expiry & waste report. |
| **Settings** | Pharmacy profile, staff and invites, categories, alert settings, and log out. |

**Other features**
- Email/password and Google sign-in, with email verification and password reset.
- An owner creates the pharmacy, then invites pharmacists by email.
- GS1 DataMatrix barcodes on medicine packs fill in the batch number and expiry date.
- Stock alerts are worked out on the phone from products and batches, so there is no separate notifications collection to keep in sync.
- All money is stored as whole Rwandan francs (`int` RWF).

## Roles

| | Owner | Pharmacist |
|---|:---:|:---:|
| Sell, view stock and reports | ✅ | ✅ |
| Register products, add batches, add categories | ✅ | ✅ |
| Lower a batch's quantity (selling, removing stock) | ✅ | ✅ |
| Edit a product, its price or reorder level | ✅ | ❌ |
| Edit or delete batches, delete products or categories | ✅ | ❌ |
| Edit the pharmacy profile, invite staff | ✅ | ❌ |

These limits are enforced in two places: the app hides owner-only
controls from pharmacists, and [`firestore.rules`](firestore.rules) refuses
the writes.

---

## Tech stack

- **Flutter** (Dart `^3.13.2`)
- **State management:** `flutter_bloc` (BLoC for auth, Cubits elsewhere) with `equatable`
- **Navigation:** `go_router`, with a bottom-tab shell
- **Backend:** Firebase Auth and Cloud Firestore
- **Scanning:** `mobile_scanner`
- **On-device settings:** `shared_preferences`
- **Tests:** `flutter_test`, `bloc_test`, `mocktail`

## Project structure

Each feature has the same three layers:

```
lib/
├── main.dart              # Starts Firebase and wires the real repositories
├── app.dart               # Providers, theme and router
├── core/                  # Shared code: router, theme, widgets, utils, roles
└── features/
    ├── auth/              # Login, register, verify email, pharmacy setup
    ├── dashboard/         # Home tab
    ├── pos/               # Sell, cart, checkout, receipt
    ├── scanner/           # Shared barcode scanner and GS1 parser
    ├── inventory/         # Stock tab, product details, add stock, register product
    ├── stock_removal/     # Remove stock flow
    ├── sales/             # Sales history and sale details
    ├── reports/           # Reports hub, inventory and expiry & waste reports
    ├── notifications/     # Stock alerts and the bell
    ├── invites/           # Inviting pharmacists
    └── settings/          # Profile, staff, categories, alert settings

features/<name>/
├── domain/                # Entities, repository interfaces, pure rules
├── data/                  # Firestore repositories and fakes for tests
└── presentation/          # Cubits/BLoCs, pages and widgets
```

Each repository is defined as an interface in `domain/`. `main.dart` passes
the Firestore versions, while widget tests use the fakes. `CurrentPharmacy…`
repositories follow the signed-in user's pharmacy, so a new sign-in never
sees the previous user's data.

---

## Data model

All of a pharmacy's data lives under `pharmacies/{pharmacyId}`. The
diagram is in [`docs/erd.png`](docs/erd.png), with
[`erd.svg`](docs/erd.svg) and [`erd.pdf`](docs/erd.pdf) copies.

```
users/{uid}                              name, email, role (owner | pharmacist), pharmacyId
invites/{email}                          pending pharmacist invites, keyed by lowercased email
pharmacies/{pharmacyId}                  name, district, city, ownerId, alert defaults
├── categories/{categoryId}
├── products/{productId}                 barcode, name, form, packSize, sellingPrice, reorderLevel
│   └── batches/{batchId}                batchNumber, expiryDate, quantity, costPrice,
│                                        pharmacyId, productId (for collection-group queries)
├── sales/{saleId}                       receiptNo, total, paymentMethod, items[] (embedded)
└── stock_removals/{removalId}           what left the shelf, why, and its cost value
```

[`firestore.indexes.json`](firestore.indexes.json) contains a
collection-group index on `batches` (`pharmacyId` + `expiryDate`). The
Stock tab, Home and alerts use it to read every batch in one query.

---

## Getting started

### 1. Requirements

- Flutter SDK with Dart **3.13.2 or newer** (`flutter --version`)
- Android Studio or Xcode, with an emulator or a real phone
- For deploying rules: Node.js and the Firebase CLI (`npm install -g firebase-tools`)

### 2. Clone and install

```bash
git clone https://github.com/Bangnyfe/Mobile-App-Development_Front-end-Backend-Implementation_Cohort-4_Team-30.git
cd Mobile-App-Development_Front-end-Backend-Implementation_Cohort-4_Team-30
flutter pub get
```

### 3. Run

```bash
flutter run
```

The app already points at the team's Firebase project, `front-end-backend`
(see `lib/firebase_options.dart` and `android/app/google-services.json`).

> **Google sign-in on Android** works only after your computer's debug
> SHA-1 is added to the Firebase project. Get it with
> `cd android && ./gradlew signingReport`, then ask a project owner to add
> it under *Project settings → Your apps*.
> The barcode scanner needs a real camera, so use a phone; on an emulator,
> type the barcode instead.

### 4. Try it

1. Register with email, open the verification link, then **set up your pharmacy**. You are now its owner.
2. **Stock → Register product**, then **Add stock** with a batch and expiry date.
3. **Sell**: scan or search the product, add it to the cart and check out.
4. **Settings → Staff**: invite a second email. Signing in with that email joins as a pharmacist.

---

## Tests and checks

```bash
flutter analyze
flutter test
```

Tests sit in `test/` and mirror the layout of `lib/`. They cover domain
rules (FEFO, change, expiry, GS1 parsing, low stock), every Cubit/BLoC, the
Firestore mappers, and widget tests for each screen. Widget tests use fake
repositories, so they don't need Firebase.

## Deploying Firestore rules and indexes

```bash
firebase login
firebase deploy --only firestore --project front-end-backend
```

This deploys [`firestore.rules`](firestore.rules) and
[`firestore.indexes.json`](firestore.indexes.json). New indexes take a few
minutes to build: wait until they show **Enabled** under
*Firebase Console → Firestore → Indexes*.

---

## How we work

- `main` is always releasable. Nobody commits to it directly.
- One branch per piece of work, named by type: `feature/…`, `fix/…`, `chore/…`, `docs/…`, `test/…`.
- Open a pull request into `main`. Run `flutter analyze` and `flutter test` first, and get a teammate's review before merging.
- Commit messages say what the change does, in plain words (e.g. *"Show the signed-in pharmacy's sales on Home"*).

## Team

Team 30, Cohort 4. Contributors on GitHub:
[@Bangnyfe](https://github.com/Bangnyfe) ·
[@nakuwa23](https://github.com/nakuwa23) ·
[@MHiirwa](https://github.com/MHiirwa) ·
[@HMaxiime](https://github.com/HMaxiime) ·
[@mog-ttw](https://github.com/mog-ttw)
