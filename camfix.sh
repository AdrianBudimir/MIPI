#!/bin/bash

# Script to install Intel MIPI camera drivers on Ubuntu 24.04 (Dell OEM Archive based on ubuntu-drivers list)

# Check if the script is run with sudo
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run with sudo privileges."
  exit 1
fi

# Update package lists
echo "Updating package lists..."
sudo apt update

# Probe for available drivers
echo "Probing for available drivers using ubuntu-drivers list..."
available_drivers=$(ubuntu-drivers list)

# Define the list of target libcamhal packages
target_packages=("libcamhal-ipu6" "libcamhal-ipu6ep" "libcamhal-ipu6epmtl" "libcamhal-ipu7x" "libcamhal-ipu75xa")

found_package=""

# Search for the target packages in the available drivers list
for package in "${target_packages[@]}"; do
  if echo "$available_drivers" | grep -q "$package"; then
    found_package="$package"
    echo "Found matching libcamhal package: $found_package"
    break
  fi
done

# If a target package is found, add the Dell repository and install it
if [[ -n "$found_package" ]]; then
  echo "Adding Dell OEM repository..."
  sudo apt install --yes ubuntu-oem-keyring
  sudo add-apt-repository "deb http://dell.archive.canonical.com/ noble somerville"
  sudo apt update
  echo "Installing found package: $found_package..."
  sudo apt install --yes "$found_package"

  # Install v4l2loopback and v4l2-relayd
  echo "Installing v4l2loopback and v4l2-relayd..."
  sudo apt install --yes v4l2loopback v4l2-relayd

  # Install gstreamer icamera plugins
  echo "Installing gstreamer icamera plugins..."
  sudo apt install --yes gst-plugins-icamera

  echo "Installation completed. Please reboot your system."
  echo "You can try testing your camera with a web browser (gUM Test Page) after reboot."
  echo "Note: The 'gst-launch-1.0 icamerasrc ! autovideosink' command may not work on all platforms."

else
  echo "No matching libcamhal package found in the list of available drivers."
  echo "The Dell repository was not added, and no specific package was installed."
  echo "You might need to try other installation methods or ensure the correct drivers are available."
fi
