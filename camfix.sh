#!/bin/bash

# Script to install Intel MIPI camera drivers on Ubuntu 24.04

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
  echo "You may need to try the development PPAs or the individual OEM archive method."
  echo "Proceeding with caution..."
fi

# Prompt user for development PPA or OEM archive installation
read -p "Do you want to try installing the userspace stack from the development PPAs (unstable, use at your own risk)? [y/N]: " use_ppa
if [[ "$use_ppa" =~ ^[Yy]$ ]]; then
  echo "Adding development PPAs..."
  sudo add-apt-repository ppa:oem-solutions-group/intel-ipu6
  sudo add-apt-repository ppa:oem-solutions-group/intel-ipu7
  sudo apt update
  echo "Listing available camera HAL packages..."
  ubuntu-drivers list
  read -p "Please enter the name of the appropriate libcamhal package (e.g., libcamhal-ipu6): " camhal_package
  if [[ -n "$camhal_package" ]]; then
    echo "Installing $camhal_package..."
    sudo apt install --yes "$camhal_package"
  else
    echo "No libcamhal package specified. Skipping installation from PPA."
  fi
else
  read -p "Do you want to try installing the userspace stack from an individual OEM archive (Dell/Lenovo)? [y/N]: " use_oem
  if [[ "$use_oem" =~ ^[Yy]$ ]]; then
    echo "Attempting installation from OEM archive..."
    if grep -qi "Dell" /sys/devices/virtual/dmi/id/board_vendor; then
      echo "Detected Dell system."
      sudo apt install --yes ubuntu-oem-keyring
      sudo add-apt-repository "deb http://dell.archive.canonical.com/ noble somerville"
      sudo apt update
      echo "Listing available camera HAL packages..."
      ubuntu-drivers list
      read -p "Please enter the name of the appropriate libcamhal package (e.g., libcamhal0): " camhal_package_oem
      if [[ -n "$camhal_package_oem" ]]; then
        echo "Installing $camhal_package_oem..."
        sudo apt install --yes "$camhal_package_oem"
      else
        echo "No libcamhal package specified for Dell. Skipping."
      fi
    elif grep -qi "Lenovo" /sys/devices/virtual/dmi/id/board_vendor; then
      echo "Detected Lenovo system."
      sudo apt install --yes ubuntu-oem-keyring
      sudo add-apt-repository "deb http://lenovo.archive.canonical.com/ noble sutton"
      sudo apt update
      echo "Listing available camera HAL packages..."
      ubuntu-drivers list
      read -p "Please enter the name of the appropriate libcamhal package (e.g., libcamhal0): " camhal_package_oem
      if [[ -n "$camhal_package_oem" ]]; then
        echo "Installing $camhal_package_oem..."
        sudo apt install --yes "$camhal_package_oem"
      else
        echo "No libcamhal package specified for Lenovo. Skipping."
      fi
    else
      echo "This system does not appear to be a Dell or Lenovo. Skipping OEM archive installation."
    fi
  else
    echo "Skipping userspace stack installation for now."
  fi
fi

# Install v4l2loopback (workaround) and v4l2-relayd
echo "Installing v4l2loopback and v4l2-relayd..."
sudo apt install --yes v4l2loopback v4l2-relayd

# Install gstreamer icamera plugins
echo "Installing gstreamer icamera plugins..."
sudo apt install --yes gst-plugins-icamera

echo "Installation process completed."
echo "Please reboot your system for the kernel modules to be loaded."
echo "You can try testing your camera with a web browser (gUM Test Page) after reboot."
echo "Note: The 'gst-launch-1.0 icamerasrc ! autovideosink' command may not work on all platforms."
