# Progress history migration: V1 baseline and behavior contract

Preparation for [issue #22](https://github.com/samyanez94/GoalTracker/issues/22). This PR does not enable V2, change production calculations, or reproduce CloudKit transport behavior.

## Production baseline

The owner confirmed that **1.2.0** is the latest App Store version. The local release-version commit is `5d15dab40648e7618c0f6b190e100b5bce107444`. This is source provenance, not verification of an App Store archive/build number.

At preparation commit `9a84af2`, the following files are byte-for-byte identical to their 1.2.0 counterparts (moved from `Models/` to `Features/Goals/Models/`, and the schema to `Persistence/`):

- `Goal`, `Tag`, `GoalTrackerSchema`
- `GoalProgress`, `GoalProgressEvent`, `MeasurableProgress`, `OutcomeProgress`
- `GoalProgressUnit` (including `GoalProgressUnitStorage`)
- `GoalRecurrence`, `GoalRecurrenceCadence`, `GoalReminder`

Freeze V1's persisted properties, entity identities, relationship definitions, and nested Codable representation. V1 references shared value types: changing their Codable shape or validation can break old stores even without changing `Goal.swift`. PR #2 must preserve those legacy definitions/decoders when introducing a different V2 calculation representation. Do not replace the committed fixture to make a compatibility failure pass.

## Minimal behavior contract for upgraded clients

Keep signed-delta operations for this migration. Complete/reset are adjustments against the history the device has observed, not globally ordered assignments. No logical clocks, settings revisions, second authoritative goal entity, or separate observable copy of each goal.

| Scenario | Required result after receiving all operations |
| --- | --- |
| Start at 4/10; offline additions +2 and +3 | Both survive; 9/10 |
| Two distinct events have the same time and amount | Both survive |
| The same logical event arrives twice | Count once by goal ID + event ID |
| Start at 4/10; both devices complete | Keep +6 and +6; raw 16, display 10 |
| Decrement once after observing that raw 16/10 | Record −7; display 9, matching V1's visible-value adjustment |
| Start at 4; reset races with +2 | Keep −4 and +2; display 2 |
| Start at 2; both devices subtract 2 | Keep both; raw −2, display 0; do not crash |
| Binary: both devices complete | Keep +1 and +1; display complete |
| Binary: reset after observing both completions | Record −2; display incomplete; reopening must succeed |
| Binary: reset races with an unseen completion | Retain the unseen completion; calculate the bounded sum |
| Two individually valid deletions leave a negative total | Honor both; display 0; do not restore deleted events |

The surplus and adjustment behavior is intentional continuity with V1, not an idealized counter. History displays the actual recorded delta. PR #3 must not silently introduce absolute assignments or discard overflow. If this behavior is rejected in review, resolve it before finalizing V2's persisted representation.

### Validation boundary

`GoalProgressConflictBaselineTests` executes the valid merged cases against production value types and characterizes the unsupported cases without calling preconditioned initializers on invalid input. V1 rejects negative aggregate totals and binary deltas outside ±1. Preserve those frozen decoders; the new event reader/reducer must accept finite merged deltas, bound displayed values, and reject/quarantine non-finite input or overflow without dropping valid history. The tests asserting V1 rejection must remain as historical characterization, not be inverted by loosening a legacy decoder.

The new V2 reader must acquire executable assertions for the negative-total and binary −2 expectations before activation. These are release gates, not behavior implemented by this PR. Pure arithmetic tests do not establish that CloudKit retains both operations.

### Identity, deletion, and ordering

- Preserve imported event UUIDs, timestamps, deltas, and goal association. Same identity with conflicting payload is a diagnostic/recovery case, not two countable events.
- Persist event deletion markers independently of event arrival. A late import must not resurrect a deleted ID. Do not expire markers in this release.
- Keep the current local refusal to delete an event when the locally visible remaining history is negative. If independently accepted deletions merge to a negative total, the reader must still honor both and display zero.
- Continue existing goal deletion behavior. Do not recreate a missing goal from an orphan event. Keep events pending while a parent may still be syncing. Test late events versus goal deletion on devices before release.
- Preserve array order in the V1 fixture. V2 history must order by timestamp, then stable event ID for ties; relationship/arrival order is not a history order. Use a deterministic reduction order as well.
- Evaluate recurring goals with the existing calendar windows, including the exclusive period end. Do not change time-zone semantics or reinterpret dates during import.
- Settings edits of the same progress type preserve history. Existing type changes replace active progress; V2 must preserve that visible behavior and prevent late old-type events from entering the replacement history. The mechanism remains a PR #2 design gate; do not implement a general settings conflict system.

## Compatibility boundary

Upgrading legacy data is supported. Reliable concurrent editing requires all devices to run the upgraded version. Keep legacy data readable; never dual-write new history into the old array. Repeat reconciliation for legacy records arriving after local migration, deduplicating IDs and respecting deletion markers. Absence from an old array does not prove deletion. Old clients can still change/delete the shared goal; this migration does not isolate upgraded data from them. Already-overwritten history cannot be reconstructed.

## Fixture coverage and use

`GoalTrackerTests/Persistence/Fixtures/goal-tracker-v1.json` contains fixed synthetic inputs, event identities, and independently specified calculation expectations. Evaluation uses June 10, 2026 at 12:00 UTC, Gregorian calendar, Monday-first weeks.

The disk store covers empty and completed outcome/measurable goals; completion/reset history; signed and equal-time events; 256-event fractional history; no unit, preset unit, and full custom unit; daily/weekly recurrence and streaks; an event exactly at the next weekly boundary; optional notes/target dates/reminders; shared tags and inverse relationships.

Normal tests copy the committed `.store` to a unique temporary directory and open it twice. They compare all persisted goal/tag fields, exact ordered event arrays, configuration, current-period totals, completion, and streaks to the manifest. They never regenerate the baseline and never enable CloudKit.

The fixture is synthetic and produced with a modern simulator from source matching 1.2.0. It does not replace testing an actual installed 1.2.0 upgrade, its original OS runtime, or production CloudKit metadata.

## Capturing a baseline intentionally

The committed store was captured with Xcode 27.2 (27B52), iOS Simulator 27.2, and CloudKit disabled. It contains synthetic data only. SHA-256: `52aa38cd5b50fcc0dc478ab1de486fe6946573c08ca829b79770727ba82f9013`.

To reproduce a capture, use source matching the commit above and a clean simulator app container. The capture refuses to overwrite `Documents/V1FixtureCapture`. Run:

```sh
TEST_RUNNER_GOALTRACKER_CAPTURE_V1=1 xcodebuild test \
  -project GoalTracker.xcodeproj -scheme GoalTracker \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -parallel-testing-enabled NO \
  -only-testing:GoalTrackerTests/GoalTrackerV1FixtureCaptureTests
```

After the test process exits, copy the entire printed capture directory to a temporary host directory, including any SQLite `-wal`/`-shm` sidecars. Use SQLite's backup API on that copy to produce a standalone `.store`; never copy just the main file from a live store. Validate `PRAGMA integrity_check`, then run `GoalTrackerV1FixtureTests` against the resulting resource. Store bytes can differ across captures because internal store identifiers are generated. Replacing the checked-in baseline and its pinned checksum requires explicit review; ordinary tests never record it automatically.

## Remaining PRs

1. PR #2: additive V2 schema, frozen V1 dependencies, repeatable import/deduplication, deletion markers, and migration tests opening this committed fixture. Production stays on V1.
2. PR #3: event read/write integration, the unsupported calculation cases above, remote refresh/reminders, device verification, and production activation.

Device gates: independent offline upgrades, concurrent actions in both delivery orders, delete-before-insert, old-client edits/deletion, interrupted migration, and fresh install downloading legacy/new records out of order. Publish additive CloudKit schema changes before releasing the V2 build. Recovery builds must read V2; downgrading is not a recovery strategy.
