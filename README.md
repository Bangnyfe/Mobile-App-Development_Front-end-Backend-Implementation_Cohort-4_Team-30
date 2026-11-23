# Pharmacy Inventory & POS

A Flutter and Firebase app for small pharmacies in Rwanda. It tracks stock
by batch and expiry date, handles sales at the counter with a barcode
scanner, and warns staff when stock is low or medicines are about to expire.

## Demo video: 
**Link**: https://youtu.be/RPRhCax65qA

## What it does

| Tab | What you can do |
|-----|-----------------|
| Home | See today's sales, low-stock and expiring counts, recent sales, and stock alerts. |
| Sell | Scan or search for a product, build a cart, take payment and show the receipt. Batches are sold first-expiry, first-out (FEFO), and expired batches can't be sold. |
| Stock | Browse the inventory with search and filters (All, Low stock, Expiring soon, Expired), open a product to see its batches, add stock, register new products and remove stock (expired, damaged and so on). |
| Reports | Sales history with sale details, an inventory report, and an expiry and waste report. |
| Settings | Pharmacy profile, staff and invites, product categories, the low stock threshold and expiry alert period, and log out. |

Other things worth knowing:

- You can sign in with email and password or with Google. Email accounts
  have to be verified, and there is a password reset.
- The owner creates the pharmacy and invites pharmacists by email.
- Scanning the GS1 DataMatrix code on a medicine pa# Mobile-App-Development_Front-end-Backend-Implementation_Cohort-4_Team-30ck fills in the batch
  number and expiry date.
- Stock alerts are worked out on the phone from the products and batches,
  so there is no separate notifications collection to keep in sync. They
  show up in the app under the bell; nothing is pushed to the phone.
- Money is always stored as whole Rwandan francs (an `int`).

## Roles

| | Owner | Pharmacist |
|---|:---:|:---:|# Mobile-App-Development_Front-end-Backend-Implementation_Cohort-4_Team-30
| Sell, view stock and reports | Yes | Yes |
| Register products, add batches and categories | Yes | Yes |
| Lower a batch's quantity (selling, removing stock) | Yes | Yes |
| Edit a product, its price or reorder level | Yes | No |
| Edit or delete batches, delete products or categories | Yes | No |
| Edit the pharmacy profile, invite staff | Yes | No |

The app hides owner-only controls from pharmacists, and
[`firestore.rules`](firestore.rules) rejects those writes on the server as
well, so the limits hold even outside the app.

## Tech stack

- Flutter (Dart `^3.13.2`)
- State management: `flutter_bloc` with `equatable`. Auth uses a BLoC; the
  rest of the app uses Cubits.
- Navigation: `go_router` with a bottom-tab shell
- Backend: Firebase Authentication and Cloud Firestore
- Barcode scanning: `mobile_scanner`
- Settings stored on the phone: `shared_preferences`
- Testing: `flutter_test`, `bloc_test` and `mocktail`

## Project structure

```
lib/
├── main.dart              # Starts Firebase and wires up the real repositories
├── app.dart               # Providers, theme and router
├── core/                  # Shared code: router, theme, widgets, utils, roles
└── features/
    ├── auth/              # Login, register, verify email, pharmacy setup
    ├── dashboard/         # Home tab
    ├── pos/               # Sell, cart, checkout, receipt
    ├── scanner/           # Shared barcode scanner and GS1 parser
    ├── inventory/         # Stock tab, product details, add stock, register product
    ├── stock_removal/     # Remove stock
    ├── sales/             # Sales history and sale details
    ├── reports/           # Reports hub, inventory and expiry & waste reports
    ├── notifications/     # Stock alerts and the bell
    ├── invites/           # Inviting pharmacists
    └── settings/          # Profile, staff, categories, alert settings
```

Every feature is split the same way:

```
features/<name>/
├── domain/                # Entities, repository interfaces, business rules
├── data/                  # Firestore repositories, plus fakes for tests
└── presentation/          # Cubits/BLoCs, pages and widgets
```

Repositories are interfaces in `domain/`. `main.dart` passes in the
Firestore implementations and the widget tests pass in fakes. The
`CurrentPharmacy` repositories always follow the signed-in user's
pharmacy, so when someone else signs in they never see the previous
user's data.

## Data model

Everything a pharmacy owns lives under `pharmacies/{pharmacyId}`. The ERD
is in [`docs/erd.png`](docs/erd.png) (also as [SVG](docs/erd.svg) and
[PDF](docs/erd.pdf)).

```
users/{uid}                              name, email, role (owner | pharmacist), pharmacyId
invites/{email}                          pending pharmacist invites, keyed by lowercased email
pharmacies/{pharmacyId}                  name, district, city, ownerId,
│                                        defaultReorderLevel, expiryAlertDays
├── categories/{categoryId}
├── products/{productId}                 barcode, name, form, packSize, sellingPrice, reorderLevel
│   └── batches/{batchId}                batchNumber, expiryDate, quantity, costPrice,
│                                        pharmacyId, productId (for collection-group queries)
├── sales/{saleId}                       receiptNo, total, paymentMethod, items[] (embedded)
└── stock_removals/{removalId}           what left the shelf, why, and its cost value
```

Batches also store `pharmacyId` and `productId` so that all of a
pharmacy's batches can be read in a single collection-group query. The
index for that query (`pharmacyId` + `expiryDate`) is in
[`firestore.indexes.json`](firestore.indexes.json); the Stock tab, Home
and the alerts all rely on it.

## Getting started

### Requirements

- Flutter SDK with Dart 3.13.2 or newer (check with `flutter --version`)
- Android Studio and an Android phone or emulator. We built and tested the
  app on Android only; iOS isn't set up for Google sign-in.
- Node.js and the Firebase CLI if you want to deploy the rules
  (`npm install -g firebase-tools`)

### Clone and install

```bash
git clone https://github.com/Bangnyfe/Mobile-App-Development_Front-end-Backend-Implementation_Cohort-4_Team-30.git
cd Mobile-App-Development_Front-end-Backend-Implementation_Cohort-4_Team-30
flutter pub get
```

### Run

```bash
flutter run
```

The app is already connected to our Firebase project, `front-end-backend`
(see `lib/firebase_options.dart` and `android/app/google-services.json`).

A couple of notes:

- Google sign-in only works once your computer's debug SHA-1 has been
  added to the Firebase project. Get it with
  `cd android && ./gradlew signingReport` and ask one of us to add it under
  Project settings > Your apps.
- The scanner needs a real camera. On an emulator you can type the barcode
  instead.

### Try it out

1. Register with an email address, click the link in the verification
   email, then set up your pharmacy. You are now its owner.
2. In Stock, register a product, then add stock with a batch number and
   expiry date.
3. In Sell, scan or search for the product, add it to the cart and check
   out.
4. In Settings > Staff and users, invite a second email address. Register
   with that address, verify it, and you will join the pharmacy as a
   pharmacist.
5. To test scanning without real medicine packs, print [`docs/barcode_sheet.pdf`](docs/barcode_sheet.pdf). Page 1 has product barcodes for Sell, and page 2 has GS1 DataMatrix codes for Add stock.

## Tests

```bash
flutter analyze
flutter test
```

The tests live in `test/` and follow the same layout as `lib/`. There are
unit tests for the business rules (FEFO, change, expiry, GS1 parsing, low
stock), tests for every Cubit and BLoC, tests for the Firestore mappers,
and widget tests for each screen. The widget tests use fake repositories,
so they run without Firebase.

## Deploying the Firestore rules and indexes

```bash
firebase login
firebase deploy --only firestore --project front-end-backend
```

This deploys [`firestore.rules`](firestore.rules) and
[`firestore.indexes.json`](firestore.indexes.json). A new index takes a few
minutes to build; it is ready when it shows as Enabled under Firestore >
Indexes in the Firebase Console.

## Using your own Firebase project

You only need this if you want to run a separate copy.

1. Create a Firebase project, add an Android app, and run
   `flutterfire configure` to regenerate `lib/firebase_options.dart` and
   `android/app/google-services.json`.
2. Under Authentication > Sign-in method, enable Email/Password and Google.
   Email sign-up won't work until Email/Password is enabled.
3. Add your debug SHA-1 under Project settings > Your apps so Google
   sign-in works.
4. Create a Cloud Firestore database and deploy the rules and indexes as
   shown above, using `--project <your-project-id>`.

## How we worked

- Nobody commits straight to `main`.
- Each piece of work gets its own branch, named by type: `feature/...`,
  `fix/...`, `chore/...`, `docs/...` or `test/...`.
- Work goes into `main` through a pull request. We run `flutter analyze`
  and `flutter test` before merging, and teammates merged each other's
  pull requests where possible.
- Commit messages describe the change in plain words, for example "Show
  the signed-in pharmacy's sales on Home".

## Team

Team 30, Cohort 4.

| Member | GitHub | Main parts |
|---|---|---|
| Ahmad Daib | [@Bangnyfe](https://github.com/Bangnyfe) | App shell, Home, Settings, Notifications |
| Brian Nakuwa | [@nakuwa23](https://github.com/nakuwa23) | Authentication, Remove stock, Reports |
| Ayobamidele Aiyedogbon | [@mog-ttw](https://github.com/mog-ttw) | Data layer, ERD, Firestore rules, Inventory |
| Maxime Hirwa | [@MHiirwa](https://github.com/MHiirwa), [@HMaxiime](https://github.com/HMaxiime) | Sell and checkout, testing |