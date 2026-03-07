#!/bin/bash
function undo_changes(){
  /usr/bin/initramfs-imgldr --clean >/dev/null 2>&1
  exit 1
}
if [ -f "/tmp/initramfs-imgldr_inst" ]; then
  rm -f "/tmp/initramfs-imgldr_inst" >/dev/null 2>&1
  echo "activate initramfs-imgldr ..."
  /usr/bin/initramfs-imgldr --initramfs_active >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  echo "activate fastboot in cmdline ..."
  /usr/bin/initramfs-imgldr -f  >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
else
  /usr/bin/initramfs-imgldr --update >/dev/null 2>&1
fi
exit 0