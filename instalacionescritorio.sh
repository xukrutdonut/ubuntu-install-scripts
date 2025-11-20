#!/bin/bash
sudo add-apt-repository ppa:apt-fast/stable
sudo add-apt-repository ppa:flatpak/stable
sudo add-apt-repository ppa:nilarimogard/webupd8 
sudo add-apt-repository ppa:webupd8team/y-ppa-manager
sudo add-apt-repository ppa:danielrichter2007/grub-customizer
sudo add-apt-repository ppa:oguzhaninan/stacer
sudo apt-get update

# wget "https://global.synologydownload.com/download/Utility/SynologyDriveClient/3.5.0-16084/Ubuntu/Installer/synology-drive-client-16084.x86_64.deb"
# wget "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
# wget "https://dl.google.com/dl/earth/client/current/google-earth-stable_current_amd64.deb"
# sudo dpkg -i google-earth-stable*.deb
# sudo dpkg -i synology-drive-client-*.deb
sudo apt-get install apt-fast tlp tlp-rdw ubuntu-restricted-extras gnome-tweak-tool flatpak gdebi libfuse2t64 cheese gimp vlc synaptic timeshift wine y-ppa-manager gnome-software-plugin-flatpak grub-customizer terminus stacer openconnect pcsc-tools pcscd filezilla spotify whatsapp-desktop virtualbox zotero
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'
# wget "https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/synaptics-repository-keyring.deb"
# sudo apt install synaptics-repository-keyring.deb
# sudo apt-get update
# sudo apt install displaylink-driver


#ELIMINAR FIREFOX SNAP:

sudo snap remove firefox

sudo install -d -m 0755 /etc/apt/keyrings

wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null

echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla

sudo apt update && sudo apt install firefox

