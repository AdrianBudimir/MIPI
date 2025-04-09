#!/bin/bash

# Script to install Intel MIPI camera drivers on Ubuntu 24.04 (Individual OEM Archive - Dell Only - No Prompts)

# Check if the script is run with sudo
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run with sudo privileges."
  exit 1
fi

# Update package lists
echo "Updating package lists..."
sudo apt update

# Determine the platform and install appropriate kernel modules and metapackages
echo "Determining your Intel platform..."
if grep -q "Tiger Lake" /proc/cpuinfo || grep -q "Alder Lake" /proc/cpuinfo || grep -q "Raptor Lake" /proc/cpuinfo || grep -q "Meteor Lake" /proc/cpuinfo; then
  echo "Detected Tiger Lake, Alder Lake, Raptor Lake, or Meteor Lake platform."
  echo "Installing generic HWE kernel modules..."
  sudo apt install --no-install-recommends --yes \
    linux-generic-hwe-24.04 \
    linux-modules-ipu6-generic-hwe-24.04 \
    linux-modules-usbio-generic-hwe-24.04
elif grep -q "Lunar Lake" /proc/cpuinfo || grep -q "Arrow Lake" /proc/cpuinfo; then
  echo "Detected Lunar Lake or Arrow Lake platform."
  echo "Installing OEM kernel modules (beta)..."
  sudo apt install --no-install-recommends --yes \
    linux-oem-24.04b \
    linux-modules-ipu6-oem-24.04b \
    linux-modules-ipu7-oem-24.04b \
    linux-modules-vision-oem-24.04b \
    linux-modules-usbio-oem-24.04b
else
  echo "Your Intel platform is not explicitly listed for direct OEM metapackage support."
  echo "Attempting installation from Dell OEM archive..."
fi

# Install from Dell OEM archive (No Prompts)
if grep -qi "Dell" /sys/devices/virtual/dmi/id/board_vendor; then
  echo "Detected Dell system."
  sudo apt install --yes ubuntu-oem-keyring
  sudo add-apt-repository "deb http://dell.archive.canonical.com/ noble somerville"
  sudo apt update
  echo "Listing available camera HAL packages..."
  ubuntu-drivers list
  echo "Please review the output above and manually install the appropriate libcamhal package"
  echo "using a command like: sudo apt install <libcamhal-package-name>"
  MANUAL_CAMHAL_REQUIRED=1
else
  echo "This system does not appear to be a Dell. Skipping Dell OEM archive installation."
  MANUAL_CAMHAL_REQUIRED=0
fi

# Install v4l2loopback (workaround) and v4l2-relayd
echo "Installing v4l2loopback and v4l2-relayd..."
sudo apt install --yes v4l2loopback v4l2-relayd

# Install gstreamer icamera plugins
echo "Installing gstreamer icamera plugins..."
sudo apt install --yes gst-plugins-icamera

echo "Installation process partially completed."
if [[ "$MANUAL_CAMHAL_REQUIRED" -eq 1 ]]; then
  echo "Please manually install the appropriate libcamhal package as instructed above."
fi
echo "Reboot your system for the kernel modules to be loaded."
echo "You can try testing your camera with a web browser (gUM Test Page) after reboot."
echo "Note: The 'gst-launch-1.0 icamerasrc ! autovideosink' command may not work on all platforms."
