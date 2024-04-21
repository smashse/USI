#! /bin/bash
#  *Ubuntu, the distro for human begins
#  Author: Anderson Gama
#  License: GPL v3

cd /tmp

#CREATE NEW SOURCES LIST
clear
echo "Creating sources file with default Ubuntu repositories..."
sleep 3

echo "#ubuntu
deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-backports main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-proposed restricted main universe multiverse
#security
deb http://security.ubuntu.com/ubuntu $(lsb_release -sc)-security main restricted universe multiverse
#partner
deb http://archive.canonical.com/ubuntu $(lsb_release -sc) partner" | sudo tee /etc/apt/sources.list
sleep 3

#UPDATE AND UPGRADE UBUNTU BASE
clear
echo "Upgrading Ubuntu Base $(lsb_release -sr)..."
sleep 3
sudo apt update --fix-missing
sleep 3

clear
sudo apt -y dist-upgrade
sleep 3

#INSTALL BASE SYSTEM
echo "Installing base system for Ubuntu Base $(lsb_release -sr)..."
sudo apt -y install adb bash-completion btrfs-progs curl dphys-swapfile fdclone grub-efi-amd64 htop ifupdown ipset jq language-pack-pt linux-image-generic lvm2 mlocate nano ncdu network-manager net-tools nmap petname powerline resolvconf snap snapd screenfetch software-properties-common tar thin-provisioning-tools tldr tlp ubuntu-minimal unzip wipe whois wget xfsprogs xz-utils
sleep 3

#CUSTOM GRUB
clear
echo "Customizing grub for this installation method..."
sleep 3

echo "
# Old network interface names
GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"

# Uncomment to disable OS PROBE
GRUB_DISABLE_OS_PROBER=true" | sudo tee -a /etc/default/grub
sleep 3

#UPDATE GRUB
clear
echo "Updating grub..."
sleep 3
sudo update-grub2
sudo update-initramfs -u
sleep 3

#ENABLE AUTO FSCK
clear
echo "Enabling automatic disk integrity checking..."
sleep 3
echo "FSCKFIX=yes" | sudo tee /etc/default/rcS
echo "fsck.repair=yes" | sudo tee /boot/cmdline.txt
sleep 3

#ENABLE NETWORK MANAGER
clear
echo "Enabling network administration..."
sleep 3
sudo sed -i "s/=false/=true/g" /etc/NetworkManager/NetworkManager.conf
sudo touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
sleep 3

#CONFIG LOCALE
clear
echo "Setting the locale..."
sleep 3
echo "Choose your location. For example, if you live in Brazil, it will be [pt_BR], Portugal [pt_PT], in the USA [en_US]."
echo -n "Enter your location! "
read location
sleep 3
sudo locale-gen $location
sudo locale-gen $location.UTF-8
sudo dpkg-reconfigure locales
sudo update-locale LC_ALL="$location.UTF-8" LANG="$location.UTF-8" LANGUAGE="$location"
sleep 3

#CHOSE GUI
clear
gui() {
	echo "Chose your GUI: GNOME, KDE or XFCE?"
	sleep 3
	echo "Type gnome, kde or xfce"
	echo -n "What option is desired? "
	read gui

	case $gui in
	gnome) gnome ;;
	kde) kde ;;
	xfce) xfce ;;
	*)
		clear
		echo "Type [gnome], [kde] or [xfce]!"
		sleep 3
		clear
		gui
		;;
	esac

}

gnome() {
	clear
	echo "#Install GNOME!"
	sudo apt update --fix-missing
	sudo apt -y install gnome-shell gnome-shell-extensions chrome-gnome-shell gedit gnome-screensaver gnome-terminal gnome-tweaks language-selector-gnome language-pack-gnome-pt light-locker light-locker-settings lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings nautilus software-properties-common tilix yaru-theme-gnome-shell vlc
	sleep 3
}

kde() {
	clear
	echo "#Install KDE!"
	sudo curl -fsSL 'http://archive.neon.kde.org/public.key' | sudo apt-key add -
	sudo echo "deb http://archive.neon.kde.org/user $(lsb_release -cs) main" | sudo tee "/etc/apt/sources.list.d/kde-neon.list"
	sudo echo "deb http://archive.neon.kde.org/user/lts $(lsb_release -cs) main" | sudo tee -a "/etc/apt/sources.list.d/kde-neon.list"
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 444DABCF3667D0283F894EDDE6D4736255751E5D
	sudo apt update --fix-missing
	sudo apt -y install neon-desktop elisa vlc
	sleep 3
}

xfce() {
	clear
	echo "#Install XFCE!"
	sudo apt update --fix-missing
	su sudo apt -y install xfce4 light-locker light-locker-settings lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4-terminal language-selector-gnome language-pack-gnome-pt gnome-tweaks software-properties-common policykit-1-gnome policykit-desktop-privileges tilix vlc
	sleep 3
}

gui
clear

#SYSTEM76
system76() {
	echo "Do you want to add the SYSTEM76 repository?"
	sleep 3
	echo "Type yes or no!"
	echo -n "What option is desired? "
	read system76

	case $system76 in
	yes) yes ;;
	no) no ;;
	*)
		clear
		echo "Type [yes] if you want to add the repository or [no] to end the process!"
		sleep 3
		clear
		system76
		;;
	esac

}

yes() {
	clear
	echo "Adding the repository for SYSTEM76..."
	sleep 3
	sudo add-apt-repository ppa:system76/pop
	sudo apt-add-repository -ys ppa:system76-dev/stable
	sudo apt update --fix-missing
	sudo apt -y install grub-theme-pop plymouth-theme-pop-basic pop-gnome-shell-theme pop-icon-theme pop-theme system76-wallpapers
	sleep 3
	sudo runuser -l $USER -c 'gsettings set org.gnome.desktop.interface gtk-theme "Pop"'
	sleep 3
	sudo runuser -l $USER -c 'gsettings set org.gnome.desktop.interface icon-theme "Pop"'
	sleep 3
	sudo runuser -l $USER -c 'gsettings set org.gnome.desktop.interface cursor-theme "Pop"'
	sleep 3
	sudo runuser -l $USER -c 'gsettings set org.gnome.desktop.wm.preferences theme "Pop"'
	sleep 3
	sudo runuser -l $USER -c 'gsettings set org.gnome.desktop.wm.preferences titlebar-font "Ubuntu 11"'
	sleep 3
	sudo runuser -l $USER -c 'gsettings set org.gnome.desktop.interface document-font-name "Ubuntu 11"'
	sleep 3
	sudo runuser -l $USER -c 'gsettings set org.gnome.desktop.interface font-name "Ubuntu 11"'
	sleep 3
	sudo runuser -l $USER -c 'gsettings set org.gnome.desktop.interface monospace-font-name "Ubuntu Mono 12"'
	sleep 3
	sudo runuser -l $USER -c 'gsettings set org.gnome.nautilus.desktop font "Ubuntu 11"'
	sleep 3
	sudo runuser -l $USER -c 'gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/System76-Fractal_Mountains-by_Kate_Hazen_of_System76.png"'
	sleep 3
}

no() {
	echo "Ok, get brave, read the code and try again later!"
	sleep 3
}

system76
clear

#GOOGLE CHROME
chrome() {
	echo "Do you want to add the Google Chrome repository?"
	sleep 3
	echo "Type yes or no!"
	echo -n "What option is desired? "
	read chrome

	case $chrome in
	yes) yes ;;
	no) no ;;
	*)
		clear
		echo "Type [yes] if you want to add the repository or [no] to end this process!"
		sleep 3
		clear
		chrome
		;;
	esac

}

yes() {
	clear
	echo "Adding the repository for GOOGLE CHROME..."
	sudo curl -fsSL 'https://dl-ssl.google.com/linux/linux_signing_key.pub' | sudo apt-key add -
	sudo echo "deb http://dl.google.com/linux/chrome/deb stable main" | sudo tee "/etc/apt/sources.list.d/google-chrome.list"
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 4CCA1EAF950CEE4AB83976DCA040830F7FAC5991
	sudo apt-get update --fix-missing
	sudo apt -y install google-chrome-stable --force-yes
	sleep 3
}

no() {
	echo "Ok, get brave, read the code and try again later!"
	sleep 3
}

chrome
clear

#CHOSE CLOUD PROVIDER
clear
cloud() {
	echo "Chose your CLOUD PROVIDER: AWS, AZURE or GCP?"
	sleep 3
	echo "Type aws, azure, gcp or no"
	echo -n "What option is desired? "
	read cloud

	case $cloud in
	aws) aws ;;
	azure) azure ;;
	gcp) gcp ;;
	no) no ;;
	*)
		clear
		echo "Type [aws], [azure], [gcp] or [no] to end this process!"
		sleep 3
		clear
		cloud
		;;
	esac

}

aws() {
	clear
	echo "#AWS"
	sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/"awscliv2.zip"
	sudo unzip /tmp/awscliv2.zip -d /tmp/
	sudo sh /tmp/aws/install
	sleep 3
}

azure() {
	clear
	echo "#AZURE"
	sudo curl -fsSL 'https://packages.microsoft.com/keys/microsoft.asc' | sudo apt-key add -
	sudo echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee "/etc/apt/sources.list.d/azure-cli.list"
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF
	sudo apt update --fix-missing
	sudo apt -y install azure-cli
	sleep 3
}

gcp() {
	clear
	echo "#GCP"
	sudo curl -fsSL 'https://packages.cloud.google.com/apt/doc/apt-key.gpg' | sudo apt-key add -
	sudo echo "deb [arch=amd64] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee "/etc/apt/sources.list.d/google-cloud-sdk.list"
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 54A647F9048D5688D7DA2ABE6A030B21BA07F4FB
	sudo apt update --fix-missing
	sudo apt -y install google-cloud-sdk
	sleep 3
}

no() {
	echo "Ok, get brave, read the code and try again later!"
	sleep 3
}

cloud
clear

#HASHICORP
hashicorp() {
	echo "Do you want to add the HashiCorp repository?"
	sleep 3
	echo "Type yes or no!"
	echo -n "What option is desired? "
	read hashicorp

	case $hashicorp in
	yes) yes ;;
	no) no ;;
	*)
		clear
		echo "Type [yes] if you want to add the repository or [no] to end the process!"
		sleep 3
		clear
		hashicorp
		;;
	esac

}

yes() {
	clear
	echo "Adding the repository for HASHICORP..."
	sudo curl -fsSL 'https://apt.releases.hashicorp.com/gpg' | sudo apt-key add -
	sudo echo "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee "/etc/apt/sources.list.d/hashicorp.list"
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E8A032E094D8EB4EA189D270DA418C88A3219F7B
	sudo apt update --fix-missing
	sudo apt -y install terraform
	sleep 3
}

no() {
	echo "Ok, get brave, read the code and try again later!"
	sleep 3
}

hashicorp
clear

#CHOSE IDE
clear
ide() {
	echo "Chose your IDE: INTELLIJ, VSCODE or VSCODIUM?"
	sleep 3
	echo "Type intellij, vscode, vscodium or no"
	echo -n "What option is desired? "
	read ide

	case $ide in
	intellij) intellij ;;
	vscode) vscode ;;
	vscodium) vscodium ;;
	no) no ;;
	*)
		clear
		echo "Type [intellij], [vscode], [vscodium] or [no] to end this process!"
		sleep 3
		clear
		ide
		;;
	esac

}

intellij() {
	clear
	echo "#INTELLIJ"
	sudo snap install intellij-idea-community --classic
	sleep 3
}

vscode() {
	clear
	echo "#VSCODE"
	sudo snap install code --classic
	sleep 3
}

vscodium() {
	clear
	echo "#VSCODIUM"
	sudo snap install codium --classic
	sleep 3
}

no() {
	echo "Ok, get brave, read the code and try again later!"
	sleep 3
}

ide
clear

#KUBERNETES
clear
k8s() {
	echo "Do you want to install tools to work with KUBERNETES??"
	sleep 3
	echo "Type yes or no!"
	echo -n "What option is desired? "
	read k8s

	case $k8s in
	yes) yes ;;
	no) no ;;
	*)
		clear
		echo "Type [yes] if you want to install support to KUBECTL, HELM, LENS, K9S and POPEYE or [no] to end the process!"
		sleep 3
		clear
		k8s
		;;
	esac

}

yes() {
	clear
	echo "#KUBECTL"
	sudo snap install kubectl --classic
	echo "HELM"
	sudo snap install helm --classic
	echo "LENS"
	sudo snap install kontena-lens --classic
	echo "KUBENAV"
	cd /tmp
	wget -c https://github.com/kubenav/kubenav/releases/latest/download/kubenav-linux-amd64.zip
	unzip kubenav-linux-amd64.zip
	chmod a+x kubenav
	sudo mv kubenav /usr/local/sbin/
	echo "K9S+POPEYE"
	cd /tmp
	for i in $(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep 'browser_' | cut -d\" -f4 | grep "Linux_x86_64"); do wget -c $i -O "k9s.tar.gz"; done
	tar -zxvf k9s.tar.gz
	chmod a+x k9s
	sudo mv k9s /usr/local/sbin/
	for i in $(curl -s https://api.github.com/repos/derailed/popeye/releases/latest | grep 'browser_' | cut -d\" -f4 | grep "Linux_x86_64"); do wget -c $i -O "popeye.tar.gz"; done
	tar -zxvf popeye.tar.gz
	chmod a+x popeye
	sudo mv popeye /usr/local/sbin/
	sleep 3
}

no() {
	echo "Ok, get brave, read the code and try again later!"
	sleep 3
}

k8s
clear

#ENABLE POWERLINE
clear
echo "Enable POWERLINE..."
sudo echo '
#powerline
if [ -f `which powerline-daemon` ]; then
  powerline-daemon --quiet
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bindings/bash/powerline.sh
fi' | sudo tee -a /etc/bash.bashrc

#UPDATEME SCRIPT
clear
echo "Create UPDATEME..."
sudo echo '#!/bin/bash
sudo apt update --fix-missing
sudo apt -y dist-upgrade --download-only
sudo apt -y dist-upgrade
sudo apt -y autoremove
sudo apt -y clean
sudo snap set system refresh.retain=2
sudo snap refresh
sudo snap list --all | while read snapname ver rev trk pub notes; do if [[ $notes = *disabled* ]]; then sudo snap remove "$snapname" --revision="$rev"; fi; done
exit' | sudo tee /usr/local/sbin/updateme
sudo chmod 777 /usr/local/sbin/updateme

#ISOLATE APPS
sudo chmod 666 /usr/share/applications/*
cd /usr/share/applications/
for i in $(ls -1 | grep gnome); do echo "NotShowIn=XFCE;" >>$i; done
for i in $(ls -1 | grep gnome); do echo "OnlyShowIn=GNOME;" >>$i; done
for i in $(ls -1 | grep xfce); do echo "NotShowIn=GNOME;" >>$i; done
for i in $(ls -1 | grep xfce); do echo "OnlyShowIn=XFCE;" >>$i; done
sudo chmod 644 /usr/share/applications/*
cd /tmp

exit
