#!/bin/bash

function firstSetup() {
    _UNAME="vpn"

    echo "### Enter new user name (default: $_UNAME):"
    read UNAME
    if [ -z $UNAME ]; then
    	UNAME=$_UNAME
    fi

    echo "### Enter new user password:"
    read UPASSW
    if [ -z $UPASSW ]; then
    	echo "Password is required"
        exit 1
    fi

    HOMEDIR="/home/"$UNAME

    #1 Update
    SERVER_PUB_IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1)
    echo -e "\n### Setup server ${SERVER_PUB_IP} ###"
    apt -qq update && apt -qq upgrade -y
    apt -qq install -y sudo

    echo "Create user..."
    PASSWORD=$(perl -e "print crypt(\"${UPASSW}\", \"salt\"),\"\n\"")
    useradd -m -d /home/$UNAME -p $PASSWORD -s /bin/bash $UNAME

    #2 Install apps
    echo -e "\n### Installing necessary apps"
    apt -qq install -y ufw mc curl wget unzip zsh git certbot dnsutils nano htop net-tools wireguard apache2 mariadb-server mariadb-client python3-pip python3-venv lsb-release ca-certificates apt-transport-https software-properties-common gnupg2 snapd
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
    wget -qO - https://packages.sury.org/php/apt.gpg | sudo apt-key add -
    apt -qq update
    apt -qq install -y php8.2 php8.2-cli php8.2-common php8.2-opcache php8.2-curl php8.2-mbstring php8.2-mysql php8.2-zip php8.2-xml php8.2-gd php8.2-gmp #php8.2-imagick

    #3 Create user
    usermod -aG root $UNAME
    usermod -aG www-data $UNAME
    usermod -aG sudo $UNAME

    exit
}

firstSetup