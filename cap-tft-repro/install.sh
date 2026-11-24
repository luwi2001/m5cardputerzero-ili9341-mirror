#!/usr/bin/env bash
# Install cap-tft-mirror on a fresh Cardputer Zero (Raspberry Pi OS).
# Run from this directory:  bash install.sh
set -e

sudo apt-get update
sudo apt-get install -y python3-spidev python3-pil device-tree-compiler

sudo cp cap-tft-mirror /usr/local/bin/cap-tft-mirror
sudo chmod +x /usr/local/bin/cap-tft-mirror
sudo cp cap-tft-mirror.default /etc/default/cap-tft-mirror
sudo cp cap-tft-mirror.service /etc/systemd/system/cap-tft-mirror.service

dtc -@ -I dts -O dtb -o cap-tft-5v.dtbo cap-tft-5v.dts
sudo cp cap-tft-5v.dtbo /boot/firmware/overlays/cap-tft-5v.dtbo

CFG=/boot/firmware/config.txt
grep -q '^dtparam=spi=on' "$CFG" || echo 'dtparam=spi=on' | sudo tee -a "$CFG"
grep -q '^dtoverlay=cap-tft-5v' "$CFG" || echo 'dtoverlay=cap-tft-5v' | sudo tee -a "$CFG"

sudo systemctl daemon-reload
sudo systemctl enable cap-tft-mirror.service

echo
echo "Done. Reboot to apply (5V overlay + SPI):  sudo reboot"
