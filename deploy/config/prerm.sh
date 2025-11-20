#!/bin/bash
if [ -f "/lib/systemd/system/imgldr-configurator.service" ]; then
  echo "Stop and disable service ..."
  systemctl stop imgldr-configurator.service >/dev/null 2>&1
  systemctl disable imgldr-configurator.service >/dev/null 2>&1
  systemctl daemon-reload >/dev/null 2>&1
fi
[ -e "/usr/bin/imgldr-updater" ] && [ -e "/run/imgldr-updater.pid" ] && pkill --pidfile /run/imgldr-updater.pid
if [ -f "/usr/bin/initramfs-imgldr" ]; then
  echo "Prepare to remove ..."
  if [ "$1" == "remove" ]; then
    /usr/bin/initramfs-imgldr --clean >/dev/null 2>&1
    rm -f "/etc/initramfs-tools/scripts/init-top/imgldr_update" >/dev/null 2>&1
    rm -f "/etc/initramfs-tools/scripts/init-top/imgldr_fixes" >/dev/null 2>&1
    rm -f "/etc/initramfs-tools/scripts/image" >/dev/null 2>&1
    #echo "INFO: you can delete /boot/config-initramfs.txt and /boot/initramfs.img"
    #echo "if you dont need initramfs image anymore, but please remove"
    #echo "\"include config-initramfs.txt\" line in /boot/config.txt also!"
  else
    /usr/bin/initramfs-imgldr --remove >/dev/null 2>&1
  fi
fi
exit 0