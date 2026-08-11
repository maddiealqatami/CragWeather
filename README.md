# CragWeather

Colorado crag weather app that ranks climbing regions and crags by same-day conditions. Data comes from [OpenBeta](https://openbeta.io) (crag metadata) and [Open-Meteo](https://open-meteo.com) (forecasts).

## Screenshots

| Region picker | Crag list | Detail |
|---------------|-----------|--------|
| *(Add simulator captures to `docs/screenshots/`)* | | |

## Requirements

- Xcode 26+
- iOS 26.5+ deployment target
- macOS with Xcode Command Line Tools for CI-style test runs

## Setup

```bash
git clone https://github.com/your-org/CragWeather.git
cd CragWeather
open CragWeather.xcodeproj
```

Run on an iOS Simulator (e.g. iPhone 16) from Xcode, or:

```bash
xcodebuild -scheme CragWeather \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

## Run Tests

```bash
xcodebuild test -scheme CragWeather \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Unit tests use Swift Testing; UI smoke tests use XCTest.

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for layer diagrams, sync pipeline, and data flow.

## Design Decisions

See [docs/DECISIONS.md](docs/DECISIONS.md) for ADR-style notes on region-first launch, SwiftData, and picker eligibility rules.

## Demo Script (~30 seconds)

1. **Launch** — App opens on **Choose a Region**; bundled Colorado catalog loads immediately.
2. **Pick a region** — Tap a region (sorted by today's conditions score when available).
3. **Browse crags** — Crag list syncs from OpenBeta, then shows scored rows for that region.
4. **Filter / search** — Use the search field or filter sheet for climb type, elevation, aspect.
5. **Detail** — Tap a crag for a 5-day forecast breakdown and OpenBeta link.
6. **Change region** — Use the region badge in the nav bar to open the picker sheet without losing tab state.

## Talking Points

- **Problem:** Climbers need a quick read on which Colorado areas are worth driving to today.
- **Trade-off:** Region-first launch keeps cold start fast; crag + weather sync happens after selection.
- **Testing:** Pure logic unit tests, in-memory SwiftData integration tests, and UI smoke tests — no network mocks in CI.
- **Next steps:** Protocol-based networking, sync TTL tuning, multi-state region catalogs.

## License

MIT — see [LICENSE](LICENSE).
