# Installing Arch, Ubuntu, and Windows 10
The goal of this is to install all three OSes on the same hard drive. They will ideally share a swap and boot loader such that the Arch GRUB will be able to boot to all three, though Arch will be the default (as intended).

## Ordering
Windows 10 must be installed first, as the Windows Boot Loader can only be installed with a full installation of the operating system (to my knowledge), and generally likes to override EFI partitions for some reason. Ubuntu will be installed next, as it actually has an installer and can be set up with a bit more rigidity than Arch. Arch is last, as it must all be manually set up. Each medium will first be a Live CD (USB) and then installed from the Live CD (USB).

## Disk Partitions
In my instance, I had one 120 GB drive. I wanted to split it about 35 GB for Windows, 40GB for Ubuntu, and 45 GB for Arch. Of course, some had to be taken out for (U)EFI and swap, but that was generally fine. Here's what my partition tree looked like:
```
sda
|--sda1   100M    EFI System            ---|
|--sda2   128M    Microsoft reserved    ---|---- Windows
|--sda3   34.2G   Microsoft basic data  ---|
|--sda4   37.3G   Linux filesystem      -------- Ubuntu
|--sda5   512M    EFI System            ---|
|--sda6   4G      Linux swap            ---|---- Arch
|--sda7   43.1G   Linux filesystem      ---|
```

## Arch Package List
Setup/General: `man nano vim vi sudo grub os-prober efibootmgr dosfstools binutils git`

Networking: `dhcpcd net-tools iproute2 iputils wpa_supplicant`

Display: `i3 dmenu feh xorg-server xorg-xinit xterm ttf-dejavu`

Other: `intellij-idea-community-edition lynx cowsay neofetch wget`

## i3 Shortcuts
Assume all shortcuts include Alt (default modifier). U/D/L/R are moves with the shift key, and focus changes without.
```
Shift + E       Exit (exits back to shell)
Shift + R       Reload in place (reloads styling w/o restart)
Shift + Q       Quit current application (usually Ctrl + W)
Enter           xterm window (terminal [emulator])
D               Open dmenu (start typing to open files)
R               Resize windows (drag window bar, toggle disable)
F               Fullscreen (on currently focused window)
(Shift) J       (Move) left
(Shift) K       (Move) down
(Shift) L       (Move) up
(Shift) ;       (Move) right
```

## Downloading ISOs
### Windows 10
Microsoft offers the ISO for all versions of Windows 10 with their Media Creation Tool, but it can be obtained by tricking the browser into thinking you aren't a Windows-based computing device, even without a product key.
1. Go to https://www.microsoft.com/en-us/software-download/windows10
2. Press `F12` and click on the three dots at the top right (of the inspect element console)
3. Go to "More Tools" -> "Network Conditions"
4. Under "User Agent" deselect "Select automatically" and select any "Android" or "Blackberry" entry under "Custom"
5. Reload the page but don't close the `F12` menu
6. Select "Windows 10" and "English" then "64-Bit Download"
7. Go to https://rufus.ie/ and download the latest version of rufus

### Linux
* Download link to Ubuntu ISO: https://ubuntu.com/download/desktop (get an LTS release)
* Download link for Arch ISO: https://www.archlinux.org/download/ (use a US mirror)

## Burning ISOs to USB Drives
1. Plug in USB drive that can be entirely erased
2. Open the Rufus executable
3. Select the ISO you downloaded using the "Select" button
4. Ensure that your settings match:
	* Partition Scheme: `GPT`
    * Target System: `UEFI (non CSM)`
    * File System: (Windows) `NTFS` / (Linux) `FAT32 (Default)`
    * Cluster Size: (Windows) `4096 bytes (Default)` / (Linux) `8192 bytes (Default)`
5. Press the OK button and burn the ISO to the flash drive, repeat for each ISO image onto a *separate* USB drive.

## OS Installation
### Windows 10
1. Boot to the USB. Make sure legacy boot is disabled - UEFI only.
2. Follow the installer until the Partition page. Make a new partition of the minimum size (35 GB), and allow the installer to make two more partitions in front of that for the boot loader, etc.
3. Make the username your name but the PC name should be Windows-X220
3. Let Windows install. This may take some time.
4. Get windows update configured. Expand partition as necessary. WARNING: You will not be able to extend this partition after making the next one.

### Ubuntu
1. Unplug the previous USB and plug in the Ubuntu one. Boot to it again in UEFI mode.
2. Follow the installation again. Select a minimal installation and choose "Something else" for the installation options.
3. On the partitions page, press the "+" and make a new partition of 40000 MB. Select "Ext4 journaling file system" for "Use as" and enter "/" as the mount point.
4. The username should be your name, and the PC name should be Ubuntu-X220
5. Enter into Ubuntu and run `sudo apt update` and `sudo apt upgrade`
6. Expand partition as necessary, same warning as with windows.

### Arch
#### Base OS Setup
1. Boot to the third USB drive. Select the first option to boot off. Make sure the ethernet is connected; no wifi yet.
2. Verify that you are in UEFI mode. This should return something. If not, you're not running UEFI.
	* `ls /sys/firmware/efi/efivars`
3. Ensure clock accuracy:
	* `timedatectl set-ntp true`
4. Run `cfdisk` to partition the drive. By this point, `sda1` to `sda4` should exist, leaving a "Free space" at the bottom. Partition the free space into 3 partitions:
```
Name:           Size:     Location:     Size Type:
Boot Loader     512M      /dev/sda5     EFI System
Swapfile        4G        /dev/sda6     Linux swap
Filesystem      43.1G     /dev/sda7     Linux filesystem
```
Locations may not be the same as these, but will be used throughout the rest of this as above. All partitions will start as "Linux filesystem", so to change it select the partition you want and Select "Type", under which those options will become selectable. Note that the filesystem does not have to be 43.1G, rather just as much space remains. Swap should be one to two times your memory size.

5. Create an Ext4 file structure for the filesystem
	* `mkfs.ext4 /dev/sda7`
6. Create a FAT32 file structure for the EFI partition
	* `mkfs.fat -F 32 /dev/sda5`
7. Activate the swap partition
	* `mkswap /dev/sda6`
	* `swapon /dev/sda6`
8. Mount the partitions to the live media
	* `mount /dev/sda7 /mnt`
	* `mkdir /mnt/boot`
	* `mount /dev/sda5 /mnt/boot`
9. Install the Arch essential packages
	* `pacstrap /mnt base base-devel linux linux-firmware`
10. Generate an fstab file
	* `genfstab -U /mnt >> /mnt/etc/fstab`
11. Change root into the new system
	* `arch-chroot /mnt /bin/bash`
12. Set the time zone. "Region" and "City" may be replaced with region and city as an entry in the timezone list (accessible by running `timedatectl list-timezones`)
	* `ln -sf /usr/share/zoneinfo/Region/City /etc/localtime`
	* `hwclock --systohc`
13. Install the "general/setup" packages as above
	* `pacman -S <packages>`
14. Uncomment the `en_US.UTF-8 UTF-8` in `/etc/locale.gen`
	* `nano /etc/locale.gen`'`
	* `locale-gen`
15. Set a hostname (the entire contents of `/etc/hostname`)
	* `nano /etc/hostname`
16. Add loopback lines to hosts file

```
127.0.0.1	localhost
::1		localhost
127.0.1.1	myhostname.localdomain	myhostname
```
17. Enable dhcpcd so DHCP is enabled on all network interfaces
	* `systemctl enable dhcpcd`

#### GRUB Installation
1. Install GRUB onto the storage device
	* `grub-install /dev/sda`
2. Mount the Windows Boot Loader and Ubuntu to the already mounted system so that GRUB will recognize the EFI loaders on both partitions
	* `mount /dev/sda1 /mnt`
	* `mkdir /mnt2`
	* `mount /dev/sda4 /mnt2`
3. Copy in/install a copy of the linux kernel to `/boot`
	* `cd /boot`
	* `pacman -U /var/cache/pacman/pkg/linux-5.3.13.1-1-x86_64.pkg.tar.xz`
4. Configure GRUB to recognize all the boot loaders on the hard drive. This means that the Arch GRUB should take priority at bootup as it will have options for all three OSes.
	* `grub-mkconfig -o /boot/grub/grub.cfg`
5. Unmount all the mounted partitions, and `exit` out of the chroot, then `reboot`

#### User Setup
1. Boot into arch and login as "root" (no password)
2. Update the packages
	* `pacman -Syu`
3. Configure the package manager to allow 32-bit package installs. Uncomment the line that is `[multilib]` and the line below it.
	* `nano /etc/pacman.conf`
4. Update the package repositories
	* `pacman -Syy`
5. Add your main user account and set the password
	* `useradd -m -g users -G wheel,storage,power -s /bin/bash <username>`
	* `passwd <username>`
6. Allow the user to run commands as sudo by uncommenting `%wheel ALL=(ALL) ALL`
	* `nano /etc/sudoers`
7. Login as the new user. Some packages may need to be reinstalled.
	* `exit`
	* Login as: `<username>`
	* Password: `<password>`
Start using this account and `sudo` instead of the root.


#### Network Configuration
[For my purposes, `systemd-networkd` works just fine, but `NetworkManager` is available for anyone wanting a more built solution]
1. Grab the "neworking" packages as listed above
	* `pacman -S <packages>`
2. Enable and start dhcpcd again for all interfaces
	* `sudo systemctl enable dhcpcd`
	* `sudo systemctl start dhcpcd`
3. Enable and start the wpa_supplicant for all interfaces and `wlp3s0` specifically
	* `sudo systemctl enable wpa_supplicant`
	* `sudo systemctl enable wpa_supplicant@wlp3s0`
	* `sudo systemctl start wpa_supplicant`
	* `sudo systemctl start wpa_supplicant@wlp3s0`
4. Create a configuration file to store network configurations. I suggest using a link and making one centralized one if DHCP is all that is needed.
	* `sudo nano /etc/wpa_supplicant/wpa_supplicant.conf`
  
	Insert the top three lines as is, then modify the "network" portion according to your network. Duplicate "network" entries for more possible wifi networks.
	```
	ctrl_interfaces=/run/wpa_supplicant
	ctrl_interface_group=wheel
	update_config=1

	network={
		ssid="<name>"
		psk="<password>"
	}
	```
	
	Create a symlink to this initial file for the interface to specifically use:

	* `sudo ln -s /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf`
5. Enable and start `systemd-networkd` to manage network connectivity
	* `sudo systemctl enable systemd-networkd`
	* `sudo systemctl start systemd-networkd`
6. If required, the wireless network can be started manually
	* `sudo wpa_supplicant -B -D nl80211 -i wlp3s0 -c /etc/wpa_supplicant/wpa_supplicant.conf`
  
#### Display Environment Setup
1. Install all the "display" packages as listed above
	* `sudo pacman -S <packages>`
2. Create a display init file to run i3
	* `echo "exec i3" | ~/.xinitrc`
3. Create an xterm config file and fix the awful default color scheme
	* `nano ~/.Xresources`
	``` 
	xterm*background: black
	xterm*foreground: lightgray
	```
4. Launch i3 with `startx`
5. Allow i3 to create a config file, and use Alt as default modifier
6. Open xterm (Alt + Enter) and set a new background wallpaper
	* `wget https://getwall.net/wp-content/uploads/2019/04/Arch-hero-wallpaper-free.png`
	* `feh --bg-scale Arch-hero-wallpaper-free.png`
7. Fix the color scheme for real this time
	* `nano ~/.config/i3/config`
	* Add this line somewhere: `exec_always xrdb -merge ~/.Xresources`
  
## Resources
* Official Arch installation guide: https://wiki.archlinux.org/index.php/installation_guide
* Step-by-Step guide (some errors): https://www.ostechnix.com/install-arch-linux-latest-version/
