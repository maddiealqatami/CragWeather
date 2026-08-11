# Design Decisions

Short ADR-style records for interview discussion.

---

## ADR-001: Region-first launch vs fetch-all-crags-at-launch

**Context:** Colorado has dozens of climbing regions; fetching every crag and forecast at launch is slow and wasteful.

**Decision:** Show the region picker immediately after seeding bundled metadata. Fetch crags and weather only for the selected region.

**Consequences:**
- Fast cold start and lower API usage.
- Users must pick a region before seeing crags.
- Region scores refresh in the background to rank the picker.

---

## ADR-002: SwiftData over Core Data

**Context:** Need local persistence for crags, forecasts, and region summaries with SwiftUI integration.

**Decision:** Use SwiftData with `@Model` types and `@Query` in views.

**Consequences:**
- Less boilerplate than Core Data stack setup.
- Testable via in-memory `ModelContainer`.
- Tighter coupling to Apple’s newest persistence API (iOS 17+).

---

## ADR-003: Bundled region catalog + background score refresh

**Context:** OpenBeta does not expose a simple “list all Colorado regions” API suitable for instant picker population.

**Decision:** Ship `ColoradoRegions.json` for centroid metadata; sync scores from Open-Meteo after launch without blocking the UI.

**Consequences:**
- Picker is populated offline on first launch.
- Catalog updates require an app release (or future remote config).
- Scores may be stale until background refresh completes.

---

## ADR-004: Hide zero-crag regions after sync

**Context:** Some catalog entries resolve to zero roped-eligible crags (boulder-only areas, API gaps).

**Decision:** `isEligibleForPicker` hides regions with `cragCount == 0` once `lastCragSyncDate` is set.

**Consequences:**
- Cleaner picker after users explore regions.
- Regions like Aspen may disappear if sync returns no eligible crags.
- Unsynced regions remain visible so users can still try them.

---

## ADR-005: Session-only region selection on launch

**Context:** Restoring the last region from `UserDefaults` skipped the picker and caused blank-sheet edge cases.

**Decision:** `AppCoordinator.selectedRegion` starts empty each launch; still persist selection when the user picks a region.

**Consequences:**
- Consistent launch experience for demos and new users.
- Returning users re-select their region each session.
- Sheet-based region change keeps tab state when switching mid-session.

---

## Future / TODO

- **Protocol-based networking** — inject `OpenBetaService` / `WeatherService` for deterministic integration tests.
- **Sync TTL policy** — configurable refresh intervals per region vs global weather cache.
- **Multi-state catalogs** — parameterized region JSON and map bounds beyond Colorado.
