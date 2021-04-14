#! /bin/bash
#  *Ubuntu, the distro for human begins
#  Author: Anderson Gama
#  License: GPL v3

cd /tmp
sudo apt -y install curl jq wget wipe

#LIST DEVICES
clear
sudo lsblk -I 8 -d
echo "Above you have the list of disk devices present in your equipment. Which one do you want to work on?"
sleep 3
echo "Choose your device. For example, if you are going to install the OS on SATA or USB disks, it should be something like [sda] for the first, [sdb] for the second and so on."
read -p "Enter the desired device: " device
export device
echo export device=$device >/tmp/env.txt
sleep 3

#EXPORT CHROOT FOLDER
export jail="/media/$USER/mobile"
echo export jail="/media/$USER/mobile" >>/tmp/env.txt

source /tmp/env.txt

#DISK PARTITIONING
wipe() {
    clear
    echo "This script was created by someone who was tired of reinstalling Ubuntu using the most difficult method (but much more fun and light in the end). It uses Ubuntu Base 20.04.2 LTS (Focal Fossa), feel free to copy it and adapt to your needs! This procedure will erase the the selected device, do you want to proceed?"
    sleep 3
    echo "Type yes or no!"
    echo -n "What option is desired? "
    read wipe

    case $wipe in
    yes) yes ;;
    no) no ;;
    *)
        clear
        echo "Type [yes] if you want to erase the second disc and proceed or [no] to end the process!"
        sleep 3
        clear
        wipe
        ;;
    esac

}

yes() {
    clear
    sleep 3
    sudo umount -l $jail
    sleep 3
    sudo rm -rf $jail
    sleep 3
    sudo wipefs -a -f /dev/$device
    sleep 3
    sudo partprobe -s /dev/$device
    sleep 3
    sudo parted -s /dev/$device mklabel msdos
    sleep 3
    sudo parted -s /dev/$device print free
    sleep 3
    sudo parted -a optimal -s /dev/$device mkpart primary ext4 0% 512MB
    sleep 3
    sudo parted -a optimal -s /dev/$device mkpart primary ext4 512MB 100%
    sleep 3
    sudo parted -s /dev/$device print free
    sleep 3
    sudo mkfs.vfat -n UEFI /dev/$device"1"
    sleep 3
    sudo mkfs.xfs -f -L MOBILE /dev/$device"2"
    sleep 3
    sudo partprobe -s /dev/$device
    sleep 3
    sudo lsblk -I 8 -d
    sleep 3
}

no() {
    echo "Ok, get brave, read the code and try again later!"
    sleep 3
    exit
}

wipe
clear

#DOWNLOAD UBUNTU BASE
clear
echo "Downloading Ubuntu Base 20.04.2 LTS (Focal Fossa)..."
sleep 3
wget -c http://cdimage.ubuntu.com/ubuntu-base/releases/focal/release/ubuntu-base-20.04.2-base-amd64.tar.gz
sleep 3

#CREATE AND MOUNT MEDIA FOLDER
clear
echo "Creation and assembly of the folder used by chroot..."
sleep 3
sudo mkdir -p $jail
sudo mount -t xfs --rw /dev/$device"2" $jail
sleep 3

#EXTRACT UBUNTU BASE
clear
echo "Extracting Ubuntu Base 20.04.2 LTS (Focal Fossa)..."
sleep 3
sudo tar -zxvf ubuntu-base-20.04.2-base-amd64.tar.gz -C $jail/
sleep 3

#COPY RESOLV CONFIG
clear
sudo cp /etc/resolv.conf $jail/etc/
sleep 3

#MOUNT CHROOT
clear
echo "Mounting the $jail folder to be used with chroot..."
sleep 3
for f in /sys /proc /dev; do sudo mount --rbind $f $jail/$f; done
sleep 3

#CREATE NEW SOURCES LIST
clear
echo "Creating sources file with Ubuntu repositories..."
sleep 3
sudo chmod 666 $jail/etc/apt/sources.list

echo "#ubuntu
deb http://archive.ubuntu.com/ubuntu focal main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-backports main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-proposed restricted main universe multiverse
#security
deb http://security.ubuntu.com/ubuntu focal-security main restricted universe multiverse
#partner
deb http://archive.canonical.com/ubuntu focal partner" >$jail/etc/apt/sources.list

sudo chmod 644 $jail/etc/apt/sources.list
sleep 3

#UPDATE AND UPGRADE UBUNTU BASE
clear
echo "Upgrading Ubuntu Base 20.04.2 LTS (Focal Fossa)..."
sleep 3
sudo chroot $jail apt update --fix-missing
sleep 3

clear
sudo chroot $jail apt -y dist-upgrade
sleep 3

#INSTALL BASE SYSTEM
clear
echo "Installing base system for Ubuntu Base 20.04.2 LTS (Focal Fossa)..."
sudo chroot $jail apt -y install adb bash-completion btrfs-progs curl dphys-swapfile fdclone grub-efi-amd64 htop ifupdown ipset jq language-pack-pt linux-image-generic lvm2 mlocate nano ncdu network-manager net-tools nmap petname powerline resolvconf snap snapd screenfetch software-properties-common tar thin-provisioning-tools tldr tlp ubuntu-minimal unzip whois wget xfsprogs xz-utils
sleep 3

#CREATE USER
clear
echo "Creating the user that will be used to access the system..."
sleep 3
echo "Choose your username!"
echo -n "Type the username! "
read username
sleep 3

clear
echo "Create the user with administrative permissions!"
sleep 3
sudo chroot $jail adduser $username
sudo chroot $jail addgroup $username adm
sudo chroot $jail addgroup $username sudo
sleep 3

#CUSTOM GRUB
clear
echo "Customizing grub for this installation method..."
sleep 3
sudo chmod 666 $jail/etc/default/grub

echo "
# Old network interface names
GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"

# Uncomment to disable OS PROBE
GRUB_DISABLE_OS_PROBER=true" >>$jail/etc/default/grub

sudo chmod 644 $jail/etc/default/grub
sleep 3

#CONFIG FSTAB
clear
echo "Configuring fstab..."
sudo chmod 666 $jail/etc/fstab

echo "proc          /proc proc     defaults     0     0
UUID="blkid_UEFI"     /boot/efi     vfat     umask=0077     0     1
UUID="blkid_MOBILE"     /     ext4     defaults,nodev,noatime,nodiratime     0     1" >$jail/etc/fstab

sudo sed -i "s/blkid_UEFI/$(sudo blkid -p /dev/$device"1" -l -t LABEL=UEFI -s UUID -o value)/g" $jail/etc/fstab
sudo sed -i "s/blkid_MOBILE/$(sudo blkid -p /dev/$device"2" -l -t LABEL=MOBILE -s UUID -o value)/g" $jail/etc/fstab

sudo chmod 644 $jail/etc/fstab

sudo chroot $jail mkdir -p /boot/efi
sudo chroot $jail mount -a
sleep 3

#UPDATE GRUB
clear
echo "Updating grub..."
sleep 3
sudo chroot $jail update-grub2
sudo chroot $jail update-initramfs -u
sudo chroot $jail grub-install --target=x86_64-efi --force /dev/$device
sleep 3

#ENABLE AUTO FSCK
clear
echo "Enabling automatic disk integrity checking..."
sleep 3
sudo touch $jail/etc/default/rcS
sudo chmod 666 $jail/etc/default/rcS
echo "FSCKFIX=yes" >$jail/etc/default/rcS
sudo chmod 644 $jail/etc/default/rcS
sleep 3

clear
sudo touch $jail/boot/cmdline.txt
sudo chmod 666 $jail/boot/cmdline.txt
echo "fsck.repair=yes" >$jail/boot/cmdline.txt
sudo chmod 644 $jail/boot/cmdline.txt
sleep 3

#ENABLE NETWORK MANAGER
clear
echo "Enabling network administration..."
sleep 3
sudo chmod 666 $jail/etc/NetworkManager/NetworkManager.conf
sudo sed -i "s/=false/=true/g" $jail/etc/NetworkManager/NetworkManager.conf
sudo chmod 644 $jail/etc/NetworkManager/NetworkManager.conf
sleep 3

clear
sudo touch $jail/etc/NetworkManager/conf.d/10-globally-managed-devices.conf
sleep 3

#CONFIG LOCALE
clear
echo "Setting the locale..."
sleep 3
echo "Choose your location. For example, if you live in Brazil, it will be [pt_BR], Portugal [pt_PT], in the USA [en_US]."
echo -n "Enter your location! "
read location
sleep 3
sudo chroot $jail locale-gen $location
sudo chroot $jail locale-gen $location.UTF-8
sudo chroot $jail dpkg-reconfigure locales
sudo chroot $jail update-locale LC_ALL="$location.utf8" LANG="$location.utf8" LANGUAGE="$location"
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
    sudo chroot $jail apt update --fix-missing
    sudo chroot $jail apt -y install gnome-shell gnome-shell-extensions chrome-gnome-shell gedit gnome-screensaver gnome-terminal gnome-tweak-tool gnome-tweaks language-selector-gnome language-pack-gnome-pt light-locker light-locker-settings lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings nautilus software-properties-common tilix yaru-theme-gnome-shell vlc
    sleep 3
}

kde() {
    clear
    echo "#Install KDE!"
    sudo touch $jail/etc/apt/sources.list.d/kde-neon.list
    sudo chmod 666 $jail/etc/apt/sources.list.d/kde-neon.list
    sudo chroot $jail curl -fsSL 'http://archive.neon.kde.org/public.key' | sudo apt-key add -
    sudo echo "deb http://archive.neon.kde.org/user $(lsb_release -cs) main" >"$jail/etc/apt/sources.list.d/kde-neon.list"
    sudo echo "deb http://archive.neon.kde.org/user/lts $(lsb_release -cs) main" >>"$jail/etc/apt/sources.list.d/kde-neon.list"
    sudo chmod 644 $jail/etc/apt/sources.list.d/kde-neon.list
    sudo chroot $jail apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 444DABCF3667D0283F894EDDE6D4736255751E5D
    sudo chroot $jail apt update --fix-missing
    sudo chroot $jail apt -y install neon-desktop elisa vlc
    sleep 3
}

xfce() {
    clear
    echo "#Install XFCE!"
    sudo chroot $jail apt update --fix-missing
    sudo chroot $jail apt -y install xfce4 light-locker light-locker-settings lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings xfce4-terminal language-selector-gnome language-pack-gnome-pt gnome-tweak-tool gnome-tweaks software-properties-common policykit-1-gnome policykit-desktop-privileges tilix vlc
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
    sudo chroot $jail add-apt-repository ppa:system76/pop
    sudo chroot $jail apt-add-repository -ys ppa:system76-dev/stable
    sudo chroot $jail apt update --fix-missing
    sudo chroot $jail apt -y install grub-theme-pop plymouth-theme-pop-basic pop-gnome-shell-theme pop-icon-theme pop-theme system76-wallpapers
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
    sudo touch $jail/etc/apt/sources.list.d/google-chrome.list
    sudo chmod 666 $jail/etc/apt/sources.list.d/google-chrome.list
    sudo chroot $jail curl -fsSL 'https://dl-ssl.google.com/linux/linux_signing_key.pub' | sudo apt-key add -
    sudo echo "deb http://dl.google.com/linux/chrome/deb stable main" >"$jail/etc/apt/sources.list.d/google-chrome.list"
    sudo chmod 644 $jail/etc/apt/sources.list.d/google-chrome.list
    sudo chroot $jail apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 4CCA1EAF950CEE4AB83976DCA040830F7FAC5991
    sudo chroot $jail apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796
    sudo chroot $jail apt-get update --fix-missing
    sudo chroot $jail apt -y install google-chrome-stable --force-yes
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
    sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o $jail/tmp/"awscliv2.zip"
    sudo unzip $jail/tmp/awscliv2.zip -d $jail/tmp/
    sudo chroot $jail sh /tmp/aws/install
    sleep 3
}

azure() {
    clear
    echo "#AZURE"
    sudo touch $jail/etc/apt/sources.list.d/azure-cli.list
    sudo chmod 666 $jail/etc/apt/sources.list.d/azure-cli.list
    sudo chroot $jail curl -fsSL 'https://packages.microsoft.com/keys/microsoft.asc' | sudo apt-key add -
    sudo echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" >"$jail/etc/apt/sources.list.d/azure-cli.list"
    sudo chmod 644 $jail/etc/apt/sources.list.d/azure-cli.list
    sudo chroot $jail apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF
    sudo chroot $jail apt update --fix-missing
    sudo chroot $jail apt -y install azure-cli
    sleep 3
}

gcp() {
    clear
    echo "#GCP"
    sudo touch $jail/etc/apt/sources.list.d/google-cloud-sdk.list
    sudo chmod 666 $jail/etc/apt/sources.list.d/google-cloud-sdk.list
    sudo chroot $jail curl -fsSL 'https://packages.cloud.google.com/apt/doc/apt-key.gpg' | sudo apt-key add -
    sudo echo "deb [arch=amd64] http://packages.cloud.google.com/apt cloud-sdk main" >"$jail/etc/apt/sources.list.d/google-cloud-sdk.list"
    sudo chmod 644 $jail/etc/apt/sources.list.d/google-cloud-sdk.list
    sudo chroot $jail apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 54A647F9048D5688D7DA2ABE6A030B21BA07F4FB
    sudo chroot $jail apt update --fix-missing
    sudo chroot $jail apt -y install google-cloud-sdk
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
    sudo touch $jail/etc/apt/sources.list.d/hashicorp.list
    sudo chmod 666 $jail/etc/apt/sources.list.d/hashicorp.list
    sudo chroot $jail curl -fsSL 'https://apt.releases.hashicorp.com/gpg' | sudo apt-key add -
    sudo echo "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" >"$jail/etc/apt/sources.list.d/hashicorp.list"
    sudo chmod 666 $jail/etc/apt/sources.list.d/hashicorp.list
    sudo chroot $jail apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E8A032E094D8EB4EA189D270DA418C88A3219F7B
    sudo chroot $jail apt update --fix-missing
    sudo chroot $jail apt -y install terraform
    sleep 3
}

no() {
    echo "Ok, get brave, read the code and try again later!"
    sleep 3
}

hashicorp
clear

#POSTINST
clear
echo "Adding the POSTINST SCRIPT..."
echo "Open a terminal after booting with the chosen device on a computer and run "postinst", this script will help you install an IDE for editing code and tools for working with KUBERNETES."
sudo touch $jail/usr/local/sbin/postinst
sudo chmod 777 $jail/usr/local/sbin/postinst
sudo echo '#!/bin/bash
#CHOSE IDE
clear
ide() {
	echo "Chose your IDE: ATOM, INTELLIJ or VSCODE?"
	sleep 3
	echo "Type atom, intellij, vscode or no"
	echo -n "What option is desired? "
	read ide

	case $ide in
		atom) atom ;;
		intellij) intellij ;;
		vscode) vscode ;;
		no) no ;;
		*) clear ; echo "Type [atom], [intellij], [vscode] or [no] to end this process!" ; sleep 3 ; clear ; ide ;;
	esac

}

atom() {
	clear
	echo "#ATOM"
	sudo snap install atom --classic
	sleep 3
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
		*) clear ; echo "Type [yes] if you want to install support to KUBECTL, HELM, LENS, K9S and POPEYE or [no] to end the process!" ; sleep 3 ; clear ; k8s ;;
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
    for i in `curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep 'browser_' | cut -d\" -f4 | grep "Linux_x86_64"` ; do wget -c $i -O "k9s.tar.gz" ; done
    tar -zxvf k9s.tar.gz
    chmod a+x k9s
    sudo mv k9s /usr/local/sbin/
    for i in `curl -s https://api.github.com/repos/derailed/popeye/releases/latest | grep 'browser_' | cut -d\" -f4 | grep "Linux_x86_64"` ; do wget -c $i -O "popeye.tar.gz" ; done
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
exit' >$jail/usr/local/sbin/postinst

#ENABLE POWERLINE
sudo chmod 666 $jail/etc/bash.bashrc
sudo echo '
#powerline
if [ -f `which powerline-daemon` ]; then
  powerline-daemon --quiet --replace
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bindings/bash/powerline.sh
fi' >>$jail/etc/bash.bashrc
sudo chmod 644 $jail/etc/bash.bashrc

#UPDATEME SCRIPT
sudo touch $jail/usr/local/sbin/updateme
sudo chmod 777 $jail/usr/local/sbin/updateme
sudo echo '#!/bin/bash
sudo apt update --fix-missing
sudo apt -y dist-upgrade --download-only
sudo apt -y dist-upgrade
sudo apt -y autoremove
sudo apt -y clean
sudo snap set system refresh.retain=2
sudo snap refresh
sudo snap list --all | while read snapname ver rev trk pub notes; do if [[ $notes = *disabled* ]]; then sudo snap remove "$snapname" --revision="$rev"; fi; done
exit' >$jail/usr/local/sbin/updateme

#ISOLATE APPS
sudo chmod 666 $jail/usr/share/applications/*
cd $jail/usr/share/applications/
for i in $(ls -1 | grep gnome); do echo "NotShowIn=XFCE;" >>$i; done
for i in $(ls -1 | grep gnome); do echo "OnlyShowIn=GNOME;" >>$i; done
for i in $(ls -1 | grep xfce); do echo "NotShowIn=GNOME;" >>$i; done
for i in $(ls -1 | grep xfce); do echo "OnlyShowIn=XFCE;" >>$i; done
sudo chmod 644 $jail/usr/share/applications/*
cd /tmp

exit
