#!/bin/sh
# Copyright (c) 2016-2017 Wolfram Schneider, https://bbbike.org
#
# init bbbike.org ubuntu deb repository

: ${DEBUG=false}

if $DEBUG; then
  set -x
fi
set -e

sources_list_d=/etc/apt/sources.list.d

init_apt_bbbike() {
    bbbike_list=bbbike.list
    apt_key=https://raw.githubusercontent.com/wosch/bbbike-world/world/etc/apt/debian/jessie/gpg/bbbike.asc
    deb_url=https://debian.bbbike.org

    file="$sources_list_d/$bbbike_list"
    os=$(lsb_release -i | perl -npe 's,^Distributor ID:\s+,,; $_=lc($_)')
    codename=$(lsb_release -cs)

    if [ ! -e $file ]; then 
        curl -sSf $apt_key | sudo apt-key add -
        sudo sh -c "echo deb $deb_url/${os}/${codename} ${codename} main > $file.tmp"
        sudo mv -f $file.tmp $file
	sudo apt-get install -y apt-transport-https
        sudo apt-get update -qq
    fi

    # old packages from wheezy/trusty
    legacy=$sources_list_d/bbbike-legacy.list
    if [ ! -e $legacy ]; then
	codename_old=""
	case $os in
	  debian ) codename_old="wheezy" ;;
	  ubuntu ) codename_old="trusty" ;;
        esac

	sudo cp world/etc/apt/$os/${codename_old}-legacy/sources.list.d/$(basename $legacy) $legacy
        sudo apt-get update -qq
    fi
}

init_apt_mono() {
    mono_list=mono-xamarin.list
    mono_deb_url=https://download.mono-project.com/repo

    file="$sources_list_d/$mono_list"
    os=debian
    codename=jessie

    if [ ! -e $file ]; then 
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

        sudo sh -c "echo deb $mono_deb_url/${os} ${codename} main > $file.tmp"
        sudo mv -f $file.tmp $file
        sudo apt-get update -qq
    fi
}

# required packages for this script
init_apt_deb() {
    sudo apt-get install -qq -y lsb-release wget curl gnupg dirmngr
}

init_apt_deb
init_apt_bbbike
init_apt_mono

