# FFFModelFixer

A small Mac app that gives tethered Hasselblad .fff raw files the same camera
model as untethered ones.

Files shot tethered and files shot untethered carry different camera model
metadata: in tethered files the model is missing "Hasselblad ". This app adds
it, so every file from a session names the camera the same way.

Drop a session folder on the window. The app finds every .fff file at the top
level of the folder, backs them up, and adds "Hasselblad " to each model that
lacks it. Files that already start with "Hasselblad" are left alone. Subfolders
are skipped.

## Experimental

This is experimental software. Use it at your own risk, and keep your own
backup of every session. KVdS media bv is not responsible for any loss of or
damage to your files.

## Before it changes anything

The originals are rewritten in place, so the app first copies every .fff file
into a new folder inside the session folder, named `_FFF_Backup_<date>_<time>`.
That copy is the only way back. A session's .fff files can be 100 to 200 MB
each, so the backup doubles the space the session takes.

A `fix_log.txt` in the backup folder lists what was found and what was changed.
When it's done, the window shows how many files were fixed for each model, and
Open Backup Folder shows the copies in Finder.

## Requirements

- macOS 15 or later
- [ExifTool](https://exiftool.org), which does the reading and writing:

      brew install exiftool

  The app looks for `exiftool` on your `PATH`, then in `/opt/homebrew/bin`
  and `/usr/local/bin`.

## Building

Open `FFFModelFixer.xcodeproj` in Xcode and run it, or from Terminal:

    xcodebuild -project FFFModelFixer.xcodeproj -scheme FFFModelFixer \
      -configuration Release -derivedDataPath build build

The App Sandbox is off, so the app can run `exiftool` and write into the
folders you drop on it. Local builds are named "FFFModelFixer (Debug)" or
"FFFModelFixer (Test)" so you can tell them apart from an installed copy.

## Licence

Made by KVdS media bv. MIT licence, see [LICENSE](LICENSE).
