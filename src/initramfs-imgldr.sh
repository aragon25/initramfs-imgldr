#!/bin/bash
##############################################
##                                          ##
##  initramfs-imgldr                        ##
##  update payload lines in script:         ##
##  - payload.tar.gz is in same dir         ##
##  - run script with --payload_pack        ##
##  extract payload.tar.gz from script:     ##
##  - run script with --payload_unpack      ##
##                                          ##
##############################################

#get some variables
SCRIPT_TITLE="initramfs-imgldr"
SCRIPT_VERSION="2.7"

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
UNPACK_DIR="$(mktemp -d)"
if mountpoint -q "/boot/firmware"; then 
  BOOT_DIR=/boot/firmware
elif mountpoint -q "/boot"; then
  BOOT_DIR=/boot
fi
EXITCODE=0

#!!!RUN RESTRICTIONS!!!
#only for raspberry pi (rpi5|rpi4|rpi3|all) can combined!
raspi="all"
#only for Raspbian OS (trixie|bookworm|bullseye|all) can combined!
rasos="trixie|bookworm|bullseye"
#only for cpu architecture (i386|armhf|amd64|arm64) can combined!
cpuarch=""
#only for os architecture (32|64) can NOT combined!
bsarch=""
#this aptpaks need to be installed!
aptpaks=( initramfs-tools cpio sed )

#check commands
for i in "$@"
do
  case $i in
    --update)
    cmd="${cmd}update"
    shift # past argument
    ;;
    -c|--clean)
    cmd="${cmd}clean"
    shift # past argument
    ;;
    -i|--initramfs_active)
    cmd="${cmd}initramfs_active"
    shift # past argument
    ;;
    -I|--initramfs_inactive)
    cmd="${cmd}initramfs_inactive"
    shift # past argument
    ;;
    -f|--cmdline_fastboot_active)
    cmd="${cmd}cmdline_fastboot_active"
    shift # past argument
    ;;
    -F|--cmdline_fastboot_inactive)
    cmd="${cmd}cmdline_fastboot_inactive"
    shift # past argument
    ;;
    --payload_pack)
    cmd="${cmd}payload_pack"
    shift # past argument
    ;;
    --payload_unpack)
    cmd="${cmd}payload_unpack"
    shift # past argument
    ;;
    -v|--version)
    cmd="${cmd}version"
    shift # past argument
    ;;
    -h|--help)
    cmd="${cmd}help"
    shift # past argument
    ;;
    *)
    if [ "$i" != "" ]
    then
      echo "Unknown option: $i"
      exit 1
    fi
    ;;
  esac
done
if [[ "$cmd" =~ "initramfs_active" ]] && [[ "$cmd" =~ "initramfs_inactive" ]]; then
  echo "option initramfs_active and initramfs_inactive can not combined!"
  cmd="help"
fi
if [[ "$cmd" =~ "cmdline_fastboot_active" ]] && [[ "$cmd" =~ "cmdline_fastboot_inactive" ]]; then
  echo "option cmdline_fastboot_active and cmdline_fastboot_inactive can not combined!"
  cmd="help"
fi
if [[ "$cmd" =~ "clean" ]] && [[ "$cmd" != "clean" ]]; then
  echo "option clean can not combined with other options!"
  cmd="help"
fi
if [[ "$cmd" =~ "update" ]] && [[ "$cmd" != "update" ]]; then
  echo "option update can not combined with other options!"
  cmd="help"
fi
if [[ "$cmd" =~ "payload_pack" ]] && [[ "$cmd" != "payload_pack" ]]; then
  echo "option payload_pack can not combined with other options!"
  cmd="help"
fi
if [[ "$cmd" =~ "payload_unpack" ]] && [[ "$cmd" != "payload_unpack" ]]; then
  echo "option payload_unpack can not combined with other options!"
  cmd="help"
fi
if [[ "$cmd" =~ "help" ]] || [ "$cmd" == "" ]; then
  cmd="help"
fi
if [[ "$cmd" =~ "version" ]]; then
  cmd="version"
fi

function set_base_perms() {
  local filetype
  local entry
  local test
  IFS=$'\n'
  test=($(find "$1"))
  if [ "${#test[@]}" != "0" ]; then
    for entry in ${test[@]}; do
      chown -f 0:0 "$entry"
      if [ -f "$entry" ]; then
        filetype=$(file -b --mime-type "$entry" 2>/dev/null)
        if [[ "$filetype" =~ "executable" ]] || [[ "$filetype" =~ "script" ]] || 
           [[ "$entry" == *".desktop" ]] || [[ "$entry" == *".sh" ]]|| [[ "$entry" == *".py" ]]; then
          chmod -f 755 "$entry"
        else
          chmod -f 644 "$entry"
        fi
      elif [ -d "$entry" ]; then
        chmod -f 755 "$entry"
      fi
    done
  fi
  unset IFS
}

function do_check_start() {
  #check if superuser
  if [ $UID -ne 0 ]; then
    echo "Please run this script with Superuser privileges!"
    exit 1
  fi
  #check if raspberry pi 
  if [ "$raspi" != "" ]; then
    raspi_v="$(tr -d '\0' 2>/dev/null < /proc/device-tree/model)"
    local raspi_res="false"
    [[ "$raspi_v" =~ "Raspberry Pi" ]] && [[ "$raspi" =~ "all" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 3" ]] && [[ "$raspi" =~ "rpi3" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 4" ]] && [[ "$raspi" =~ "rpi4" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 5" ]] && [[ "$raspi" =~ "rpi5" ]] && raspi_res="true"
    if [ "$raspi_res" == "false" ]; then
      echo "This Device seems not to be an Raspberry Pi ($raspi)! Can not continue with this script!"
      exit 1
    fi
  fi
  #check if raspbian
  if [ "$rasos" != "" ]
  then
    rasos_v="$(lsb_release -d -s 2>/dev/null)"
    [ -f /etc/rpi-issue ] && rasos_v="Raspbian ${rasos_v}"
    local rasos_res="false"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos" =~ "all" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "bullseye" ]] && [[ "$rasos" =~ "bullseye" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "bookworm" ]] && [[ "$rasos" =~ "bookworm" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "trixie" ]] && [[ "$rasos" =~ "trixie" ]] && rasos_res="true"
    if [ "$rasos_res" == "false" ]; then
      echo "You need to run Raspbian OS ($rasos) to run this script! Can not continue with this script!"
      exit 1
    fi
  fi
  #check cpu architecture
  if [ "$cpuarch" != "" ]; then
    cpuarch_v="$(dpkg --print-architecture 2>/dev/null)"
    if [[ ! "$cpuarch" =~ "$cpuarch_v" ]]; then
      echo "Your CPU Architecture ($cpuarch_v) is not supported! Can not continue with this script!"
      exit 1
    fi
  fi
  #check os architecture
  if [ "$bsarch" == "32" ] || [ "$bsarch" == "64" ]; then
    bsarch_v="$(getconf LONG_BIT 2>/dev/null)"
    if [ "$bsarch" != "$bsarch_v" ]; then
      echo "Your OS Architecture ($bsarch_v) is not supported! Can not continue with this script!"
      exit 1
    fi
  fi
  #check apt paks
  local apt
  local apt_res
  IFS=$' '
  if [ "${#aptpaks[@]}" != "0" ]; then
    for apt in ${aptpaks[@]}; do
      [[ ! "$(dpkg -s $apt 2>/dev/null)" =~ "Status: install" ]] && apt_res="${apt_res}${apt}, "
    done
    if [ "$apt_res" != "" ]; then
      echo "Not installed apt paks: ${apt_res%?%?}! Can not continue with this script!"
      exit 1
    fi
  fi
  unset IFS
  #check boot partition mount
  if [ -z "$BOOT_DIR" ]; then 
    echo "Could not find bootpartition! exit."
    exit 1
  fi
  #bootro state
  if findmnt -n -o OPTIONS "$BOOT_DIR" | egrep "^ro,|,ro,|,ro$" &>/dev/null; then
    BOOT_READONLY="true"
  fi
}

function set_boot_rw() {
  [ -n "$BOOT_READONLY" ] && mount -o remount,rw $BOOT_DIR
}

function set_boot_ro() {
  [ -n "$BOOT_READONLY" ] && mount -o remount,ro $BOOT_DIR
}

function extract_files() {
  local PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ { print NR + 1; exit 0; }' "$SCRIPT_PATH")
  [ -z "$PAYLOAD_LINE" ] && return 1
  rm -rf "$UNPACK_DIR"
  mkdir -p "$UNPACK_DIR"
  tail -n +${PAYLOAD_LINE} "$SCRIPT_PATH" | base64 -d | tar -zpvx -C "$UNPACK_DIR" &>/dev/null
  local result=$?
  set_base_perms "$UNPACK_DIR"
  return $result
}

function cmd_payload_pack() {
  if [ $UID -ne 0 ]; then
    echo "Please run this script with Superuser privileges!"
    EXITCODE=1
    return 1
  fi
  local payload_dirname="$(basename "$SCRIPT_NAME" ".sh")_payload"
  local PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ { print NR; exit 0; }' "$SCRIPT_PATH")
  if [ -d "${SCRIPT_DIR}/${payload_dirname}" ]; then
    rm -f "/tmp/payload.tar.gz"
    ( cd "${SCRIPT_DIR}/${payload_dirname}" && tar -czf "/tmp/payload.tar.gz" . )
    rm -rf "${SCRIPT_DIR}/${payload_dirname}"
  fi
  if [ -f "$SCRIPT_DIR/payload.tar.gz" ]; then
    rm -f "/tmp/payload.tar.gz"
    mv -f "$SCRIPT_DIR/payload.tar.gz" "/tmp/payload.tar.gz"
  fi
  if [ ! -f "/tmp/payload.tar.gz" ]; then
    echo "... Could not find 'payload'. EXIT ..."
    EXITCODE=1
    return 1
  fi
  if [ -z "$PAYLOAD_LINE" ]; then
    echo "__PAYLOAD_BEGINS__" >> "$SCRIPT_PATH"
    PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ { print NR; exit 0; }' "$SCRIPT_PATH")
  fi
  cp -f "$SCRIPT_PATH" "/tmp/payload_tmp"
  head -n +${PAYLOAD_LINE} /tmp/payload_tmp > "$SCRIPT_PATH"
  base64 "/tmp/payload.tar.gz" >> "$SCRIPT_PATH"
  rm -f "/tmp/payload_tmp"
  rm -f "/tmp/payload.tar.gz"
}

function cmd_payload_unpack() {
  if [ $UID -ne 0 ]; then
    echo "Please run this script with Superuser privileges!"
    EXITCODE=1
    return 1
  fi
  local u="${SUDO_USER:-$(logname 2>/dev/null)}"
  local g="$(id -gn "$u" 2>/dev/null)"
  local payload_dirname="$(basename "$SCRIPT_NAME" ".sh")_payload"
  local PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ { print NR + 1; exit 0; }' "$SCRIPT_PATH")
  [ -z "$PAYLOAD_LINE" ] && EXITCODE=1 && return 1
  rm -rf "${SCRIPT_DIR}/${payload_dirname}"
  mkdir -p "${SCRIPT_DIR}/${payload_dirname}"
  tail -n +${PAYLOAD_LINE} "$SCRIPT_PATH" | base64 -d | tar -zpvx -C "${SCRIPT_DIR}/${payload_dirname}" &>/dev/null
  set_base_perms "${SCRIPT_DIR}/${payload_dirname}"
  [ -n "$u" ] && [ -n "$g" ] && chown -fR "$u:$g" "${SCRIPT_DIR}/${payload_dirname}" 2>/dev/null
}

function cmd_clean() {
  cmd_initramfs_inactive
}

function cmd_update() {
  if [ -e "/etc/initramfs-tools/scripts/imgldr" ]; then
    install_initramfs >/dev/null 2>&1
    update_initramfs >/dev/null 2>&1
  fi
}

function update_initramfs() {
  local exitcode=0
  local distib="$(lsb_release -d -s 2>/dev/null)"
  [ -f /etc/rpi-issue ] && distib="Raspbian ${distib}"
  set_boot_rw
  sed -i '/^initramfs /d' "$BOOT_DIR/config.txt"
  sed -i '/^include config-initramfs.txt/d' "$BOOT_DIR/config.txt"
  sed -i '/^include config-custom.txt/d' "$BOOT_DIR/config.txt"
  sed -i '/\[all\][^\n]*/,$!b;//{x;//p;g};//!H;$!d;x;s//&\ninclude config-custom.txt/' "$BOOT_DIR/config.txt"
  [ -e "$BOOT_DIR/config-custom.txt" ] || touch "$BOOT_DIR/config-custom.txt"
  rm -f "$BOOT_DIR/config-initramfs.txt" >/dev/null 2>&1
  mkdir -p "/etc/initramfs-tools/conf.d"
  echo "MODULES=most" > "/etc/initramfs-tools/conf.d/imgldr"
  if [[ "$distib" =~ "bullseye" ]]; then
    local suffix_long
    local suffix_short
    local kernel_version=$(basename $(ls -dv /lib/modules/* 2>/dev/null | tail -n1) 2>/dev/null | sed 's/-.*//')
    for suffix_long in "+" "-v7+" "-v7l+" "-v8+"; do
      [ "$suffix_long" == "+" ] && suffix_short=""
      [ "$suffix_long" == "-v7+" ] && suffix_short="7"
      [ "$suffix_long" == "-v7l+" ] && suffix_short="7l"
      [ "$suffix_long" == "-v8+" ] && suffix_short="8"
      if [ -e "/lib/modules/${kernel_version}${suffix_long}" ]; then
        update-initramfs -c -k "${kernel_version}${suffix_long}"
        if [ $? -eq 0 ]; then
          echo "$BOOT_DIR/initrd.img-${kernel_version}${suffix_long} -> $BOOT_DIR/initramfs${suffix_short}"
          mv -f "$BOOT_DIR/initrd.img-${kernel_version}${suffix_long}" "$BOOT_DIR/initramfs${suffix_short}"
        else
          echo "... updating initramfs image for ${kernel_version}${suffix_long} failed ..."
          exitcode=1
        fi
      fi
    done
    if [ $exitcode -eq 0 ]; then
      local kernel_suf=$([ "$(getconf LONG_BIT 2>/dev/null)" = "64" ] && echo "8" || echo "7l")
      sed -i '/\[all\][^\n]*/,$!b;//{x;//p;g};//!H;$!d;x;s//&\ninclude config-initramfs.txt/' "$BOOT_DIR/config.txt"
      [ -f "$BOOT_DIR/kernel.img" ] && [ -f "$BOOT_DIR/initramfs" ] && cat >>"$BOOT_DIR/config-initramfs.txt" <<EOF
[all]
kernel=kernel.img
initramfs initramfs followkernel
EOF
      [ -f "$BOOT_DIR/kernel7.img" ] && [ -f "$BOOT_DIR/initramfs7" ] && cat >>"$BOOT_DIR/config-initramfs.txt" <<EOF
[pi2]
kernel=kernel7.img
initramfs initramfs7 followkernel
[pi3]
kernel=kernel7.img
initramfs initramfs7 followkernel
EOF
      [ -f "$BOOT_DIR/kernel${kernel_suf}.img" ] && [ -f "$BOOT_DIR/initramfs${kernel_suf}" ] && cat >>"$BOOT_DIR/config-initramfs.txt" <<EOF
[pi3+]
kernel=kernel${kernel_suf}.img
initramfs initramfs${kernel_suf} followkernel
[pi4]
kernel=kernel${kernel_suf}.img
initramfs initramfs${kernel_suf} followkernel
EOF
    else
      echo "... updating initramfs image/s failed ..."
      EXITCODE=1
      return 1
    fi
  elif [[ "$distib" =~ "bookworm" ]] || [[ "$distib" =~ "trixie" ]]; then
    update-initramfs -u
    if [ $? -eq 0 ]; then
      sed -i '/\[all\][^\n]*/,$!b;//{x;//p;g};//!H;$!d;x;s//&\ninclude config-initramfs.txt/' "$BOOT_DIR/config.txt"
      echo "[all]" > "$BOOT_DIR/config-initramfs.txt"
      echo "auto_initramfs=1" >> "$BOOT_DIR/config-initramfs.txt"
    else
      echo "... updating initramfs image/s failed ..."
      EXITCODE=1
      return 1
    fi
  fi
  set_boot_ro
  echo "initramfs image/s updated."
}

function install_initramfs() {
  local files_ok="true"
  remove_initramfs >/dev/null 2>&1
  extract_files
  if [ $? -ne 0 ]; then
    echo "... Could not install imgldr to initramfs-tools directory! (extract error) ..."
    EXITCODE=1
    return 1
  fi
  mkdir -p "/etc/initramfs-tools/scripts/init-premount"
  cp -af "$UNPACK_DIR/imgldr_init" "/etc/initramfs-tools/scripts/init-premount/imgldr_init"
  [ -f "/etc/initramfs-tools/scripts/init-premount/imgldr_init" ] || files_ok="false"
  cp -af "$UNPACK_DIR/imgldr_boot" "/etc/initramfs-tools/scripts/imgldr"
  [ -f "/etc/initramfs-tools/scripts/imgldr" ] || files_ok="false"
  cp -af "$UNPACK_DIR/imgldr_functions" "/etc/initramfs-tools/scripts/imgldr_functions"
  [ -f "/etc/initramfs-tools/scripts/imgldr_functions" ] || files_ok="false"
  chmod +x "/etc/initramfs-tools/scripts/init-premount/imgldr_init"
  rm -rf "$UNPACK_DIR"
  if [ "$files_ok" == "false" ]; then
    echo "... Could not install imgldr to initramfs-tools directory! (copy error) ..."
    remove_initramfs &>/dev/null
    EXITCODE=1
    return 1
  fi
  if ! grep overlay /etc/initramfs-tools/modules > /dev/null; then
    echo overlay >> /etc/initramfs-tools/modules
  fi
  if ! grep squashfs /etc/initramfs-tools/modules > /dev/null; then
    echo squashfs >> /etc/initramfs-tools/modules
  fi
  echo "installed imgldr to initramfs-tools directory."
}

function remove_initramfs() {
  rm -f "/etc/initramfs-tools/scripts/init-premount/imgldr_init"
  rm -f "/etc/initramfs-tools/scripts/imgldr"
  rm -f "/etc/initramfs-tools/scripts/imgldr_functions"
  rm -f "/etc/initramfs-tools/conf.d/imgldr" >/dev/null 2>&1
  echo "removed imgldr from initramfs-tools directory."
}

function cmd_initramfs_active() {
  install_initramfs
  update_initramfs
  echo "initramfs imgldr installed!"
}

function cmd_initramfs_inactive() {
  remove_initramfs
  update_initramfs
  echo "initramfs imgldr removed!"
}

function cmd_cmdline_fastboot_active() {
  cmd_cmdline_fastboot_inactive
  set_boot_rw
  sed -i 's/$/ fastboot/g' "$BOOT_DIR/cmdline.txt"
  set_boot_ro
}

function cmd_cmdline_fastboot_inactive() {
  set_boot_rw
  sed -i -e 's/ fastboot//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/fastboot //' "$BOOT_DIR/cmdline.txt"
  set_boot_ro
}

function cmd_print_version() {
  echo "$SCRIPT_TITLE v$SCRIPT_VERSION"
}

function cmd_print_help() {
  echo "Usage: $SCRIPT_NAME [OPTION]"
  echo "$SCRIPT_TITLE v$SCRIPT_VERSION"
  echo " "
  echo "Lightweight initramfs image-loader installer and manager for Raspberry Pi systems."
  echo "Loads image file: /IMAGES/system.sqfs and boots from it if available"
  echo " "
  echo "-c, --clean                       remove initramfs-splash, unset cmdline splash,"
  echo "                                  unset cmdline hide term cursor and rebuild image"
  echo "-i, --initramfs_active            install files to initramfs and rebuild image"
  echo "-I, --initramfs_inactive          remove files from initramfs and rebuild image"
  echo "-f, --cmdline_fastboot_active     set fastboot flag in cmdline.txt"
  echo "-F, --cmdline_fastboot_inactive   unset fastboot flag in cmdline.txt"
  echo "-v, --version                     print version info and exit"
  echo "-h, --help                        print this help and exit"
  echo " "
  echo "Author: aragon25 <aragon25.01@web.de>"
}

[ "$cmd" != "version" ] && [ "$cmd" != "help" ] && \
[ "$cmd" != "payload_pack" ] && [ "$cmd" != "payload_unpack" ] && do_check_start
[[ "$cmd" == "version" ]] && cmd_print_version
[[ "$cmd" == "help" ]] && cmd_print_help
[[ "$cmd" == "clean" ]] && cmd_clean
[[ "$cmd" == "update" ]] && cmd_update
[[ "$cmd" =~ "initramfs_active" ]] && cmd_initramfs_active
[[ "$cmd" =~ "initramfs_inactive" ]] && cmd_initramfs_inactive
[[ "$cmd" =~ "cmdline_fastboot_active" ]] && cmd_cmdline_fastboot_active
[[ "$cmd" =~ "cmdline_fastboot_inactive" ]] && cmd_cmdline_fastboot_inactive
[[ "$cmd" == "payload_pack" ]] && cmd_payload_pack
[[ "$cmd" == "payload_unpack" ]] && cmd_payload_unpack

exit $EXITCODE
