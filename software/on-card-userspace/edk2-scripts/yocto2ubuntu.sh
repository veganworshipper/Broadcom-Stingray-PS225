# Allows user to switch from Yocto to Ubuntu in partition /dev/mmcblk0p5 (default).
# User can also edit script to load Ubuntu in a different partition.

# Variables indicating Ubuntu partition
ALT_OS_PARTITION=/dev/mmcblk0p5
EFIVAR="bcm_rootfs_ordinal 5"

# Verify if user is certain of running script
echo "WARNING: This script will erase and reformat ${ALT_OS_PARTITION} before switching from Yocto to Ubuntu.
To use a different partition, please stop the script and edit the variables \"ALT_OS_PARTITION\" and \"EFIVAR\".
Type y or Y to proceed anyway."
read userinput
if [ "${userinput^}" != "Y" ]; then
  echo "Won't proceed with the script. Exiting."
  exit
fi

ALT_OS_MOUNT_POINT=/mnt/ubuntu
ALT_OS_TARBALL_URL=http://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-arm64-root.tar.xz
ALT_OS_TARBALL=$(basename $ALT_OS_TARBALL_URL)
ALT_OS_SERVER=$(echo $ALT_OS_TARBALL_URL | awk -F[/:] '{print $4}')

CHROOT_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CHROOT_SCRIPT=${CHROOT_SCRIPT_DIR}/ubuntu-chroot.sh

# Check for network connectivity before proceeding
echo -e "\n--> Checking connectivity to $ALT_OS_SERVER. Please wait.\n"
ping -c 1 -q -4 $ALT_OS_SERVER
if [ "$?" -ne "0" ]; then
  echo "No connectivity to $ALT_OS_SERVER in order to get rootfs image."
  echo "Please make sure $ALT_OS_SERVER can be reached."
  echo -e "Exiting\n"
  exit
fi
echo -e "\n--> Connectivity to $ALT_OS_SERVER OK.\n"

# Format the partition
echo -e "\n--> Formatting the partition ${ALT_OS_PARTITION}. Please wait.\n"
mkfs.ext4 ${ALT_OS_PARTITION}
echo -e "\n--- Done with formatting the partition ${ALT_OS_PARTITION}."

# Mount the partition
echo -e "\n--> Mounting the partition ${ALT_OS_PARTITION} to ${ALT_OS_MOUNT_POINT}\n"
mkdir -p ${ALT_OS_MOUNT_POINT}
mount ${ALT_OS_PARTITION} ${ALT_OS_MOUNT_POINT}
cd ${ALT_OS_MOUNT_POINT}
echo -e "\n--- Done with mounting the partition ${ALT_OS_PARTITION} to ${ALT_OS_MOUNT_POINT}"

# Download the Ubuntu image
echo -e "\n--> Downloading rootfs tarball from ${ALT_OS_TARBALL_URL}. Please wait.\n"
curl -O -k ${ALT_OS_TARBALL_URL}
echo -e "\n--- Done with downloading rootfs."
echo -e "\n--> Extracting rootfs tarball ${ALT_OS_TARBALL}. Please wait.\n"
tar --numeric-owner -xf ${ALT_OS_TARBALL}
rm -f ${ALT_OS_TARBALL}
echo -e "\n--- Done with extracting rootfs."

# Copy modules from Yocto to Ubuntu rootfs
echo -e "\n--> Copying pre-built modules for the current kernel\n"
cp -r /lib/modules/`uname -r` lib/modules
echo -e "\n--- Done with copying pre-built modules for the current kernel"

# Copy files needed to run update-me.sh
echo -e "\n--> Copying files needed for running update-me.sh script\n"
cp -r /usr/bin/update-me.sh usr/bin
cp -r /usr/share/edk2 usr/share
echo -e "\n--- Done with copying files needed for running update-me.sh script\n"

# Switch to Ubuntu file system
echo -e "\n--> Updating Ubuntu settings and user.\n"
cp ${CHROOT_SCRIPT} ${ALT_OS_MOUNT_POINT}/chroot.sh
chmod +x ${ALT_OS_MOUNT_POINT} chroot.sh
chroot ${ALT_OS_MOUNT_POINT} ./chroot.sh
echo -e "\n--- Done with updating Ubuntu settings and user."

cd
echo -e "\n--- Unmounting Ubuntu partition."
# Unmount device
umount ${ALT_OS_MOUNT_POINT}

# switch to ALT_OS_PARTITION without having to enter UEFI manually and reboot
cd /usr/share/edk2
source ./efivars.sh
set_efivar ${EFIVAR}

echo -e "\n--- Done with all actions. \n"
echo "Type y or Y to reboot into Ubuntu or any other key to continue with the current session"
read userinput
if [ "${userinput^}" = "Y" ]; then
  echo -e "\n--- Rebooting ...\n"
  reboot
else
  echo -e "\n--- Exiting... Next boot will be into Ubuntu partition \n"
fi