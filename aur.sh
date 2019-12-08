#!/bin/sh
for arg in "$@"
do
	git clone https://aur.archlinux.org/$arg.git
	cd $arg/
	makepkg -s -f
	sudo pacman -U $(find -iname '*.pkg.tar.xz')
	cd ../
done

# Downloads and installs packages from AUR Arch repos
# Package name/location specified in first argument
