#!/bin/bash
if [ "$(which initramfs-imgldr)" != "" ] && [ "$1" == "install" ]; then
  echo "The command \"initramfs-imgldr\" is already present. Can not install this."
  echo "File: \"$(which initramfs-imgldr)\""
  exit 1
fi
exit 0