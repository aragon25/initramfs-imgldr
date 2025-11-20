# Changelog

All notable changes to this project will be documented in this file.

## [2.6-2] - 2025-11-20

### Changed
- first release for github

## [2.6-1] - 2025-11-18

### Added
- shows same logo in plymouth-rpi-spinner as in initramfs-splash (>= 2.2-1)
- Saves hw-clock data every 15 mins
- creates static selfsigned ssl-cert now

### Fixed
- small bugfixes

### Changed
- admin home will not be reseted in SAVEDBOOT and SETUPMODE now

## [2.5-3] - 2025-07-16

### Fixed
- small bugfixes

## [2.5-2] - 2025-07-09

### Fixed
- small bugfixes

### Added
- sync plymouth-rpi-spinner with initramfs-splash

## [2.5-1] - 2025-07-08

### Fixed
- small bugfixes
- umount fixed

### Added
- disabled kernel updates, raspi-config, rpi-update
- Generates all initramfs images for Raspberry Pi OS bullseye

### Changed
- moved files and folders from /.conf dir to /STATIC

## [2.4-1] - 2025-07-01

### Fixed
- small bugfixes

### Added
- new /STATIC directory
- hw-clock saves stored in /STATIC dir

## [2.3-3] - 2025-07-01

### Fixed
- small bugfixes

## [2.3-2] - 2025-02-22

### Fixed
- small bugfixes

## [2.3-1] - 2025-02-02

### Fixed
- small bugfixes

### Changed
- Optimized updates
- Update is not compatible with lower versions anymore

## [2.2-1] - 2025-01-05

### Fixed
- small bugfixes

### Added
- oem.img support

### Changed
- boot.img now integrated in system.img and oem.img
