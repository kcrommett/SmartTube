# SmartTube Docker Build Environment

This document explains how to build SmartTube using Docker to ensure a consistent build environment with the correct OpenJDK version and dependencies.

## Prerequisites

- Docker installed on your system
- Git installed on your system (for submodule operations)
- Internet connection to download Docker dependencies

The SmartTube project relies on two git submodules:
1. SharedModules
2. MediaServiceCore

The build script will automatically initialize these submodules if they are not already present.

## Setup and Build Instructions

### 1. Build the Docker Image

First, build the Docker image which contains all necessary dependencies:

```bash
./docker-build.sh build-image
```

This will create a Docker image called `smarttube-builder` with:
- Ubuntu 20.04 as the base OS
- OpenJDK 14 (as required by the project)
- Android SDK with necessary platforms and build tools
- Gradle build system

### 2. Building the App

To build a specific flavor of the app:

```bash
./docker-build.sh build [FLAVOR]
```

Where `[FLAVOR]` is one of:
- `stbeta` - Beta version
- `ststable` - Stable version
- `storig` - Original version (default if no flavor specified)
- `strtarmenia` - Version with custom application ID
- `stredboxtv` - Version for RedboxTV
- `stfiretv` - Version for Amazon Fire TV

For example, to build the beta version:

```bash
./docker-build.sh build stbeta
```

The build process will compile the APK files without attempting to install them on any device. This is useful for creating distribution packages or for manually installing the APKs later.

### 3. Where to Find the APKs

After a successful build, APK files will be available in:

```
smarttubetv/build/outputs/apk/[FLAVOR]/debug/
```

### 4. Additional Commands

#### Installing APKs to a Device

To install a built APK to a connected Android device via ADB:

```bash
./docker-build.sh install [FLAVOR]
```

The default flavor is `stbeta` if not specified. The command will specifically look for an armeabi-v7a architecture APK, which is the appropriate version for most Android TV devices. If no armeabi-v7a APK is found, the script will provide options to either select a different architecture or build the correct version.

#### Uninstalling Apps from a Device

To uninstall the app from a connected Android device via ADB:

```bash
./docker-build.sh uninstall [FLAVOR]
```

The default flavor is `stbeta` if not specified. This command will uninstall the app corresponding to the specified flavor, which is useful during development to ensure a clean installation.

#### Running the Complete Build Process

To run the entire build process from start to finish in a single command:

```bash
./docker-build.sh all [FLAVOR]
```

This command will:
1. Build the Docker image (if it doesn't exist)
2. Build the specified flavor (default: stbeta)
3. Export the APKs to the builds directory
4. Prompt to install the APK if an Android device is connected

#### Exporting Built APKs

After building one or more flavors, you can copy all the generated APK files to a centralized location:

```bash
./docker-build.sh export-apks
```

This command will:
- Create a `builds` directory in the project root
- Copy all APK files from various flavor build directories to this location
- Rename the files to include the flavor name for easier identification

#### Cleaning the Build

```bash
./docker-build.sh clean
```

#### Opening a Shell in the Docker Container

To access a shell inside the Docker container for debugging or manual operations:

```bash
./docker-build.sh shell
```

#### Displaying Help

```bash
./docker-build.sh help
```

## Troubleshooting

### Memory Issues

If you encounter memory-related errors during the build, you may need to increase Docker's memory allocation in your Docker Desktop settings.

### Missing Submodules

If the build fails due to missing files in the submodules, ensure you've initialized the Git submodules:

```bash
git submodule update --init
```

## Notes

- The Docker container mounts the project directory as a volume, allowing you to edit files on your host system while building inside the container.
- The container uses OpenJDK 14 as specified in the project requirements (newer versions may cause app crashes).
- Each build operation starts with a clean state to prevent build inconsistencies.