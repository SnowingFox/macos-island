# island — Build & Publish Guide

## Prerequisites

| Requirement | Version |
|-------------|---------|
| macOS | 14.0 (Sonoma) or later |
| Xcode | 16.0+ (recommended 16.4) |
| Apple Developer Account | Required for code signing & notarization |
| Homebrew (optional) | For installing helper tools |

## 1. Clone & Setup

```bash
git clone https://github.com/TheBoredTeam/boring.notch.git
cd boring.notch
```

Open the project in Xcode:

```bash
open boringNotch.xcodeproj
```

Xcode will automatically resolve Swift Package Manager dependencies (Defaults, KeyboardShortcuts,
Sparkle, Lottie, etc.). If resolution fails, go to **File → Packages → Resolve Package Versions**.

## 2. Local Development Build

### From Xcode UI

1. Open `boringNotch.xcodeproj`
2. Select the **boringNotch** scheme in the toolbar (top left)
3. Select **My Mac** as the run destination
4. Press **⌘R** (Run) for a debug build, or **⌘B** (Build) to compile without running

### From Terminal

```bash
# Debug build
xcodebuild build \
  -project boringNotch.xcodeproj \
  -scheme boringNotch \
  -destination "platform=macOS" \
  -configuration Debug

# Release build (optimized, no debug symbols)
xcodebuild build \
  -project boringNotch.xcodeproj \
  -scheme boringNotch \
  -destination "platform=macOS" \
  -configuration Release
```

## 3. Code Signing Setup

### For Local Testing (Development)

1. In Xcode, select the **boringNotch** target → **Signing & Capabilities** tab
2. Check **Automatically manage signing**
3. Select your **Team** (your Apple Developer account)
4. Xcode will create a development provisioning profile

### For Distribution

You need a **Developer ID Application** certificate for distributing outside the Mac App Store:

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates)
2. Create a **Developer ID Application** certificate
3. Download and install it in your Keychain
4. In Xcode build settings, set:
   - `CODE_SIGN_IDENTITY` = `Developer ID Application`
   - `DEVELOPMENT_TEAM` = your Team ID (10-character string)

## 4. Archive & Export

### From Xcode UI

1. Select **Product → Archive** (⌘⇧B with Release config)
2. Wait for the archive to complete
3. In the **Organizer** window (Window → Organizer):
   - Select the archive
   - Click **Distribute App**
   - Choose **Developer ID** → **Export**
   - Follow the prompts to export a signed `.app`

### From Terminal

```bash
PROJECT=boringNotch
TEAM_ID="YOUR_TEAM_ID"

# Step 1: Archive
xcodebuild clean archive \
  -project ${PROJECT}.xcodeproj \
  -scheme ${PROJECT} \
  -archivePath build/${PROJECT}.xcarchive \
  -destination "generic/platform=macOS" \
  DEVELOPMENT_TEAM="${TEAM_ID}" \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  ONLY_ACTIVE_ARCH=NO

# Step 2: Create export options plist
cat > build/export_options.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${TEAM_ID}</string>
</dict>
</plist>
EOF

# Step 3: Export the signed app
xcodebuild -exportArchive \
  -archivePath build/${PROJECT}.xcarchive \
  -exportPath build/Release \
  -exportOptionsPlist build/export_options.plist
```

The exported app will be at `build/Release/boringNotch.app`.

## 5. Notarization

Apple requires notarization for apps distributed outside the Mac App Store.
Users will see a Gatekeeper warning ("cannot be opened because the developer cannot be verified")
without it.

```bash
APP_PATH="build/Release/boringNotch.app"
TEAM_ID="YOUR_TEAM_ID"
APPLE_ID="your@apple.id"
APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-specific password from appleid.apple.com

# Step 1: Create a ZIP for notarization
ditto -c -k --keepParent "${APP_PATH}" build/island.zip

# Step 2: Submit for notarization
xcrun notarytool submit build/island.zip \
  --apple-id "${APPLE_ID}" \
  --team-id "${TEAM_ID}" \
  --password "${APP_PASSWORD}" \
  --wait

# Step 3: Staple the notarization ticket to the app
xcrun stapler staple "${APP_PATH}"
```

### Creating an App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign In → Security → App-Specific Passwords
3. Generate a password and use it for `--password` above

### Storing Credentials (recommended)

```bash
# Store credentials in Keychain so you don't have to pass them every time
xcrun notarytool store-credentials "notarytool-profile" \
  --apple-id "${APPLE_ID}" \
  --team-id "${TEAM_ID}" \
  --password "${APP_PASSWORD}"

# Then submit using the profile name
xcrun notarytool submit build/island.zip \
  --keychain-profile "notarytool-profile" \
  --wait
```

## 6. Create a DMG

The project includes a DMG creation script at `Configuration/dmg/create_dmg.sh`.

```bash
# Install dmgbuild
pip3 install "dmgbuild[badge_icons]"

# Create the DMG
chmod +x Configuration/dmg/create_dmg.sh
./Configuration/dmg/create_dmg.sh \
  "build/Release/boringNotch.app" \
  "build/Release/island.dmg" \
  "island"
```

Or manually with `create-dmg` (Homebrew):

```bash
brew install create-dmg

create-dmg \
  --volname "island" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "boringNotch.app" 175 190 \
  --app-drop-link 425 190 \
  "build/Release/island.dmg" \
  "build/Release/boringNotch.app"

# Don't forget to notarize the DMG too
xcrun notarytool submit build/Release/island.dmg \
  --keychain-profile "notarytool-profile" \
  --wait
xcrun stapler staple build/Release/island.dmg
```

## 7. Distribution Channels

### GitHub Releases (Direct Download)

```bash
VERSION="1.0.0"

gh release create "v${VERSION}" build/Release/island.dmg \
  --title "v${VERSION}" \
  --notes "Release notes here"
```

Users download the DMG, open it, and drag the app to Applications.

### Homebrew Cask

If you have a Homebrew tap repository:

```ruby
# Casks/island.rb
cask "island" do
  version "1.0.0"
  sha256 "SHA256_OF_DMG"

  url "https://github.com/YOUR_ORG/YOUR_REPO/releases/download/v#{version}/island.dmg"
  name "island"
  desc "Dynamic notch widget for MacBook"
  homepage "https://github.com/YOUR_ORG/YOUR_REPO"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: ">= :sonoma"

  app "boringNotch.app"
end
```

Users install with:

```bash
brew tap YOUR_ORG/YOUR_TAP
brew install --cask island
```

### Sparkle (In-App Auto-Updates)

The project uses [Sparkle](https://sparkle-project.org/) for automatic updates.
The appcast URL is configured in `boringNotch/Info.plist` under `SUFeedURL`.

To publish an update:

1. Build and export the new version
2. Generate a signed appcast:

```bash
./Configuration/sparkle/generate_appcast \
  --ed-key-file path/to/sparkle_private_key \
  --link "https://github.com/YOUR_ORG/YOUR_REPO/releases" \
  --download-url-prefix "https://github.com/YOUR_ORG/YOUR_REPO/releases/download/v${VERSION}/" \
  -o updater/appcast.xml \
  build/Release/
```

3. Host `appcast.xml` at the URL specified in `SUFeedURL`

## 8. CI/CD (GitHub Actions)

The project includes three workflow files:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `manual_build.yml` | Manual dispatch | Build + DMG artifact (no publish) |
| `release.yml` | `/release` comment on PR | Full pipeline: build → notarize → GitHub Release → Homebrew |
| `cicd.yml` | Push / PR | CI checks |

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded `.p12` certificate |
| `P12_PASSWORD` | Password for the `.p12` file |
| `KEYCHAIN_PASSWORD` | Temporary keychain password (any value) |
| `PRIVATE_SPARKLE_KEY` | Sparkle EdDSA private key for signing appcast |
| `RELEASE_TOKEN` | GitHub PAT with `contents: write` for merging |
| `HOMEBREW_TAP_TOKEN` | GitHub PAT for updating the Homebrew tap repo |

### Required GitHub Variables

| Variable | Description |
|----------|-------------|
| `DEVELOPMENT_TEAM_ID` | Your Apple Developer Team ID |

### Release Process

1. Create a PR with your changes
2. Get the PR reviewed and approved
3. Comment `/release 1.2.3` on the PR (admin only)
4. The workflow will:
   - Extract version from the comment
   - Build and archive the app
   - Create a DMG
   - Create a GitHub Release with the DMG
   - Generate and commit the Sparkle appcast
   - Update the Homebrew cask
   - Merge the PR (for stable releases)

### Manual Build

Go to **Actions → Manual Build → Run workflow** in the GitHub UI.
The DMG will be available as a workflow artifact.

## 9. Version Management

Versions are stored in `project.pbxproj`:

- `MARKETING_VERSION` — User-visible version string (e.g., `1.2.3`)
- `CURRENT_PROJECT_VERSION` — Build number (auto-incremented by CI)

To update manually:

```bash
# Set version to 1.2.3
sed -i '' 's/MARKETING_VERSION = [^;]*/MARKETING_VERSION = 1.2.3/g' \
  boringNotch.xcodeproj/project.pbxproj
```

Or in Xcode: select the target → **General** tab → update **Version** and **Build**.

## 10. Naming Notes

The app's **display name** has been changed to **island**. Internal code still uses the
`boringNotch` module name, target name, and class prefixes (e.g., `BoringViewModel`).
This is intentional — renaming internal symbols would be a massive refactor with high risk
of breakage.

What was renamed:
- `CFBundleDisplayName` → `island` (what users see in Dock, menu bar, Finder)
- Menu bar title → `island`
- "Restart" button label → `Restart island`
- All localized strings for the above

What remains as `boringNotch` (internal):
- Xcode project file name (`boringNotch.xcodeproj`)
- Target and scheme name (`boringNotch`)
- Bundle identifier (`theboringteam.boringnotch`)
- Source folder (`boringNotch/`)
- Swift module name and class prefixes (`Boring*`)
- The `.app` bundle name (`boringNotch.app`)

If you want a full rename, you would need to:
1. Rename `boringNotch.xcodeproj` → `island.xcodeproj`
2. Rename the `boringNotch/` source folder → `island/`
3. Update all group/file paths in `project.pbxproj`
4. Change bundle identifier (breaks existing installs and Sparkle updates)
5. Rename Swift types (optional, cosmetic)
6. Update CI/CD workflows (`PROJECT_NAME`, scheme names, artifact paths)
7. Update Homebrew cask and Sparkle appcast URLs

## Quick Reference

```bash
# Build (debug)
xcodebuild build -project boringNotch.xcodeproj -scheme boringNotch

# Build (release)
xcodebuild build -project boringNotch.xcodeproj -scheme boringNotch -configuration Release

# Archive
xcodebuild archive -project boringNotch.xcodeproj -scheme boringNotch -archivePath build/island.xcarchive

# Run the app
open build/Release/boringNotch.app
```
