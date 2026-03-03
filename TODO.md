# TODO

- [ ] trixie: firstboot skripte deaktivieren
- [ ] trixie: sudo rm /etc/issue.d/IP.issue
- [ ] trixie: sudo touch /etc/cloud/cloud-init.disabled oder sudo apt remove cloud-guest-utils cloud-init --yes
- [ ] neue firstboot daten importieren

- [ ] imageauswahl in initramfs-imgldr skript fixed speichern -> symlink erstellen
- [ ] imageauswahl in initramfs-boot skript laden von symlink oder falls nicht vorhanden: auswahl zum booten anzeigen

- [ ] alle skripte in initramfs und temporär kopieren
- [ ] early reboot für auto-reboot integrieren
- [ ] funktionen von updater und configurator in imgldr skript packen und whiptail dialog erstellen
- [ ] alle dateien in lib speichern statt payload
- [ ] add Sevice output text -> echo "[$SCRIPT_TITLE] TEXT"

- [ ] boot=image option obsolet machen (ein skript vorschieben, das boot=image variable setzt)
- [x] wenn lokal verfügbar und kein image vorhanden dann automatisch lokal starten.
- [x] lokale installation falls vorhanden laden wenn kein sytem.img vorhanden

- [ ] steam os firmware like statt image?
- [ ] evtl. flatpak mit warehouse integrieren
- [ ] alle apt und dpkg installationen verhindern im usermode (ram und persistent)
- [ ] SquashFS + signatur nutzen statt image datei

- [ ] Test new Version 2.7