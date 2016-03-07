#!/bin/sh
#
# init bbbike.org ubuntu deb repository

set -e
sources_list_d=/etc/apt/sources.list.d

init_apt_bbbike() {
    bbbike_list=bbbike.list
    apt_key=https://raw.githubusercontent.com/wosch/bbbike-world/world/etc/apt/trusty/gpg/bbbike.asc
    deb_url=http://debian.bbbike.org

    file="$sources_list_d/$bbbike_list"
    os=$(lsb_release -i | perl -npe 's,^Distributor ID:\s+,,; $_=lc($_)')
    codename=$(lsb_release -cs)

    if [ ! -e $file ]; then 
        wget -O- $apt_key | sudo apt-key add -
        sudo sh -c "echo deb $deb_url/${os}/${codename} ${codename} main > $file.tmp"
        sudo mv -f $file.tmp $file
        sudo apt-get update -qq
    fi
}

init_apt_mono() {
    mono_list=mono-xamarin.list
    mono_deb_url=http://download.mono-project.com/repo

    file="$sources_list_d/$mono_list"
    os=debian
    codename=wheezy

    if [ ! -e $file ]; then 
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

        sudo sh -c "echo deb $mono_deb_url/${os} ${codename} main > $file.tmp"
        sudo mv -f $file.tmp $file
        sudo apt-get update -qq
    fi
}

# required packages for this script
init_apt_deb() {
    sudo apt-get install -qq -y lsb-release wget
}

init_apt_deb
init_apt_bbbike
init_apt_mono
