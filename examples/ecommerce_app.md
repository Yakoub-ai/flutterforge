# Recipe: E-Commerce App with Stripe Payments

## What We're Building

A mobile e-commerce app with a product catalog fetched from a REST API, a shopping cart with quantity management, a checkout flow, and Stripe payment processing. The app covers product listing, product detail, cart management, order summary, and a payment confirmation screen. This recipe shows how to layer multiple `/flutterforge:build-flutter-feature` invocations sequentially and how to use `/flutterforge:audit-flutter-app` partway through development — before adding payments — to catch architectural issues early.

## Prerequisites

- Flutter 3.19+ and Dart on `PATH`
- FlutterForge plugin installed in Claude Code
- A REST API to serve product data — you can use a mock API (e.g., [DummyJSON](https://dummyjson.com/products)) or your own backend
- A Stripe account (free) — you need a Stripe publishable key and a backend endpoint that creates PaymentIntents (Stripe does not allow secret key usage from mobile apps)
- Android emulator or iOS simulator running

---

## Step-by-Step Workflow

### Step 1 — Plan the App

```
/flutterforge:plan-flutter-app "I want to build a Flutter e-commerce app. It should have a product catalog that fetches from a REST API, a product detail screen, a shopping cart with quantity management, an order summary screen, and Stripe payment processing. State management with Riverpod. Clean Material 3 UI with product image support."
```

**What happens:** The product-strategist returns a brief with 3–4 personas (casual browser, deal-hunter, returning buyer) and user stories spanning the full shopping journey: browsing, filtering, cart management, checkout, and post-purchase state.

The UX designer maps out 6–8 screens: product catalog (grid), product detail, cart, order summary, payment, confirmation. It will recommend a persistent cart icon in the app bar with an item count badge.

The Flutter architect will recommend:
- `Riverpod` with `AsyncNotifier` for products and `Notifier` for cart state
- A `ProductRepository` that wraps your HTTP client (`dio` or `http`)
- `flutter_stripe` for payment UI components
- `cached_network_image` for product images
- `go_router` for navigation

**Decision point:** The architect may suggest a `freezed` + `json_serializable` combo for models. This adds code generation to your workflow. Accept it — it pays off in a complex app. If you want to keep it simple, reply:

> "Skip code generation. Use simple Dart classes with hand-written fromJson/toJson."

---

### Step 2 — Scaffold the Project

```
/flutterforge:new-flutter-app
```

After scaffolding, verify the app compiles with `flutter run`.

If you're using DummyJSON as your mock API, no additional setup is needed. If you're using a real backend, add your base URL to a `.env` file (do not hardcode it) and add `flutter_dotenv` to your dependencies.

---

### Step 3 — Build the Product Catalog

```
/flutterforge:build-flutter-feature "Product catalog screen that fetches a list of products from GET /products. Each product has id, title, description, price, thumbnail URL, category, and rating. Display products in a 2-column grid using GridView. Each card shows the thumbnail, title, price, and a star rating. Add a category filter bar at the top. Tapping a product navigates to the product detail screen (stub it for now). Handle loading, error, and empty states."
```

**What happens:** The inspect phase checks your folder structure and existing `pubspec.yaml`. The plan phase shows the `Product` model, the `ProductRepository`, the `productsProvider`, and the grid widget.

**Approval gate:** Confirm the `Product` model matches your API's actual response shape. If DummyJSON returns `thumbnail` but your API uses `image_url`, tell the agent:

> "The API uses 'image_url' instead of 'thumbnail' and 'avg_rating' instead of 'rating'. Please adjust the model."

After implementation, test:
- Products load on startup
- Category filter updates the visible products
- Scrolling works smoothly (check for jank — the agent should be using `cached_network_image`)
- Error state appears if you kill your network

---

### Step 4 — Build the Product Detail Screen

```
/flutterforge:build-flutter-feature "Product detail screen showing the full product: large image (hero animation from catalog), title, full description, price, rating with review count, and an 'Add to Cart' button with quantity selector (+ / - stepper). If the item is already in the cart, show the current cart quantity and an 'Update Cart' button. Navigate back on add/update."
```

**What happens:** The hero animation between the catalog grid and the detail screen is a common request — the agent will wrap the catalog thumbnail in a `Hero` widget and match the tag on the detail screen.

After implementation, verify the hero animation looks smooth. If it stutters, tell the agent:

> "The hero animation is janky. Please add `HeroFlightShuttleBuilder` that fades between the low-res thumbnail and the full image."

---

### Step 5 — Build Cart State and Cart Screen

```
/flutterforge:build-flutter-feature "Shopping cart: (1) A CartNotifier (Riverpod) that manages a list of CartItems (product + quantity). Methods: addItem, removeItem, updateQuantity, clearCart. Cart persists to SharedPreferences as JSON so it survives app restarts. (2) A Cart screen showing all items with product thumbnail, title, unit price, quantity stepper, and remove button. Show order subtotal, estimated tax (10%), and total. A 'Proceed to Checkout' button at the bottom. Show empty state if cart is empty."
```

**What happens:** This is the most stateful feature so far. The plan phase will show the `CartItem` model, the `CartNotifier` with persistence logic, and the cart screen. Review the persistence logic — it serializes the cart to JSON and reads it back on startup.

**Decision point:** The plan may suggest re-fetching product details from the API when restoring the cart (to get fresh prices). This is the correct approach. Accept it — stale prices in the cart are a real-world bug.

After implementation, test persistence: add items to cart, hot-restart the app (not just hot-reload), and verify the cart is restored.

Also verify the cart icon in the app bar shows the correct item count badge. The agent should have wired this up using a `Consumer` widget that watches `cartProvider`.

---

### Step 6 — Mid-Point Audit

Before adding payments, run a full audit to catch issues early. This is much cheaper than finding architectural problems after Stripe is integrated.

```
/flutterforge:audit-flutter-app
```

**What happens:** Five agents run in parallel and produce a combined report. At this stage, the most important findings are typically:

- **Performance:** Are product images causing memory pressure? Is the `CartNotifier` doing unnecessary rebuilds?
- **Architecture:** Is cart state being accessed correctly across screens, or are there scope issues?
- **Codebase:** Are there unused dependencies in `pubspec.yaml` from the scaffold?
- **Tests:** What is the current test coverage? The test engineer will identify the highest-risk uncovered paths.

Work through the report. Do not skip it — payment flows are hard to retrofit onto a shaky foundation.

After the audit, if the performance engineer flagged image memory issues:

```
/flutterforge:build-flutter-feature "Optimize product image loading: set explicit cacheWidth and cacheHeight on all CachedNetworkImage instances proportional to device pixel ratio. Use a placeholder shimmer effect while loading. Evict images from cache when they scroll far off-screen."
```

---

### Step 7 — Build the Checkout / Order Summary Screen

```
/flutterforge:build-flutter-feature "Order summary screen showing the cart items (read-only), delivery address form (name, address line 1, address line 2, city, state, zip, country), order totals (subtotal, shipping flat rate $4.99, tax, total), and a 'Pay Now' button. Validate all address fields before enabling the button. This screen does not process payment yet — the Pay Now button navigates to the payment screen."
```

**What happens:** A form-heavy screen. The agent will use `Form` + `GlobalKey<FormState>` with `TextFormField` validators. The order total calculation should match the cart screen's calculation exactly — the agent should import the same calculation logic, not duplicate it.

**Watch for:** If the plan proposes duplicating the total calculation logic, say:

> "Extract the order total calculation into a shared `OrderTotals` model or utility function used by both the cart screen and the order summary screen. Single source of truth."

---

### Step 8 — Integrate Stripe Payments

Before this step, you need a backend endpoint that creates a Stripe PaymentIntent and returns the `client_secret`. You cannot create PaymentIntents from mobile — your server holds the Stripe secret key. If you don't have a backend yet, you can use a simple Firebase Cloud Function or a Stripe test mode endpoint.

```
/flutterforge:build-flutter-feature "Stripe payment screen using flutter_stripe. On screen load, call POST /create-payment-intent with the order total (in cents) to get a client_secret from the server. Initialize the Stripe PaymentSheet with the client_secret, merchant display name, and Google Pay / Apple Pay enabled (test mode). Present the PaymentSheet. On success, clear the cart and navigate to the order confirmation screen. On cancellation, stay on the payment screen. On error, show the Stripe error message in a SnackBar."
```

**What happens:** The inspect phase reads your existing `pubspec.yaml` to check if `flutter_stripe` is already added. If not, the engineer adds it. The plan phase shows the full payment flow with proper error handling for the three Stripe outcomes: success, cancellation, and failure.

**Critical before approving the plan:** Verify the plan uses the server-side PaymentIntent creation pattern (calling your backend), not a client-side secret key. If the plan references `Stripe.instance.createToken` with a secret key, reject it:

> "Do not use the Stripe secret key on the client. The plan must call our backend POST /create-payment-intent endpoint to get the client_secret, then present the PaymentSheet."

**Stripe test cards:** While testing, use `4242 4242 4242 4242` (any future date, any CVC) for a successful payment. Use `4000 0000 0000 9995` to test a declined card.

---

### Step 9 — Build Order Confirmation Screen

```
/flutterforge:build-flutter-feature "Order confirmation screen shown after successful payment. Display a success animation (Lottie or simple animated checkmark), order number (generate a UUID client-side for now), summary of items ordered, total charged, and an estimated delivery date (today + 5 business days). Buttons: 'Continue Shopping' (pops to catalog root, clearing the back stack) and 'View Order Details' (stub for future feature)."
```

---

### Step 10 — Generate Tests

```
/flutterforge:generate-tests "E-commerce app: unit tests for ProductRepository (mock HTTP client), CartNotifier state transitions (add, remove, update, clear, persistence), order total calculation, and widget tests for ProductCard, CartScreen, and OrderSummaryScreen. Mock stripe calls in the payment flow tests."
```

```bash
flutter test
```

Expect 30–50 test cases for an app of this complexity. Pay special attention to the cart persistence tests — serialize, write to SharedPreferences, recreate the notifier, and verify state is restored correctly.

---

### Step 11 — UX Review

```
/flutterforge:improve-ux "catalog grid, cart screen, and checkout flow"
```

For e-commerce, the UX agent typically prioritizes:
- Pull-to-refresh on the catalog
- Skeleton loading screens instead of a spinner
- Cart quantity stepper accessibility (minimum tap target size)
- The checkout form's keyboard handling (auto-advance between fields, numeric keyboard for zip/phone)
- Error recovery on the payment screen

Implement the suggestions selectively — pull-to-refresh and keyboard handling are high value, decorative animations are low priority for v1.

---

### Step 12 — Final Audit and Release Prep

```
/flutterforge:audit-flutter-app
```

The security reviewer will specifically check:
- No Stripe secret key in source
- No API keys hardcoded (they should be in `.env` or environment variables)
- Network calls use HTTPS

```
/flutterforge:prepare-release
```

For an e-commerce app, the release engineer will flag:
- App icon and splash screen
- App store metadata (description, screenshots, privacy policy URL — required for apps that process payments)
- iOS: `NSPhotoLibraryUsageDescription` if you added any photo picking

---

## Tips for This App Type

**Stripe test vs live mode:** Your Stripe publishable key starts with `pk_test_` in test mode and `pk_live_` in production. Never hardcode the live key. Use environment variables and build flavors to switch between them.

**PaymentIntent amount in cents:** Stripe amounts are always in the smallest currency unit. `$19.99` = `1999` cents. Off-by-100 bugs here will cause incorrect charges — double-check the math in your backend.

**Cart race conditions:** If a user rapidly taps Add to Cart, the `CartNotifier` can receive multiple events before the first completes. Use `Mutex` or debounce the add button to prevent double-adds.

**Image caching strategy:** Product images change infrequently. Set a long cache duration in `CachedNetworkImage` (e.g., 7 days) and use the product's `updatedAt` timestamp as a cache-buster in the URL if needed.

**Pagination:** The catalog recipe above loads all products at once. For a real product catalog with hundreds of items, add infinite scroll after you verify the basic flow works. Use `/flutterforge:build-flutter-feature "Infinite scroll pagination on the product catalog"` as a follow-up.

**Order number:** The recipe generates a UUID client-side. In production, the order number must come from your backend after the PaymentIntent succeeds — otherwise you risk collisions and cannot reconcile orders with Stripe.
