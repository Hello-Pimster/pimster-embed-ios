## Pimster iOS Widgets

### Overview

Pimster’s iOS SDK provides drop‑in widgets to showcase shoppable stories inside your iOS app:

- **Gallery Widget**: A carousel/grid of story previews embedded inline in your UI.
- **Sticky Widget**: A floating story preview pinned to a screen corner.

Both widgets:

- Render via `WKWebView` and open a full‑screen Story Player when a user taps a preview.
- Send analytics events automatically (impressions, story opens).
- Support an optional Add‑to‑Cart callback so you can react to commerce actions.

Minimum requirements: **iOS 14+**, Swift **6.1+**.

---

### Installation (Swift Package Manager)

You can add Pimster using Xcode or your `Package.swift`.

- Xcode steps:

  1. In Xcode: File → Add Package Dependencies…
  2. Enter the package URL: `https://github.com/Hello-Pimster/pimster-embed-ios`
  3. Choose the latest version and add the library product `PimsterEmbed`.

- `Package.swift` example:

```swift
dependencies: [
    .package(url: "https://github.com/Hello-Pimster/pimster-embed-ios", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "PimsterEmbed", package: "PimsterEmbed")
        ]
    )
]
```

**Version Strategy**: Using `from: "1.0.0"` automatically includes all compatible versions (1.0.x, 1.1.x, etc.) following semantic versioning. For more control, you can use exact versions like `.exact("1.0.0")`.

**Note**: The package provides a unified `PimsterEmbed` product that includes both `PimsterGalleryWidget` and `PimsterStickyWidget` modules.

Modules to import in your app code:

- `PimsterGalleryWidget` for the Gallery widget
- `PimsterStickyWidget` for the Sticky widget
- `PimsterEmbedCore` for shared types

No Info.plist changes are required under normal ATS policies. If your app enforces a strict ATS that blocks Pimster's domains, allow‑list the Pimster production domains provided by your contact.

---

### Quick Start (SwiftUI)

#### Gallery Widget (inline)

```swift
import SwiftUI
import PimsterGalleryWidget
import PimsterEmbedCore

struct ProductView: View {
    func handleAddToCart(_ payload: AddToCartPayload) -> AddToCartResponse {
        // Add the referenced product to your cart
        print("Add to cart:", payload.product.id, "variant:", payload.variant.id)

        // Process the add to cart and return response
        // This would typically involve your e-commerce integration
        do {
            // Your e-commerce logic here
            // let success = await addToCart(payload.product, variant: payload.variant)

            // Return success response
            return AddToCartResponse.success()
        } catch {
            // Return error response
            return AddToCartResponse.error("Failed to add item to cart")
        }
    }

    let config = GalleryWidgetConfig(
        company: "your_company",
        moduleId: 75,                 // your module ID
        product: "your_product_slug",// optional; defaults to "default"
        animations: [.autoplay],
        display: .square,
        justify: .right,
        height: 180
    )

    var body: some View {
        VStack(spacing: 16) {
            // Your content above…
            GalleryWidget(config: config, addToCartCallback: handleAddToCart)
                .createSwiftUIView()
            // Your content below…
        }
        .onAppear {
            // Optional: Set current screen for analytics context
            AnalyticsManager.shared.setCurrentScreen("ProductView")
        }
    }
}
```

#### Sticky Widget (floating)

```swift
import SwiftUI
import PimsterStickyWidget
import PimsterEmbedCore

struct HomeView: View {
    func handleAddToCart(_ payload: AddToCartPayload) -> AddToCartResponse {
        print("Add to cart:", payload.product.id, "variant:", payload.variant.id)

        // Process the add to cart and return response
        // This would typically involve your e-commerce integration
        do {
            // Your e-commerce logic here
            // let success = await addToCart(payload.product, variant: payload.variant)

            // Return success response
            return AddToCartResponse.success()
        } catch {
            // Return error response
            return AddToCartResponse.error("Failed to add item to cart")
        }
    }

    let config = StickyWidgetConfig(
        company: "your_company",
        storyId: 1077,                // story ID to preview
        product: "your_product_slug",// optional; defaults to "default"
        display: .round,
        placement: .bottomRight,
        width: 120,
        height: 120
    )

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Your page content

            StickyWidget(config: config, addToCartCallback: handleAddToCart)
                .createSwiftUIView()
                .padding(.trailing, 12)
                .padding(.top, 12)
                .zIndex(1)
        }
    }
}
```

The Story Player opens as a `.sheet` automatically when a story is tapped, then dismisses itself when the user closes it.

---

### UIKit Integration

If you are not using SwiftUI, you can embed the widgets via a hosting controller:

```swift
import UIKit
import SwiftUI
import PimsterStickyWidget // or PimsterGalleryWidget
import PimsterEmbedCore

final class WidgetHostViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let config = StickyWidgetConfig(
            company: "your_company",
            storyId: 1077
        )

        func handleAddToCart(_ payload: AddToCartPayload) -> AddToCartResponse {
            // Your e-commerce logic here
            return AddToCartResponse.success()
        }

        let vc = StickyWidget(config: config, addToCartCallback: handleAddToCart)
            .createUIKitView()

        addChild(vc)
        view.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            vc.view.topAnchor.constraint(equalTo: view.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        vc.didMove(toParent: self)
    }
}
```

---

### Configuration Reference

Common fields (both widgets):

- **company**: String (required) – Your Pimster company identifier.
- **product**: String (optional, default "default") – Product slug used by the Story Player URL.
- **display**: `StoryPreviewDisplay` – `.round` or `.square`.
- **animations**: `[StoryPreviewAnimation]` – any of `.pulse`, `.autoplay`, `.onHover`.
- **borderColor**: String (hex) – Preview border color.
- **withPlayIcon**: Bool (default `true`).
- **withRadius**: Bool (default `true`).
- **withTitle**: Bool (default `true`) – Note: For Gallery widgets, this maps to `withStoryTitle` in the web configuration. For Sticky widgets, it maps to `withTitle`.

Gallery‑specific:

- **moduleId**: Int (required) – The module to render.
- **justify**: `GalleryJustify` – `.left`, `.right`, `.center`, `.evenly`.
- **height**: Double – Container height in points.

Sticky‑specific:

- **storyId**: Int (required) – The story to preview.
- **placement**: `StickyPlacement` – `.topLeft`, `.topRight`, `.bottomLeft`, `.bottomRight`.
- **width** / **height**: Double – Container size in points.

Types come from `PimsterEmbedCore`:

- `StoryPreviewDisplay`, `StoryPreviewAnimation`, `GalleryJustify`, `StickyPlacement`, `WidgetType`
- `AddToCartPayload`, `Product`, `ProductVariant`, and `Source`

---

### Add‑to‑Cart Callback

When a user performs an add‑to‑cart action inside a story, your callback receives an `AddToCartPayload` and must return an `AddToCartResponse`:

```swift
func handleAddToCart(_ payload: AddToCartPayload) -> AddToCartResponse {
    // Access product and variant information
    let product = payload.product
    let variant = payload.variant

    // product.id, product.source.provider, product.source.metadata
    // variant.id, variant.gtin, variant.source.provider, variant.source.metadata

    // Process the add to cart and return response
    do {
        // Your e-commerce logic here
        // let success = await addToCart(product, variant: variant)

        // Return success response
        return AddToCartResponse.success()
    } catch {
        // Return error response
        return AddToCartResponse.error("Failed to add item to cart")
    }
}
```

`AddToCartPayload` contains the following fields:

- **product**: `Product` – The main product information
- **variant**: `ProductVariant` – Selected variant details

`Product` fields:

- **id**: String – Pimster shoppable identifier
- **source**: `Source` – Contains provider and metadata information

`ProductVariant` fields:

- **id**: String – Pimster shoppable variant identifier
- **gtin**: String? – Global Trade Item Number if available (optional)
- **source**: `Source` – Contains provider and metadata information

`Source` fields:

- **provider**: String – The commerce provider (e.g., Shopify, Magento, custom)
- **metadata**: [String: String] – Metadata from the product feed

`AddToCartResponse` contains:

- **success**: Bool – Whether the add‑to‑cart was successful
- **error**: String? – Error message if unsuccessful

You can create responses using convenience methods:

- `AddToCartResponse.success()` – For successful operations
- `AddToCartResponse.error(String)` – For failed operations

The SDK automatically sends the response back to the story, allowing it to show success/error states and potentially redirect to a cart page.

---

### Analytics

The SDK automatically tracks widget impressions and story opens for both widgets. **No additional setup is required** - the analytics system automatically extracts rich context information.

#### Automatic Analytics Context

The SDK automatically provides comprehensive analytics context including:

**Automatically Extracted Information:**

- **App Info**: Bundle ID, app name, version, build number
- **Device Info**: Model, OS version, screen dimensions, orientation
- **Context**: Locale, timezone, enhanced user agent
- **Session**: Unique session ID, timestamps

**Optional Screen Context Enhancement:**

If you want to track the current screen/view for better analytics context:

```swift
import PimsterEmbedCore

// Simple: Set current screen for analytics context
AnalyticsManager.shared.setCurrentScreen("ProductDetailView")
```

**Note**: This is completely optional. The SDK works perfectly without any custom context configuration and will automatically extract all available app and device information.

---

### Troubleshooting

- **Nothing appears**: Verify `company`, `moduleId` (Gallery) or `storyId` (Sticky) are valid and published. Ensure network access is available.
- **Strict ATS blocks content**: Allow‑list Pimster’s domains if your app enforces non‑default ATS rules.
- **Widget clipped or invisible**: Ensure you set appropriate `height` (Gallery) or `width`/`height` (Sticky) and your layout provides space.
- **Story Player doesn’t open**: Confirm taps reach the web view and that `.sheet(isPresented:)` isn’t intercepted by other presentation logic.
- **Add‑to‑Cart not received**: Confirm you pass a non‑nil callback and handle it on the main app side. The callback must return an `AddToCartResponse` and accept an `AddToCartPayload` parameter.

---

### FAQ

- **Does the player manage its own lifecycle?** Yes. The SDK presents the player via `.sheet` and dismisses it when closed.
- **Can I customize the player UI?** Not yet. Contact Pimster for roadmap details.
- **Can I theme preview styles?** Use `display`, `borderColor`, `withPlayIcon`, `withRadius`, and `withTitle` in the config.
- **Is UIKit supported?** Yes, use `.createUIKitView()` and embed the returned `UIViewController`.

---

### Support

For integration help or environment access, contact your Pimster representative or email your Pimster support channel.
