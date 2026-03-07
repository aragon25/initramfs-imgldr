#!/bin/bash
if [ -f "/usr/bin/initramfs-imgldr" ]; then
  echo "Prepare to remove ..."
  if [ "$1" == "remove" ]; then
    /usr/bin/initramfs-imgldr --clean >/dev/null 2>&1
    rm -rf "/usr/lib/initramfs-imgldr" >/dev/null 2>&1
  fi
fi
exit 0