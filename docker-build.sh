#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}"
IMAGE_NAME="smarttube-builder"
CONTAINER_NAME="smarttube-builder-container"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

print_help() {
  echo -e "${GREEN}SmartTube Docker Build Helper${NC}"
  echo -e "---------------------------------"
  echo -e "Usage: $0 [COMMAND]"
  echo -e ""
  echo -e "Commands:"
  echo -e "  ${YELLOW}build-image${NC}      Build Docker image for SmartTube development"
  echo -e "  ${YELLOW}shell${NC}            Start a shell in the Docker container"
  echo -e "  ${YELLOW}build${NC} [FLAVOR]   Build the SmartTube app"
  echo -e "                   Flavors: stbeta, ststable, storig, strtarmenia, stredboxtv, stfiretv"
  echo -e "                   Default: storig"
  echo -e "  ${YELLOW}clean${NC}            Clean build outputs"
  echo -e "  ${YELLOW}export-apks${NC}      Copy all built APKs to the ./builds directory"
  echo -e "  ${YELLOW}install${NC} [FLAVOR] Install APK of specified flavor to connected device via ADB"
  echo -e "                   Default: stbeta"
  echo -e "  ${YELLOW}uninstall${NC} [FLAVOR] Uninstall app of specified flavor from connected device via ADB"
  echo -e "                   Default: stbeta"
  echo -e "  ${YELLOW}all${NC} [FLAVOR]     Run complete process: build image, build app, export APKs, install"
  echo -e "                   Default: stbeta"
  echo -e "  ${YELLOW}help${NC}             Show this help message"
  echo -e ""
  echo -e "Examples:"
  echo -e "  $0 build-image"
  echo -e "  $0 build stbeta"
  echo -e "  $0 export-apks"
  echo -e "  $0 install stbeta"
  echo -e "  $0 uninstall stbeta"
  echo -e "  $0 all stbeta"
  echo -e "  $0 shell"
}

build_docker_image() {
  echo -e "${GREEN}Building Docker image...${NC}"
  docker build -t ${IMAGE_NAME} "${PROJECT_DIR}"
}

run_docker_shell() {
  ensure_docker_image
  init_submodules
  
  echo -e "${GREEN}Starting shell in Docker container...${NC}"
  docker run --rm -it \
    -v "${PROJECT_DIR}:/app" \
    -v "${PROJECT_DIR}/SharedModules:/app/SharedModules" \
    -v "${PROJECT_DIR}/MediaServiceCore:/app/MediaServiceCore" \
    --name ${CONTAINER_NAME} \
    ${IMAGE_NAME} bash -c "chmod +x /app/gradlew && cd /app && bash"
}

ensure_docker_image() {
  if ! docker image inspect ${IMAGE_NAME} &>/dev/null; then
    echo -e "${YELLOW}Docker image not found. Building it now...${NC}"
    build_docker_image
  fi
}

init_submodules() {
  echo -e "${GREEN}Initializing git submodules...${NC}"
  
  # Check if SharedModules exists and has content
  if [ ! -d "${PROJECT_DIR}/SharedModules" ] || [ ! "$(ls -A "${PROJECT_DIR}/SharedModules" 2>/dev/null)" ]; then
    echo -e "${YELLOW}SharedModules submodule empty or missing. Cloning...${NC}"
    rm -rf "${PROJECT_DIR}/SharedModules"
    git clone https://github.com/yuliskov/SharedModules "${PROJECT_DIR}/SharedModules"
  fi
  
  # Check if MediaServiceCore exists and has content
  if [ ! -d "${PROJECT_DIR}/MediaServiceCore" ] || [ ! "$(ls -A "${PROJECT_DIR}/MediaServiceCore" 2>/dev/null)" ]; then
    echo -e "${YELLOW}MediaServiceCore submodule empty or missing. Cloning...${NC}"
    rm -rf "${PROJECT_DIR}/MediaServiceCore"
    git clone https://github.com/yuliskov/MediaServiceCore "${PROJECT_DIR}/MediaServiceCore"
  fi
}

build_app() {
  local flavor=$1
  if [ -z "$flavor" ]; then
    flavor="storig"
  fi
  
  # Capitalize first letter of flavor for gradle task
  local flavor_cap=$(capitalize "$flavor")
  
  ensure_docker_image
  init_submodules
  
  echo -e "${GREEN}Building SmartTube ${flavor} flavor...${NC}"
  docker run --rm \
    -v "${PROJECT_DIR}:/app" \
    -v "${PROJECT_DIR}/SharedModules:/app/SharedModules" \
    -v "${PROJECT_DIR}/MediaServiceCore:/app/MediaServiceCore" \
    --name ${CONTAINER_NAME} \
    ${IMAGE_NAME} \
    bash -c "chmod +x /app/gradlew && cd /app && ./gradlew clean assemble${flavor_cap}Debug"
  
  echo -e "${GREEN}Build completed!${NC}"
  echo -e "APKs can be found in the following directories:"
  echo -e "  - smarttubetv/build/outputs/apk/${flavor}/debug/"
  
  # List generated APK files
  echo -e "${YELLOW}Generated APK files:${NC}"
  find "${PROJECT_DIR}/smarttubetv/build/outputs/apk/${flavor}/debug" -name "*.apk" 2>/dev/null | while read -r apk; do
    echo "  - $(basename "$apk")"
  done
}

clean_build() {
  ensure_docker_image
  init_submodules
  
  echo -e "${GREEN}Cleaning build outputs...${NC}"
  docker run --rm \
    -v "${PROJECT_DIR}:/app" \
    -v "${PROJECT_DIR}/SharedModules:/app/SharedModules" \
    -v "${PROJECT_DIR}/MediaServiceCore:/app/MediaServiceCore" \
    --name ${CONTAINER_NAME} \
    ${IMAGE_NAME} \
    bash -c "chmod +x /app/gradlew && cd /app && ./gradlew clean"
  
  echo -e "${GREEN}Clean completed!${NC}"
}

# Make first letter uppercase
capitalize() {
  local str=$1
  local first_char=$(echo "${str:0:1}" | tr '[:lower:]' '[:upper:]')
  local rest_str="${str:1}"
  echo "${first_char}${rest_str}"
}

export_apks() {
  local output_dir="${PROJECT_DIR}/builds"
  mkdir -p "${output_dir}"
  
  echo -e "${GREEN}Exporting APKs to ${output_dir}...${NC}"
  
  # Find all APK files and copy them to the output directory
  find "${PROJECT_DIR}/smarttubetv/build/outputs/apk" -name "*.apk" 2>/dev/null | while read -r apk; do
    flavor_path=$(echo "$apk" | sed -n 's/.*\/apk\/\([^\/]*\)\/debug\/.*/\1/p')
    cp -v "$apk" "${output_dir}/$(basename "$apk" | sed "s/\.apk/_${flavor_path}.apk/")"
  done
  
  echo -e "${GREEN}Exported APKs can be found in: ${output_dir}${NC}"
  ls -la "${output_dir}"
}

install_apk() {
  local flavor=$1
  if [ -z "$flavor" ]; then
    flavor="stbeta"
  fi
  
  local output_dir="${PROJECT_DIR}/builds"
  
  echo -e "${GREEN}Checking for ADB connection...${NC}"
  if ! adb devices | grep -q "device$"; then
    echo -e "${RED}No ADB devices connected. Please connect a device and try again.${NC}"
    return 1
  fi
  
  echo -e "${GREEN}Looking for armeabi-v7a ${flavor} APK to install...${NC}"
  local apk_path=$(find "${output_dir}" -name "*armeabi-v7a*_${flavor}.apk" | sort -r | head -1)
  
  # If no armeabi-v7a APK found, check if user wants to try another version
  if [ -z "$apk_path" ]; then
    echo -e "${YELLOW}No armeabi-v7a APK found for flavor ${flavor}.${NC}"
    
    # List available APKs for this flavor
    echo -e "${YELLOW}Available APKs for ${flavor}:${NC}"
    find "${output_dir}" -name "*_${flavor}.apk" -exec basename {} \; | sort
    
    echo -e "${YELLOW}Would you like to install a different architecture? (y/n)${NC}"
    read -r -n 1 use_alt
    echo
    
    if [[ "$use_alt" =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}Available APKs:${NC}"
      local available_apks=($(find "${output_dir}" -name "*_${flavor}.apk"))
      
      if [ ${#available_apks[@]} -eq 0 ]; then
        echo -e "${RED}No APKs found for flavor ${flavor}. Build it first with './docker-build.sh build ${flavor}'${NC}"
        return 1
      fi
      
      for i in "${!available_apks[@]}"; do
        echo "[$i] $(basename "${available_apks[$i]}")"
      done
      
      echo -e "${YELLOW}Enter the number of the APK to install:${NC}"
      read -r apk_num
      
      if [[ "$apk_num" =~ ^[0-9]+$ ]] && [ "$apk_num" -lt "${#available_apks[@]}" ]; then
        apk_path="${available_apks[$apk_num]}"
      else
        echo -e "${RED}Invalid selection.${NC}"
        return 1
      fi
    else
      echo -e "${YELLOW}Build the app with armeabi-v7a architecture for Android TV devices:${NC}"
      echo -e "${YELLOW}./docker-build.sh build ${flavor}${NC}"
      return 1
    fi
  fi
  
  echo -e "${GREEN}Installing APK: $(basename "$apk_path")${NC}"
  adb install -r "$apk_path"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Installation successful!${NC}"
  else
    echo -e "${RED}Installation failed!${NC}"
    return 1
  fi
}

uninstall_app() {
  local flavor=$1
  if [ -z "$flavor" ]; then
    flavor="stbeta"
  fi
  
  local package_name=""
  
  # Map flavor to package name
  case "$flavor" in
    stbeta)
      package_name="com.liskovsoft.smarttubetv.beta"
      ;;
    ststable)
      package_name="com.teamsmart.videomanager.tv"
      ;;
    storig)
      package_name="org.smartteam.smarttube.tv.orig"
      ;;
    strtarmenia)
      package_name="com.google.android.youtube.tv"
      ;;
    stredboxtv)
      package_name="com.redboxtv.smartyoutubetv"
      ;;
    stfiretv)
      package_name="com.amazon.firetv.youtube"
      ;;
    *)
      echo -e "${RED}Unknown flavor: ${flavor}${NC}"
      echo -e "${YELLOW}Available flavors: stbeta, ststable, storig, strtarmenia, stredboxtv, stfiretv${NC}"
      return 1
      ;;
  esac
  
  echo -e "${GREEN}Checking for ADB connection...${NC}"
  if ! adb devices | grep -q "device$"; then
    echo -e "${RED}No ADB devices connected. Please connect a device and try again.${NC}"
    return 1
  fi
  
  echo -e "${YELLOW}Uninstalling app package: ${package_name}${NC}"
  adb uninstall "$package_name"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Uninstallation successful!${NC}"
  else
    echo -e "${RED}Uninstallation failed! App may not be installed or package name is incorrect.${NC}"
    return 1
  fi
}

build_all() {
  local flavor=$1
  if [ -z "$flavor" ]; then
    flavor="stbeta"
  fi
  
  echo -e "${GREEN}Starting complete build process for flavor: ${flavor}${NC}"
  
  # Step 1: Build the Docker image
  build_docker_image
  
  # Step 2: Build the specified flavor
  build_app "$flavor"
  
  # Step 3: Export the APKs
  export_apks
  
  # Step 4: Optionally install the APK if a device is connected
  if adb devices | grep -q "device$"; then
    echo -e "${YELLOW}Android device found. Would you like to install the APK? (y/n)${NC}"
    read -r -n 1 install_choice
    echo
    if [[ "$install_choice" =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}Installing armeabi-v7a version for Android TV...${NC}"
      install_apk "$flavor"
    else
      echo -e "${YELLOW}Skipping installation.${NC}"
    fi
  else
    echo -e "${YELLOW}No Android device connected. Skipping installation.${NC}"
  fi
  
  echo -e "${GREEN}Complete build process finished!${NC}"
}

# Main script logic
case "$1" in
  build-image)
    build_docker_image
    ;;
  shell)
    ensure_docker_image
    run_docker_shell
    ;;
  build)
    build_app "$2"
    ;;
  clean)
    clean_build
    ;;
  export-apks)
    export_apks
    ;;
  install)
    install_apk "$2"
    ;;
  uninstall)
    uninstall_app "$2"
    ;;
  all)
    build_all "$2"
    ;;
  help|"")
    print_help
    ;;
  *)
    echo -e "${RED}Unknown command: $1${NC}"
    print_help
    exit 1
    ;;
esac