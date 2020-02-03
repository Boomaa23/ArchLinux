#!/bin/bash
# pacrein - Re-install all Official and Local packages

# Local package cache
locpkgcache=/var/cache/pacman-local/pkg

# Use filename as program name
prog=${0##*/}

# Text color variables
if [ $(whoami) != "cron" ]; then
txtund=$(tput sgr 0 1)          # Underline
txtcyn=$(tput setaf 6)          # Cyan
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldblu=${txtbld}$(tput setaf 4) #  blue
bldwht=${txtbld}$(tput setaf 7) #  white
txtrst=$(tput sgr0)             # Reset
info=${bldwht}*${txtrst}        # Feedback
pass=${bldblu}*${txtrst}
warn=${bldred}!${txtrst}
fi

# If rebuilding, be sure yaourt is installed
if [[ "$1" == 'r' ]] && [[ -z $(pacman -Qs yaourt) ]]; then
    echo
    echo "$warn $prog requires ${txtund}}Yaourt${txtrst} to be installed."
    echo "  ${txtcyn}http://wiki.archlinux.org/index.php/Yaourt${txtrst}"
    echo
    exit
fi

# Sync db, download only
echo -n "Upgrade database, and download new packages? (${txtbld}y${txtrst}/${txtbld}n${txtrst}): "
read updbdown

if [ $updbdown = "y" ]; then
  sudo pacman -Sy
  sudo pacman --noconfirm -Swu
fi

# Reinstall Official dependencies?
echo -n "Re-install Official dependencies? (${txtbld}y${txtrst}/${txtbld}n${txtrst}): "
read offdep

if [ $offdep = "y" ]; then
  sudo pacman -S --asdeps $(pacman -Qq | grep -vx "$(pacman -Qqe)" | grep -vx "$(pacman -Qqm)")
fi

# Re-install Official explictis?
echo -n "Re-install Official explicits? (${txtbld}y${txtrst}/${txtbld}n${txtrst}): "
read offexp

if [ $offexp = "y" ]; then
  sudo pacman -S $(pacman -Qqe | grep -vx "$(pacman -Qqm)")
fi

# Re-install Local depedencies
  echo -n "Re-install Local dependencies? (${txtbld}y${txtrst}/${txtbld}n${txtrst}): "
read locdep

if [ $locdep = "y" ]; then
  # Re-install package if cached, build others
  locdepls=$(pacman -Qqm | grep -vx "$(pacman -Qqme)")

  for pkg in $locdepls; do
    pkgver="$locpkgcache/$pkg-$(pacman -Qii $pkg | grep Version | awk '{ printf $3 }')-$(uname -m).pkg.tar.gz"
    if [ -f $pkgver ]; then
      sudo pacman -U --asdeps --noconfirm $pkgver
    else
      yaourt -S --asdeps --noconfirm $pkg
    fi
  done
fi

# Re-install Local explicits
  echo -n "Re-install Local explicits? (${txtbld}y${txtrst}/${txtbld}n${txtrst}): "
read locexp

if [ $locexp = "y" ]; then
  # Re-install package if cached, build others
  locexpls=$(pacman -Qqme)

  for pkg in $locexpls; do
    pkgver="$locpkgcache/$pkg-$(pacman -Qii $pkg | grep Version | awk '{ printf $3 }')-$(uname -m).pkg.tar.gz"
    if [ -f $pkgver ]; then
      sudo pacman -U --asexplicit --noconfirm $pkgver
    else
      yaourt -S --noconfirm $pkg
    fi
  done
fi
