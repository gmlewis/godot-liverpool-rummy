# Android Release Build (AAB) for Google Play

This documents the process of producing a signed release `.aab` for upload to
the Google Play Console using Godot 4.5. It exists because I once got a
Google Play policy notice ("App must target Android 16 / API level 36 or
higher") and had no record of exactly how to rebuild the AAB afterwards.

## Prerequisites (one-time / occasional)

1. **Godot 4.5** with the Android export templates installed
   (Editor → Manage Export Templates → Download).
2. **Android Studio** or at least the Android SDK + NDK + build tools
   installed and discoverable on `PATH` / `ANDROID_HOME`.
3. The release keystore at the repo root:
   `liverpool-rummy.keystore`.
   Its alias/password live in `export_presets.cfg` via the keystore editor
   (Editor → Project → Export → Android preset → Keystore section). They
   are NOT committed to the repo as plain text; Godot stores them in the
   preset file under `keystore/release_*` fields. Do not lose the keystore
   — a different one would require a new Play Store app entry.

## Where the SDK / build settings live

The compile/target SDK versions used by the Gradle build are **not** stored
in `export_presets.cfg` — they come from:

    android/build/config.gradle

```
ext.versions = [
    androidGradlePlugin: '8.7.3',
    compileSdk         : 36,     // <-- bump when Google raises the minimum
    minSdk             : 24,
    targetSdk          : 36,     // <-- bump when Google raises the minimum
    buildTools         : '36.0.0',
    ...
]
```

Google Play's "target API level" policy requires `targetSdk` (and therefore
`compileSdk`) to be at or above the level they announce in the Play
Console. As of 2025 this is **Android 16 / API 36**. When the next bump
comes, edit `android/build/config.gradle` and bump all three
(`compileSdk`, `targetSdk`, `buildTools`) together — and see the
"AGP / Gradle compatibility" section below, since a newer AGP may also be
required.

`minSdk` (currently 24 = Android 7.0) is unrelated to the Play policy and
should only be lowered/raised deliberately.

### Also set `gradle_build/target_sdk` in export_presets.cfg

**Important:** the `targetSdk` in `config.gradle` only controls what
Gradle compiles against. The **manifest's** `targetSdkVersion` (the one
Google Play actually checks) is written by Godot's export plugin from a
different source: the `gradle_build/target_sdk` field in
`export_presets.cfg`, with the Godot export template's built-in
`DEFAULT_TARGET_SDK_VERSION` as fallback.

Older Godot 4.5 dev builds default to `DEFAULT_TARGET_SDK_VERSION = 35`,
even when `config.gradle` is on 36 — so the AAB will have
`targetSdkVersion=35` in its manifest and Google Play will still reject
it as "must target Android 16 / API 36". To force it:

```
gradle_build/target_sdk="36"
```

in the `[preset.0.options]` section of `export_presets.cfg`. Leave
`gradle_build/min_sdk=""` (empty) unless you also want to override the
minSdk default.

### AGP / Gradle compatibility (important!)

Each Android Gradle Plugin (AGP) version only officially knows about a
specific range of `compileSdk` values. Using a `compileSdk` that's newer
than your AGP supports will *still build* but Godot's Export dialog will
flood with warnings like "Android 16 is not compatible with this version
of Gradle / update Gradle". The AAB still gets produced — the warnings
are just noise.

Known-good combinations:

| `compileSdk` / `targetSdk` | Min AGP version | Min Gradle wrapper |
|----------------------------|-----------------|--------------------|
| 35                         | 8.6.x           | 8.7                |
| **36 (Android 16)**        | **8.7.x**       | **8.9**            |
| (next, 37?)                | check Google's table | check Google's table |

When bumping `compileSdk`, also:

1. Bump `androidGradlePlugin` in `android/build/config.gradle` (e.g.
   `8.6.1` → `8.7.3` for API 36).
2. Check the Gradle wrapper version in
   `android/build/gradle/wrapper/gradle-wrapper.properties`
   (`distributionUrl=...gradle-X.Y.Z-bin.zip`). It must satisfy the AGP
   requirement (AGP 8.7.x wants Gradle ≥ 8.9). This repo currently ships
   `gradle-8.11.1`, which is fine.
3. AGP/Gradle compatibility table:
   https://developer.android.com/build/releases/gradle-plugin

If the Godot export dialog fills with "update Gradle" warnings, the
first thing to check is whether your AGP is too old for the
`compileSdk` you set. The build will still succeed — the AAB appears at
`android/build/build/outputs/bundle/standardRelease/` — but rebuild with
the correct AGP to silence the warnings and stay on supported ground.

## Large-screen compliance (orientation & resizability)

Google Play will warn:

> Remove resizability and orientation restrictions in your game to
> support large screen devices

…if your AAB's manifest declares a fixed `android:screenOrientation` or
`android:resizeableActivity="false"`. Godot derives both of these from
**`project.godot`** project settings (not `export_presets.cfg`):

| Manifest attribute             | project.godot key                       | Good value for large-screen compliance |
|--------------------------------|-----------------------------------------|---------------------------------------|
| `android:screenOrientation`    | `display/window/handheld/orientation`   | `6` (SCREEN_SENSOR — any orientation) |
| `android:resizeableActivity`   | `display/window/size/resizable`          | `true`                                |

### `display/window/handheld/orientation` enum values

(Godot `DisplayServer.ScreenOrientation`)

| Value | Constant                     | Android `screenOrientation` |
|------:|------------------------------|------------------------------|
| 0     | SCREEN_LANDSCAPE             | `landscape`                  |
| 1     | SCREEN_PORTRAIT              | `portrait`                   |
| 2     | SCREEN_REVERSE_LANDSCAPE     | `reverseLandscape`           |
| 3     | SCREEN_REVERSE_PORTRAIT       | `reversePortrait`           |
| 4     | SCREEN_SENSOR_LANDSCAPE      | `sensorLandscape`           |
| 5     | SCREEN_SENSOR_PORTRAIT       | `sensorPortrait`            |
| 6     | SCREEN_SENSOR                | `fullUser` (any orientation)|
| 7     | SCREEN_VISIBLE               | `user`                       |
| 8     | SCREEN_AUTO                  | (no constraint)              |

To silence the Play Store warning, use **6** (SCREEN_SENSOR). The game
must be able to handle any aspect ratio the device throws at it — Godot's
`window/stretch/mode="canvas_items"` plus `window/stretch/aspect="expand"`
(which this project already uses) handle the layout adaptation.

### Verifying the manifest after build

AABs store their `AndroidManifest.xml` as protobuf, not binary AXML, so
`aapt2 dump badging` does NOT work on an AAB. To inspect the values:

```sh
# Extract and grep the protobuf-encoded manifest
unzip -p android/liverpool-rummy-english.aab base/manifest/AndroidManifest.xml \
    | strings | grep -A2 -iE "resizeableActivity|screenOrientation|targetSdkVersion"
```

Or, for a clean field-by-field dump, run this from the repo root after a
build:

```sh
python3 -c '
import zipfile
with zipfile.ZipFile("android/liverpool-rummy-english.aab") as z:
    data = z.read("base/manifest/AndroidManifest.xml")
for k in [b"versionCode", b"versionName", b"minSdkVersion", b"targetSdkVersion",
          b"compileSdkVersion", b"resizeableActivity", b"screenOrientation"]:
    i = data.find(k)
    if i < 0: continue
    w = data[i:i+30]
    j = w.find(b"\x1a")
    if j >= 0:
        n = w[j+1]
        print(f"{k.decode()} = {w[j+2:j+2+n]!r}")
'
```

This prints the values the Play Console will actually see.

## Bumping the version number

Before rebuilding for a new release, bump the version in
`export_presets.cfg` (Android preset):

```
version/code=18                    # integer, must increase between uploads
version/name="0.18.1"              # human-readable
```

`version/code` MUST be strictly greater than the last one uploaded to the
Play Console or the upload will be rejected. `version/name` is what users
see on the store listing.

(There is a helper script `bump-version.sh` at the repo root — check what
it does before relying on it.)

## Producing the AAB

There are two ways to trigger the build. The CLI method is preferred
because it captures all Gradle warnings to a log file you can re-read;
the Godot GUI dialog discards Gradle output as soon as it closes.

### Method A: CLI (recommended)

From the repo root:

```sh
./build-android-aab.sh
```

The script:

1. Locates the Godot 4.5 binary (defaults to
   `/Applications/Godot.app/Contents/MacOS/Godot`; override via the first
   arg or `$GODOT`).
2. Verifies the `liverpool-rummy` Android preset exists in
   `export_presets.cfg` and that `liverpool-rummy.keystore` is present.
3. Runs `godot --export-release liverpool-rummy android/liverpool-rummy-english.aab`,
   teeing all output to `build-android-aab.log` (overwritten each run).
4. Confirms the AAB exists at the export path and prints a manifest
   summary (`package`, `sdkVersion`, `targetSdkVersion`,
   `application-label`) via `aapt`/`aapt2` if either is on `PATH`.

The AAB is produced at `android/liverpool-rummy-english.aab`. The
intermediate Gradle outputs land at
`android/build/build/outputs/bundle/standardRelease/` and
`android/build/build/outputs/bundle/monoRelease/`.

If you only want to see warnings from a one-off build (without using the
script), run the export directly and tee it yourself:

```sh
/Applications/Godot.app/Contents/MacOS/Godot \
    --path . --export-release "liverpool-rummy" \
    android/liverpool-rummy-english.aab 2>&1 | tee /tmp/godot-export.log
```

### Method B: Godot GUI

1. Open the project in **Godot 4.5**.
2. **Project → Export…** (or the Export button in the editor toolbar).
3. Select the **Android** preset (`liverpool-rummy`) in the left panel.
   - Preset name: `liverpool-rummy`
   - Export path: `android/liverpool-rummy-english.aab`
   - `package/unique_name="com.github.gmlewis.liverpoolrummy.english"`
   - `package/name="Multiplayer Moonridge Rummy"`
   - `package/signed=true`
   - `architectures/arm64-v8a=true` (others false — arm64-only build)
   - `gradle_build/export_format=1` (this is the "AAB" setting, not APK)
4. Click **Export Project…** (NOT "Export All").
   - **Export Project…** exports only the currently selected preset — what
     you want for a Play Store upload.
   - **Export All** exports every preset (Android + Web + iOS). Useful once
     all configs are solid, but unnecessary for a single AAB.
5. In the file dialog:
   - **Save As:** `android/liverpool-rummy-english.aab` (or your chosen
     path).
   - **Export With Debug: UNCHECKED.** A release AAB must be built without
     debug; otherwise the Play Console will reject it as a debug build.
6. Click **Export**.

**Note on the GUI dialog:** the Godot 4.5 Export dialog shows Gradle
output live but does NOT persist it. When the dialog closes, that
output is gone — there is no "Editor → Editor Logs → Export tab" that
preserves it. To see warnings after the fact, use Method A (CLI) above.

## Verifying the build

Quick sanity checks before uploading:

```sh
# Should report targetSdkVersion=36
aapt dump badging android/liverpool-rummy-english.aab | grep -E "sdkVersion|targetSdkVersion|package|version"

# Confirm it's a release (signed) build
jarsigner -verify -verbose -certs android/liverpool-rummy-english.aab
```

(The `aapt` binary lives under your Android SDK build-tools directory; use
`aapt2` if `aapt` is missing.)

## Uploading to the Play Console

1. https://play.google.com/console
2. Select **Multiplayer Moonridge Rummy** → **Production** (or
   **Internal testing** for a pre-release sanity check).
3. **Create new release** → upload the `.aab`.
4. Fill in release notes, review the rollout, and publish.

If Google shows a "target API level" warning on the release page, the
AAB was built against an older `targetSdk` — return to
`android/build/config.gradle`, bump the three values, and rebuild.

## Troubleshooting

- **"Export With Debug" was checked by mistake** — Play Console rejects
  it. Re-export with the box unchecked.
- **version/code already used** — bump `version/code` in
  `export_presets.cfg` and re-export.
- **Keystore password prompt / wrong keystore** — the keystore fields
  in the Android preset are empty or stale. Re-select
  `liverpool-rummy.keystore` in the Export dialog's Keystore section and
  re-enter the alias/password.
- **`buildTools 36.0.0` not installed** — open Android Studio's SDK
  Manager and install the matching build-tools version.
- **Gradle build fails after SDK bump** — also bump
  `androidGradlePlugin` in `android/build/config.gradle` if a newer AGP
  is required for the new build-tools (Google's compatibility table:
  https://developer.android.com/studio/releases/gradle-plugin).
- **Export dialog floods with "Android 36 not compatible with this
  version of Gradle / update Gradle" warnings** — the AAB still builds
  fine and lands at `android/build/build/outputs/bundle/standardRelease/`,
  but your AGP is too old for the `compileSdk` you set. Bump
  `androidGradlePlugin` in `android/build/config.gradle` (e.g. 8.6.x →
  8.7.x for API 36) and, if needed, the Gradle wrapper version in
  `android/build/gradle/wrapper/gradle-wrapper.properties`. See the
  "AGP / Gradle compatibility" section above.
- **"Where did the export warnings go?"** — the Godot 4.5 Export dialog
  does NOT persist Gradle output. There is no "Editor Logs → Export
  tab" that preserves it; the editor's `app_userdata/.../logs/godot.log`
  only captures editor runtime messages, not Gradle subprocess output.
  To see warnings after a build, use `./build-android-aab.sh` (which
  tees everything to `build-android-aab.log`), or run the export
  directly with `... --export-release ... 2>&1 | tee /tmp/godot-export.log`.