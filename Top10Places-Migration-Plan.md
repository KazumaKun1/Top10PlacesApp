# Top 10 Places — Migration Plan

Target: iOS 26+, Xcode 26, Combine (not `@Observable`), Coordinator pattern for navigation, Swift Testing. No persistence layer (see Phase 4).

**Deployment target note:** originally planned as iOS 18+ to preserve back-compat. Revised to iOS 26+ — this is a personal practice/portfolio rewrite with no real install base to protect, and targeting iOS 26 directly avoids writing around now-deprecated MapKit APIs (see Phase 1) instead of just using their replacements. Trade-off, for the record: iOS 26+ as a minimum means only devices that can run iOS 26 can install the app at all — a materially larger cut than the Foundation Models feature's own A17 Pro/M1 hardware requirement (Phase 7), which is a separate, narrower gate on top of this.

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

- Bump `IPHONEOS_DEPLOYMENT_TARGET` to 26.0 (both build configs). Revised up from the originally planned 18.0 once the `MKMapItem.placemark` deprecation (Phase 1) made targeting iOS 18 more friction than it was worth for a practice project.
- Consider enabling Swift 6 strict concurrency checking now, since concurrency-adjacent code (LocationManager, MapService, Combine sinks) is being rewritten anyway — better to catch actor-isolation issues during the rewrite than after.

## Phase 1 — Replace HERE API with MapKit

- Remove `MapService`'s HERE Browse API call and the hardcoded API key entirely.
- Replace with `MKLocalSearch` (or `MKLocalPointsOfInterestRequest` for category-filtered POIs).
- `MKLocalSearch` has no native Combine publisher, and bridging Combine's `Future` with `async`/`await` under Swift 6 strict concurrency took several iterations to get right (see "Concurrency debugging notes" below for what didn't work and why). Final working shape, split across three pieces:

**1. Reusable async→Combine bridge** (its own file, e.g. `Combine+Concurrency.swift` — reused again in Phase 7 for the Foundation Models call):

```swift
extension Future where Failure == Error {
    convenience init(operation: @escaping @Sendable () async throws -> Output) {
        self.init { promise in
            nonisolated(unsafe) let promise = promise
            Task {
                do {
                    promise(.success(try await operation()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}
```

**2. A stateless, naturally-`Sendable` searcher**, separated out of `MapService` specifically so the search logic never needs to capture `self` across the `@Sendable` boundary — matters regardless of what `MapService` ends up holding, since any non-Sendable state on the class would trip the same error:

```swift
struct MapKitPlaceSearcher: Sendable {
    func searchPlaces(near coordinate: CLLocationCoordinate2D) async throws -> [Place] {
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let request = MKLocalSearch.Request()
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)

        let response = try await MKLocalSearch(request: request).start()
        let sorted = response.mapItems.sorted {
            origin.distance(from: $0.location ?? origin) < origin.distance(from: $1.location ?? origin)
        }

        return sorted.prefix(10).enumerated().map { index, item in
            let actualRank = index + 1
            return Place(mapItem: item, origin: origin, rank: Rank(ordinal: actualRank.ordinalString(), rawValue: actualRank))
        }
    }
}
```

**3. `MapService.getPlaces`** — public Combine-facing entry point, capturing the searcher as a local before the closures (not `self`, not a bare property reference) to avoid both the Sendable-capture and implicit-self diagnostics:

```swift
class MapService: MapServiceProtocol {
    private let searcher = MapKitPlaceSearcher()

    func getPlaces(near coordinate: CLLocationCoordinate2D) -> AnyPublisher<[Place], Error> {
        let searcher = self.searcher

        return Deferred {
            Future {
                try await searcher.searchPlaces(near: coordinate)
            }
        }.eraseToAnyPublisher()
    }
}
```

Note: no `@MainActor` anywhere in this chain. `MapService` doesn't need main-actor isolation — only the ViewModel updating `@Published` UI state does, and that's handled by `.receive(on: DispatchQueue.main)` in the Combine pipeline (Phase 3), not by isolating the whole service.

**`Place`'s new initializer** (in `Place.swift`) — no `placemark` access anywhere:

```swift
extension Place {
    init(mapItem: MKMapItem, origin: CLLocation, rank: Rank) {
        let itemLocation = mapItem.location ?? origin
        let coordinate = itemLocation.coordinate

        self.id = (mapItem.name ?? "") + coordinate.debugDescription
        self.title = mapItem.name ?? "Unknown"
        self.distance = Int(origin.distance(from: itemLocation))
        self.position = Position(lat: coordinate.latitude, lng: coordinate.longitude, coordinate: coordinate)
        self.address = Address(label: mapItem.address?.shortAddress ?? "")
        self.rank = rank
        self.annotationType = .single
    }
}
```

**iOS 26 note:** `MKMapItem.placemark` is deprecated as of iOS 26 (replacement is `MKReverseGeocodingRequest` for reverse-geocoding use cases). Use the new `location` (`CLLocation?`) and `address`/`addressRepresentations` (`MKAddress`, with `fullAddress`/`shortAddress` string properties) properties instead. Since the app's deployment target is iOS 26+, no availability branching is needed — just use the current API directly.

**Concurrency debugging notes (what didn't work, for future reference):**
- Wrapping `MKLocalSearch.start(completionHandler:)` (the old completion-handler API, not the `async throws` one) inside `Future`'s `promise` closure fails with `Sending 'promise' risks causing data races` — the completion handler is `@Sendable`, and Combine's `Future.Promise` isn't, so capturing `promise` across that boundary is rejected. Fix was switching to the `async throws` `start()` variant entirely, removing the completion-handler closure from the picture.
- Wrapping that `await` call in a bare `Task { }` inside `Future`'s closure still fails with `Passing closure as a 'sending' parameter risks causing data races...` — same root cause, `promise` is still a non-`Sendable` value crossing into `Task.init`'s `sending` closure parameter. Fix: `nonisolated(unsafe) let promise = promise`, declared once inside the reusable `Future(operation:)` extension so the workaround lives in one place — legitimate here since Combine's `Future` is documented as safe to fulfill from any thread/queue.
- Capturing `self` (i.e. `MapService`) inside the `@Sendable operation` closure fails with `Capture of 'self' with non-Sendable type 'MapService' in a '@Sendable' closure`, since a plain class isn't `Sendable` by default. Fix: extract the search logic into its own stateless `Sendable` struct (`MapKitPlaceSearcher`) instead of keeping it on `MapService` itself.
- Referencing `searcher` (a stored property) bare inside the closure fails separately with `Reference to property 'searcher' in closure requires explicit use of 'self'` — an older, unrelated "implicit self in closures" rule, not a concurrency error. Fixed by capturing `searcher` into a local `let` before the closures.
- Marking `MapService`/`MapServiceProtocol` as `@MainActor` was tried as a fix and made things worse, not better — it doesn't address the Sendable-crossing rule at all, and this project doesn't have default main-actor isolation set (`SWIFT_DEFAULT_ACTOR_ISOLATION` isn't configured), so nothing is implicitly `@MainActor` here regardless.

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
    .handleEvents(receiveOutput: { [weak self] location in
        self?.location = location
        self?.retrievalStatus = .ongoing
    })
    .flatMap { [mapService] location in
        mapService.getPlaces(near: location.coordinate)
            .map { (LocationRetrievalState.success, $0) }
            .catch { _ in Just((LocationRetrievalState.failure, [])) }
    }
    .receive(on: DispatchQueue.main)
    .sink { [weak self] status, places in
        guard let self else { return }
        self.retrievalStatus = status
        self.places = /* existing grouped-annotation logic */
        self.goToCurrentLocation()
    }
    .store(in: &cancellables)
```

Depends on Phases 1 and 2. (See "Phase 3 review notes" below — the first working pass on the `migration/phase-3` branch got the pipeline shape right but missed wiring `location` and `retrievalStatus` through; the sketch above is the corrected version.)

**Phase 3 review notes (from reviewing the actual `migration/phase-3` branch):**
- `retrievalStatus` never reached `.success` in the first pass — the places `.sink` updated `places` but not `retrievalStatus`, so the status icon stayed stuck on "ongoing" after every successful load. Fixed above by carrying `(status, places)` through the pipeline together.
- `location` was never assigned anywhere after dropping the old delegate method, which silently broke `goToCurrentLocation()` (checks `if let location = self.location`) — the current-location button did nothing, and the map never left the hardcoded default region. Fixed above via `.handleEvents(receiveOutput:)` on the location publisher.
- Errors from `getPlaces` were swallowed by `.catch { _ in Just([]) }` into an empty array with no status change — indistinguishable from "zero results nearby." Fixed by mapping the catch to `.failure` explicitly instead of just an empty array.
- `refreshPlaces()` and the dead `didGetUpdatedLocation(location:)` stub were left commented out on that branch — still open, not addressed by the sketch above. `refreshPlaces()` needs its own small design: likely a `PassthroughSubject<Void, Never>` merged with `locationPublisher` via `Publishers.Merge`, re-emitting the last known location on demand.
- `permissionDeniedPublisher` (in `LocationManager`) only ever sends `true`, never resets to `false` on successful re-authorization — minor, but means `showNeedsPermissionAlert` won't clear itself if a user grants permission in Settings and returns to the app.

## Phase 4 — Remove Core Data, no replacement

Decided against migrating to SwiftData (tracked as a separate practice project instead — see note below). The original justification for a persistence layer no longer applies: Core Data existed to cache HERE API responses because HERE was a paid, rate-limited third-party API. `MKLocalSearch` (Phase 1) has no API key, no billing, and no rate limit for an app this size — the problem the cache solved doesn't exist anymore. Confirmed by inspection: as of Phase 1, `MapService.getPlaces` already never calls `saveRetrievedPlaces` — the caching path organically went dead the moment HERE was removed, without anything breaking.

**Caveat kept for the record:** `MKLocalSearch` still requires network access — it's not an offline API — so this does mean losing the "show last-known results when offline" behavior the original README listed as a feature. If that's wanted later, the right-sized fix is an in-memory (or `UserDefaults`) cache of the last successful `[Place]` array, not a full persistent store with entities/relationships. Not planned for now — revisit only if offline behavior becomes an actual complaint, not preemptively.

**Cleanup scope:**
- Delete `Persistence.swift`, `Top10Places.xcdatamodeld`, `Places+CoreDataClass.swift`, `Places+CoreDataProperties.swift`, `UserLocation+CoreDataClass.swift`, `UserLocation+CoreDataProperties.swift`.
- Delete the now-dead `getPlacesObject`, `saveRetrievedPlaces`, `retrievePlacesData` methods from `MapService` (unused since Phase 1).
- Remove `import CoreData` from `MapService.swift` and `Top10PlacesApp.swift`; remove `PersistenceController.shared` from the app entry point.
- Update `Top10PlacesTests` — any Core Data-dependent test setup (in-memory store, etc.) gets deleted, not migrated.

**Not a SwiftData migration.** SwiftData is being practiced separately on another project — kept out of scope here entirely rather than folded in as a "might as well" addition, since this app no longer has a real need for a persistence layer of any kind.

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

Phase 0 → Phase 6 (tests, doesn't block anything) → Phase 1 + Phase 2 (networking + location, no dependencies on each other) → Phase 4 (Core Data removal, safe once Phase 1 confirms nothing else calls the caching methods) → Phase 3 (ViewModel, depends on 1+2) → Phase 5 (Coordinator + Map API, depends on 3).

Actual progress so far: Phase 0 and Phase 1 are merged to `main`; Phase 3 has a first pass on the `migration/phase-3` branch with the gaps noted above still open; Phase 4 is newly re-scoped (removal, not SwiftData) and not yet started.

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

**Deployment target already covers this.** Requirements are iOS 26 + A17 Pro/M1 chip or newer, plus the user having Apple Intelligence enabled. Since the app's deployment target is now iOS 26+ (revised above), no `@available(iOS 26, *)` compile-time gating is needed for this feature specifically. The hardware/settings gate still applies regardless of deployment target, though — iOS 26 alone doesn't guarantee an A17 Pro/M1 chip or Apple Intelligence being enabled, so a runtime check of `SystemLanguageModel.default.availability` is still required, with a graceful fallback (plain address/category text) for devices that don't qualify.

**Implementation shape:**
- Define a `@Generable` struct for the output, e.g. `struct PlaceSummary { var blurb: String; var vibe: String }` — guided generation returns this struct directly instead of free text to parse. Properties are generated in declaration order, so put the summary field last so the model reasons over the grounding data first.
- Build the prompt entirely from data already fetched via `MKLocalSearch`/`MKMapItem` (Phase 1), with explicit instructions not to add facts not present in the input.
- Trigger lazily per-place (e.g. on callout open), not eagerly for all 10 results — it's a local inference cost even on-device.
- Wrap `LanguageModelSession.respond(to:generating:)` (async) the same way `MKLocalSearch` is wrapped — `Deferred { Future { ... } }` — so it fits the existing Combine-based architecture instead of being an async island.
</content>
