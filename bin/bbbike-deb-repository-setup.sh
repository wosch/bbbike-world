#!/bin/sh
# Copyright (c) 2016-2023 Wolfram Schneider, https://bbbike.org
#
# init bbbike.org ubuntu deb repository

: ${DEBUG=false}
: ${enable_mono="NO"}
enable_legacy="YES"

if $DEBUG; then
  set -x
fi
set -e

sources_list_d=/etc/apt/sources.list.d

init_apt_bbbike() {
    bbbike_list=bbbike.list
    apt_key=https://raw.githubusercontent.com/wosch/bbbike-world/world/etc/apt/debian/bullseye/gpg/bbbike.asc
    deb_url=https://debian.bbbike.org

    file="$sources_list_d/$bbbike_list"
    os=$(lsb_release -i | perl -npe 's,^Distributor ID:\s+,,; $_=lc($_)')
    codename=$(lsb_release -cs)

    #
    # install all given *.list files which are not
    # already installed in /etc/apt/sources.list.d
    #
    list_d="world/etc/apt/$os/$codename/sources.list.d"
    flag=0

    if [ -d $list_d ]; then
      for file in $list_d/*.list
      do
        # should never happens
        if [ ! -e "$file" ]; then
          echo "file '$file' does not exist, give up. Wrong cwd?"
          exit 2
        fi

        f=$sources_list_d/$(basename $file)
        if [ ! -e $f ]; then
          sudo cp $file $f
        fi
        flag=1
      done
    fi

    if [ $enable_legacy = "YES" ]; then
      file="world/etc/apt/ubuntu/trusty-legacy/sources.list.d/bbbike-legacy.list"
      f=$sources_list_d/$(basename $file)
      if [ ! -e $f ]; then
        sudo cp $file $f
      fi
      flag=1
    fi

    if [ $flag = "1" ]; then
        curl -sSf $apt_key | sudo apt-key add -
	sudo apt-get install -y apt-transport-https
        sudo apt-get update -qq
    fi
}

init_apt_mono() {
    mono_list=mono-xamarin.list
    mono_deb_url=https://download.mono-project.com/repo

    file="$sources_list_d/$mono_list"
    os=debian
    codename=buster

    if [ ! -e $file ]; then
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

        sudo sh -c "echo \"deb [arch=amd64] $mono_deb_url/${os} ${codename} main\" > $file.tmp"
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

if [ $enable_mono = "YES" ]; then
  init_apt_mono
fi

#EOF
