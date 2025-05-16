# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SmartTube is a free and open-source advanced media player for Android TVs and TV boxes. It allows users to play content from various public sources with features like ad-blocking, SponsorBlock integration, customizable playback speed, high resolution support, and more. The app is designed specifically for Android TV devices and is not intended for smartphones or tablets.

## Environment Setup

The project requires OpenJDK 14 or older to build. Newer JDK versions may cause app crashes. To ensure consistent builds across different development environments, we use a Docker-based build system that handles all dependencies.

## Build Commands

All build operations should be performed using the `docker-build.sh` script. Never build directly with Gradle.

### Clone the Repository
```bash
git clone https://github.com/yuliskov/SmartTube.git
cd SmartTube
```

### Build Process

First, create the Docker image containing all required build tools:
```bash
./docker-build.sh build-image
```

To build a specific flavor of the app:
```bash
./docker-build.sh build [FLAVOR]
```

For a complete build process (build image, build app, export APKs, and optionally install):
```bash
./docker-build.sh all [FLAVOR]
```

### Installation and Testing

To install a built APK to a connected Android TV device:
```bash
./docker-build.sh install [FLAVOR]
```

This command will specifically look for the armeabi-v7a architecture APK, which is the appropriate version for most Android TV devices.

To uninstall the app from a connected device:
```bash
./docker-build.sh uninstall [FLAVOR]
```

### Other Useful Commands

Open a shell in the Docker container:
```bash
./docker-build.sh shell
```

Clean build outputs:
```bash
./docker-build.sh clean
```

Export built APKs to the builds directory:
```bash
./docker-build.sh export-apks
```

### Available Build Flavors
- `stbeta` - Beta version (default)
- `ststable` - Stable version
- `storig` - Original version
- `strtarmenia` - Version with custom application ID
- `stredboxtv` - Version for RedboxTV
- `stfiretv` - Version for Amazon Fire TV

## Project Architecture

The project is organized into multiple modules:

1. `smarttubetv` - Main application module
2. `common` - Common utilities and resources
3. `chatkit` - Chat interface module
4. `leanbackassistant` - Leanback Assistant integration
5. `leanback-1.0.0` - Modified Android Leanback library
6. `fragment-1.0.0` - Modified Android Fragment library
7. `filepicker-lib` - File picker library
8. `exoplayer-amzn-2.10.6` - Custom Amazon ExoPlayer fork for video playback

The project also has two git submodules:
- `SharedModules` - Shared utilities and components
- `MediaServiceCore` - Core media service functionality

## Key Features Implementation

1. **Ad-blocking**: The app is programmed to be completely unable to display ads.
2. **SponsorBlock**: Integration with SponsorBlock to skip sponsor segments in videos.
3. **Playback Speed**: Customizable video playback speed.
4. **High Resolution Support**: Supports up to 8K resolution and HDR.
5. **Picture-in-Picture**: Supports PiP mode when enabled in settings.
6. **Voice Search**: Requires an additional bridge app for integration with system voice search.
7. **Codec Support**: Supports different video codecs (AV1, VP9, AVC) based on device compatibility.

## Testing

The project primarily uses JUnit and Robolectric for testing. Test implementations are defined in the build.gradle files:

```gradle
testImplementation 'junit:junit:' + junitVersion
testImplementation 'org.robolectric:robolectric:' + robolectricVersion
androidTestImplementation 'androidx.test.ext:junit:' + testXSupportLibraryVersion
androidTestImplementation 'androidx.test.ext:truth:' + testXSupportLibraryVersion
androidTestImplementation 'androidx.test:runner:' + testXSupportLibraryVersion
androidTestImplementation 'androidx.test:rules:' + testXSupportLibraryVersion
androidTestImplementation 'androidx.test.espresso:espresso-core:' + espressoVersion
```

## Code Style and Conventions

The app follows Google's official template and recommendations for Android TV apps. When making changes:

1. Follow the existing code style and patterns in the repository
2. Maintain compatibility with older Android versions (minimum SDK version is 18 - Android 4.3 Jelly Bean)
3. Consider device-specific limitations and ensure changes work across all supported Android TV devices

## Important Notes

1. The app is designed only for Android TV devices, not for smartphones or tablets.
2. The app has a built-in updater with changelog.
3. OpenJDK 14 or older is required for building; newer JDK versions could cause app crashes.
4. Some device-specific customizations exist for Xiaomi devices with Chinese firmware, Chromecast with Google TV, etc.

## Development Workflow

For all development and testing tasks:

1. **ALWAYS** use the Docker build system via the `docker-build.sh` script.
2. **NEVER** attempt to run Gradle commands directly or use local builds.
3. This ensures consistency across development environments and avoids JDK version issues.

For detailed information about the Docker build system, see `DOCKER_BUILD.md`.