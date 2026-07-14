# Top 10 Places — Migration Plan

Target: iOS 18+, Xcode 26, Combine (not `@Observable`), Coordinator pattern for navigation, SwiftData, Swift Testing.

## Why Combine over `@Observable`

`@Observable` (the Observation framework) doesn't emit Combine `Publisher`s — there's no `$property` projected value or `objectWillChange` to `.sink` into. `@Published`/`ObservableObject` is the Combine-native option, which matters here because the pipelines we want (`location → search`, `combineLatest(location, category, searchText)`) rely on Combine operators (`flatMap`, `switchToLatest`, `debounce`, `combineLatest`). View-side bindings (`@ObservedObject`, `@State`, `@Binding`) don't change — only the ViewModel/service internals move to explicit Combine chains instead of manual delegate callbacks + `async/await`.

## Current architecture (baseline)

- **MVVM**, single-screen SwiftUI app, no third-party dependencies.
- `LocationManager` — wraps `CLLocationManager`, exposes a custom `LocationManagerDelegate` protocol.
- `MapService` — calls the **HERE Browse API** directly (hardcoded API key in source — flagged vulnerability), decodes JSON into `Place`, caches results in Core Data as a raw JSON blob.
- `RankingPlacesViewModel` — `ObservableObject`, delegate callbacks + `async/await`, no Combine yet.
- `MainView` — deprecated `Map(coordinateRegion:annotationItems:)` + `MapAnnotation`; navigation/popups are hand-rolled `@State` booleans and `ZStack` overlays, including a `DispatchQueue.main.asyncAfter(0.5)` sequencing hack.
- `Top10PlacesTests` — XCTest, covers ViewModel, LocationManager, extensions, with mocks.
- Deployment target: iOS 16.4, Swift 5.0.

## Phase 0 — Project baseline

- Bump `IPHONEOS_DEPLOYMENT_TARGET` to 18.0 (both build configs).
- Consider enabling Swift 6 strict concurrency checking now, since concurrency-adjacent code (LocationManager, MapService, Combine sinks) is being rewritten anyway — better to catch actor-isolation issues during the rewrite than after.

## Phase 1 — Replace HERE API with MapKit

- Remove `MapService`'s HERE Browse API call and the hardcoded API key entirely.
- Replace with `MKLocalSearch` (or `MKLocalPointsOfInterestRequest` for category-filtered POIs).
- `MKLocalSearch` has no native Combine publisher — wrap it manually, using `Deferred` so the search only fires on subscription, not on publisher creation:

```swift
func searchPlaces(near coordinate: CLLocationCoordinate2D) -> AnyPublisher<[Place], Error> {
    Deferred {
        Future { promise in
            let request = MKLocalSearch.Request()
            request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
            MKLocalSearch(request: request).start { response, error in
                if let error { promise(.failure(error)); return }
                promise(.success(response?.mapItems.map(Place.init) ?? []))
            }
        }
    }.eraseToAnyPublisher()
}
```

## Phase 2 — LocationManager as a Combine publisher

- Drop the custom `LocationManagerDelegate` protocol.
- Internally still conform to `CLLocationManagerDelegate` (no native Combine support), but expose:
  - `@Published var authorizationStatus: CLAuthorizationStatus`
  - a `PassthroughSubject<CLLocation, Never>` (or `CurrentValueSubject`) for location updates, exposed as `AnyPublisher`.

**Concurrency rationale (not just modernization).** Under Swift 6 language mode, `RankingPlacesViewModel` conforming directly to the custom `LocationManagerDelegate` protocol creates actor-isolation friction between the ViewModel and however CoreLocation's `CLLocationManagerDelegate` callbacks are delivered — hit this firsthand when trying to set `locationManager.delegate = self` in the ViewModel's `init()`. Dropping the delegate conformance on the ViewModel entirely (in favor of subscribing to a publisher) removes this problem structurally rather than papering over it: `LocationManager` absorbs the raw `CLLocationManagerDelegate` callbacks and re-isolates them internally, exposing only Combine publisher values. The isolation boundary is handled in one place instead of leaking through a protocol conformance on the ViewModel. Not worth fixing the old delegate assignment in the meantime — comment it out with a TODO pointing at this phase.

## Phase 3 — ViewModel as a Combine pipeline

Replace the delegate-driven `didGetUpdatedLocation` flow with a subscription chain:

```swift
locationManager.locationPublisher
    .removeDuplicates()
    .flatMap { [mapService] location in
        mapService.searchPlaces(near: location.coordinate)
            .catch { _ in Just([]) }
    }
    .receive(on: DispatchQueue.main)
    .assign(to: &$places)
```

Depends on Phases 1 and 2.

## Phase 4 — Core Data → SwiftData

Current model is trivial: two entities (`Places`, `UserLocation`), one relationship, no migration history, no `NSFetchedResultsController` in the UI — this should be a clean, low-risk migration.

- `NSManagedObject` subclasses → `@Model` classes.
- `NSPersistentContainer` (`Persistence.swift`) → `ModelContainer`, wired via `.modelContainer(for:)` on `WindowGroup`.
- `NSFetchRequest` + `NSPredicate` (in `MapService`) → `FetchDescriptor` + `#Predicate`.
- **Worth doing at the same time (optional but recommended):** stop storing places as a raw JSON blob (`Places.json`) that gets re-decoded on every read. Since `Place` is already `Codable` with clean fields, model it as its own `@Model` keyed by lat/long instead. Removes a serialize/deserialize layer and gets real predicates instead of string-matching into a blob. Natural to do while already touching `MapService` for Phase 1.

## Phase 5 — AppCoordinator + Map API modernization

Two changes that pair naturally, both touching `MainView`:

**Coordinator.** Replace the four independent `@State` booleans (`showPlaceListPopup`, `showGroupedPlacesListPopup`, `selectedPlace`, `showNeedsPermissionAlert`) and the `asyncAfter` sequencing hack with an `AppCoordinator: ObservableObject` owning a single `@Published var route: Route?` enum (`.placeList`, `.groupedList(Place)`, `.callout(Place)`, `.permissionAlert`). Inject via `@EnvironmentObject` or constructor. Pair with native SwiftUI presentation modifiers (`.sheet(item:)`, `.popover(item:)`, or a custom `.overlay(item:)` transition) driven off `route`, instead of hand-rolled `ZStack` + `Color.clear.opacity` + `onTapGesture`-to-dismiss.

**Map API.** `Map(coordinateRegion:showsUserLocation:annotationItems:)` + `MapAnnotation` is deprecated since iOS 17. Migrate to the `MapContentBuilder` API:

```swift
@State private var cameraPosition: MapCameraPosition = .region(...)

Map(position: $cameraPosition) {
    ForEach(viewModel.places) { place in
        Annotation(place.name, coordinate: place.position.coordinate) {
            MapPinWithTitle(place: place) { ... }
        }
    }
    UserAnnotation()
}
```

Existing custom pin views (`MapPinWithTitle`, `InfoAnnotation`) drop in unchanged inside `Annotation { }`. **Decision made:** skip the native `Map(selection:)` + `MapItemDetailSelectionAccessory` callout — it's Apple-Maps-styled and less flexible than the existing custom `MapPinCallout` (rank, distance, lat/lng). Keep the manual `selectedPlace` + custom callout, just recoded against the new Map API.

Depends on Phase 3 (needs the new ViewModel state shape).

## Phase 6 — XCTest → Swift Testing

Low-risk given the suite is small (ViewModel, LocationManager, extensions — no UI tests). Conversion pattern:

- `class X: XCTestCase` → `struct`/`final class` with `import Testing`.
- `func testX()` → `@Test func x()`.
- `XCTAssertEqual(a, b)` → `#expect(a == b)`; `XCTAssertNotNil(x)` → `#expect(x != nil)` or `#require(x)` to unwrap-and-continue.
- `setUp()`/`tearDown()` → `init()`/`deinit` (Swift Testing instantiates fresh per test by default — less boilerplate than XCTest here).
- `MockLocationManager`/`MockPlaces` need no changes — Swift Testing doesn't care how test doubles are built.
- Async tests simplify: no `XCTestExpectation`, just `await` directly in an `async @Test func`.

Independent of the other phases — can move first or last.

## Suggested order

Phase 0 → Phase 6 (tests, doesn't block anything) → Phase 4 (SwiftData) → Phase 1 + Phase 2 (networking + location, no dependencies on each other) → Phase 3 (ViewModel, depends on 1+2) → Phase 5 (Coordinator + Map API, depends on 3).

## Deferred: category filter + text search (post-migration)

Not part of the base migration — revisit once Phases 0–6 land.

- **Category button** (restaurant / cafe / shop): stays true to the "top 10 nearest" concept — re-scopes the same ranked-by-distance list to a subset of place types, still capped at 10.
- **Free-text search field**: different interaction model. Capping at a fixed count regardless of relevance is the wrong call here — if someone searches for a specific place, they want it even if it's the 14th-closest result. Recommendation: text search relaxes the "top 10" cap (scroll instead of hard truncation) rather than forcing every interaction through the same number.
- **Combine shape**, once implemented — `combineLatest` across three independent sources, with `switchToLatest` (not `flatMap`) so a new keystroke or category selection cancels the in-flight `MKLocalSearch` instead of letting superseded requests race to update `places`:

```swift
Publishers.CombineLatest3(
    locationManager.locationPublisher,
    $selectedCategory,
    $searchText.debounce(for: .milliseconds(350), scheduler: DispatchQueue.main).removeDuplicates()
)
.map { [mapService] location, category, text in
    mapService.search(near: location.coordinate, category: category, query: text)
}
.switchToLatest()
.receive(on: DispatchQueue.main)
.assign(to: &$places)
```

- `MKLocalSearch.Request` supports `naturalLanguageQuery` and `pointOfInterestFilter` simultaneously, so category + text can compose into a single request rather than needing two separate search paths.

## Deferred: Phase 7 — on-device AI place summary (Apple Foundation Models)

Not part of the base migration — revisit after Phases 0–6 and the category/search feature land.

**Idea:** use Apple's on-device Foundation Models framework (iOS 26) to generate a short natural-language summary/blurb for a selected place.

**Accuracy consideration.** The on-device model is a ~3B-parameter model tuned for focused text tasks — summarization, entity extraction, classification, rewriting — not for open-ended reasoning or world knowledge. It must not be asked to "tell me about this place" from nothing, since it has no facts about the real world and will invent details. Instead, ground it: feed it the structured data already available from MapKit (name, category, address, distance, phone/hours if present) and have it synthesize that into a friendly one- or two-line blurb. Used this way, accuracy is bounded by the input data, not by the model guessing.

**No deployment target change needed.** Requirements are iOS 26 + A17 Pro/M1 chip or newer, plus the user having Apple Intelligence enabled. Keep the app's deployment target at iOS 18 and gate only this feature with `@available(iOS 26, *)` plus a runtime check of `SystemLanguageModel.default.availability`, with a graceful fallback (plain address/category text) for devices that don't qualify. Raising the whole app's deployment target to 26 would needlessly cut off iOS 18–25 users for one optional feature.

**Implementation shape:**
- Define a `@Generable` struct for the output, e.g. `struct PlaceSummary { var blurb: String; var vibe: String }` — guided generation returns this struct directly instead of free text to parse. Properties are generated in declaration order, so put the summary field last so the model reasons over the grounding data first.
- Build the prompt entirely from data already fetched via `MKLocalSearch`/`MKMapItem` (Phase 1), with explicit instructions not to add facts not present in the input.
- Trigger lazily per-place (e.g. on callout open), not eagerly for all 10 results — it's a local inference cost even on-device.
- Wrap `LanguageModelSession.respond(to:generating:)` (async) the same way `MKLocalSearch` is wrapped — `Deferred { Future { ... } }` — so it fits the existing Combine-based architecture instead of being an async island.
</content>
