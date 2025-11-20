#!/bin/bash
function undo_changes(){
  systemctl stop imgldr-configurator.service >/dev/null 2>&1
  systemctl disable imgldr-configurator.service >/dev/null 2>&1
  /usr/bin/initramfs-imgldr --clean >/dev/null 2>&1
  rm -f "/etc/initramfs-tools/scripts/init-top/imgldr_update" >/dev/null 2>&1
  rm -f "/etc/initramfs-tools/scripts/init-top/imgldr_fixes" >/dev/null 2>&1
  rm -f "/etc/initramfs-tools/scripts/image" >/dev/null 2>&1
  exit 1
}
if [ -f "/usr/bin/initramfs-imgldr" ]; then
  echo "update initramfs-tools folder ..."
  /usr/bin/initramfs-imgldr --install >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  echo "generate initramfs-image/s ..."
  /usr/bin/initramfs-imgldr --update_initramfs >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
fi
if [ -f "/lib/systemd/system/imgldr-configurator.service" ]; then
  echo "Start and enable service ..."
  systemctl daemon-reload >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  systemctl enable imgldr-configurator.service >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  touch "/run/imgldr-configurator.lock"
  systemctl start imgldr-configurator.service >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
fi
exit 0