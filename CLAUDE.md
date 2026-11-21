# FFFModelFixer

A small macOS SwiftUI app (macOS 15+, one target, no tests). Drop a session folder on the window and it adds the missing "Hasselblad " prefix to the camera Model tag of every `.fff` file at the top level of that folder (subfolders are skipped), using `exiftool`.

## How it works

- `FFFProcessor.swift`: the flow and state (`idle`, `processing`, `done`, `error`). Finds `exiftool`, lists the `.fff` files, copies them all into `_FFF_Backup_<yyyyMMdd_HHmmss>/` inside the folder, reads the distinct Model values (`-fast2 -Model -s3`), then for each model without the prefix runs one `exiftool -m -overwrite_original -Model=… -if '$Model eq "…"'` over the folder. Writes `fix_log.txt` into the backup folder.
- `ExifToolRunner.swift`: finds `exiftool` on `PATH`, then `/opt/homebrew/bin`, `/usr/local/bin`; runs it with `Process` (no shell) and drains stdout so large sessions don't deadlock.
- `ContentView.swift` (drop handling, progress, error), `DropZoneView.swift`, `ResultsView.swift` (summary, log list, Open Backup Folder).

## Build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project FFFModelFixer.xcodeproj -scheme FFFModelFixer -configuration Debug \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

`xcode-select` points at the Command Line Tools, hence `DEVELOPER_DIR`. The scheme is Xcode's auto-generated one (no shared scheme; `xcuserdata/` is ignored). Unsigned builds avoid Keychain prompts; checked 2026-11-21, builds clean.

## Gotchas

- Needs `exiftool` installed (`brew install exiftool`). App Sandbox is off on purpose (entitlements), so it can run it and write into dropped folders.
- It rewrites the originals in place (`-overwrite_original`); the backup copy is the only undo. Each `.fff` can be 100–200 MB, so a backup doubles the session's size.
- Local builds are named "FFFModelFixer (Debug)" / "FFFModelFixer (Test)"; archives keep the plain name (`APP_NAME_KIND` from `DEPLOYMENT_LOCATION` in the project). The commit that added this was shared with other repos and mentions their release scripts; this repo has none.
- Bundle id `com.kris.FFFModelFixer`, `DEVELOPMENT_TEAM` empty, Swift 5 language mode, version 1.0 (1).
- Remote: `github.com/krisvandesande/FFFModelFixer`, public since 2026-11-21 (MIT, KVdS media bv). README.md is the public description; keep it in step with the app.
