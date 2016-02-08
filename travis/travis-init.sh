#!/bin/sh
#
# init bbbike.org ubuntu deb repository

sources_list_d=/etc/apt/sources.list.d
bbbike_list=bbbike.list
apt_key=https://raw.githubusercontent.com/wosch/bbbike-world/world/etc/apt/trusty/gpg/bbbike.asc
deb_url=http://debian.bbbike.org

set -e

init_apt() {
    file="$sources_list_d/$bbbike_list"
    os=ubuntu

    if [ ! -e $file ]; then 
	codename=$(lsb_release -c -s)
        wget -O- $apt_key | sudo apt-key add -
        sudo sh -c "echo deb $deb_url/${os}/${codename} ${codename} main > $file.tmp"
        sudo mv -f $file.tmp $file
        sudo apt-get update -qq
    fi
}

init_apt

