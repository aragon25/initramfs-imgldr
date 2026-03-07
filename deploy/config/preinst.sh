#!/bin/bash
if [ "$(which initramfs-imgldr)" != "" ] && [ "$1" == "install" ]; then
  echo "The command \"initramfs-imgldr\" is already present. Can not install this."
  echo "File: \"$(which initramfs-imgldr)\""
  exit 1
fi
if [ "$1" == "install" ]; then
  mkdir -p "/tmp" >/dev/null 2>&1
  touch "/tmp/initramfs-imgldr_inst" 2>/dev/null
fi
exit 0