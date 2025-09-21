#!/bin/bash

# Exit on Error
set -e

# Enable Verbose Output
# set -x

# Tag
FIRMWARE_SELECTOR_OPENWRT_ORG_TAG=${1-"latest"}

# Install Path
FIRMWARE_SELECTOR_OPENWRT_ORG_PATH="/usr/share/nginx/html/"

# Cache Path
FIRMWARE_SELECTOR_OPENWRT_ORG_CACHE_PATH="/var/lib/installer/firmware-selector-openwrt-org"

# Repository
FIRMWARE_SELECTOR_OPENWRT_ORG_REPOSITORY="openwrt/firmware-selector-openwrt-org"

# Tag or Latest have different URL Structure
if [[ "${FIRMWARE_SELECTOR_OPENWRT_ORG_TAG}" == "latest" ]]
then
   # Define Base URL
   FIRMWARE_SELECTOR_OPENWRT_ORG_BASE_URL="https://github.com/${FIRMWARE_SELECTOR_OPENWRT_ORG_REPOSITORY}/archive/refs/tags"

   # Retrieve what Version the "latest" tag Corresponds to
   FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION=$(curl -H "Accept: application/vnd.github.v3+json" -sS  "https://api.github.com/repos/${FIRMWARE_SELECTOR_OPENWRT_ORG_REPOSITORY}/tags" | jq -r '.[0].name')
elif [[ "${FIRMWARE_SELECTOR_OPENWRT_ORG_TAG}" == "main" ]]
then
   # Define Base URL
   FIRMWARE_SELECTOR_OPENWRT_ORG_BASE_URL="https://github.com/${FIRMWARE_SELECTOR_OPENWRT_ORG_REPOSITORY}/archive/refs/heads"

   # Version is the same as the Tag
   FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION="${FIRMWARE_SELECTOR_OPENWRT_ORG_TAG}"
else
   # Define Base URL
   FIRMWARE_SELECTOR_OPENWRT_ORG_BASE_URL="https://github.com/${FIRMWARE_SELECTOR_OPENWRT_ORG_REPOSITORY}/archive/refs/tags"

   # Version is the same as the Tag but strip the "v"
   FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION=$(echo "${FIRMWARE_SELECTOR_OPENWRT_ORG_TAG}" | sed -E "s|v(.*)|\1|")
fi

# Echo
echo "Base URL Set to: ${FIRMWARE_SELECTOR_OPENWRT_ORG_BASE_URL}"

# Firmware Selector Package Filename
FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_FILENAME="${FIRMWARE_SELECTOR_OPENWRT_ORG_TAG}.tar.gz"

# Firmware Selector Download Link
FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_URL="${FIRMWARE_SELECTOR_OPENWRT_ORG_BASE_URL}/${FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_FILENAME}"

# Temporary Fix
rm -f "${FIRMWARE_SELECTOR_OPENWRT_ORG_CACHE_PATH}/${FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION}/${FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_FILENAME}"

# List Files in Cache
ls -la "${FIRMWARE_SELECTOR_OPENWRT_ORG_CACHE_PATH}"

# Echo
echo "Package URL Set to: ${FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_URL}"

# Create Directory for Firmware Selector Storage (if it doesn't exist yet)
mkdir -p "${FIRMWARE_SELECTOR_OPENWRT_ORG_PATH}"

# Create a ${FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION} subdirectory within ${FIRMWARE_SELECTOR_OPENWRT_ORG_CACHE_PATH}
mkdir -p "${FIRMWARE_SELECTOR_OPENWRT_ORG_CACHE_PATH}/${FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION}"

# By default must download
FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_DOWNLOAD=1


# Check if Package File exists in Cache
if [[ -f "${FIRMWARE_SELECTOR_OPENWRT_ORG_CACHE_PATH}/${FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION}/${FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_FILENAME}" ]]
then
   # Package File exists
   FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_DOWNLOAD=0
fi

# Check if need to re-download Package
if [[ ${FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_DOWNLOAD} -ne 0 ]]
then
   # Download Package File
   echo "Downloading Package for Firmware Selector OpenWRT from ${FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_URL}"
   curl -sS -L --output-dir "${FIRMWARE_SELECTOR_OPENWRT_ORG_CACHE_PATH}/${FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION}" -o "${FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_FILENAME}" --create-dirs "${FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_URL}"
else
   # Echo
   echo "Using Cache for Firmware Selector OpenWRT from ${FIRMWARE_SELECTOR_OPENWRT_ORG_CACHE_PATH}/${FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION}/${FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_FILENAME}"
fi


# Extract Files (only www Subfolder) from Cache Folder to Destination Folder
tar xvf "${FIRMWARE_SELECTOR_OPENWRT_ORG_CACHE_PATH}/${FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION}/${FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_FILENAME}" --strip-components 2 -C "${FIRMWARE_SELECTOR_OPENWRT_ORG_PATH}" "firmware-selector-openwrt-org-${FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION}/www"

# Install git temporarily
apt-get update
apt-get install -y git

# Get Commit ID
commit_id=$(gunzip < "${FIRMWARE_SELECTOR_OPENWRT_ORG_CACHE_PATH}/${FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION}/${FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_FILENAME}" | git get-tar-commit-id)

# This is unfortunately not possible since the Information is lost. We would need to clone the Repository using git instead of downloading the Archive, in order to do this
# tag_description=(gunzip < "${FIRMWARE_SELECTOR_OPENWRT_ORG_CACHE_PATH}/${FIRMWARE_SELECTOR_OPENWRT_ORG_VERSION}/${FIRMWARE_SELECTOR_OPENWRT_ORG_PACKAGE_FILENAME}" | git --describe-tags)

# Fix Version String
cd "${FIRMWARE_SELECTOR_OPENWRT_ORG_PATH}"
sed -i "s|%GIT_VERSION%|${FIRMWARE_SELECTOR_OPENWRT_ORG_TAG}-${commit_id}|" index.js

# Remove git
apt-get remove -y git
apt-get autoremove -y
apt-get autoclean -y
apt-get clean -y
