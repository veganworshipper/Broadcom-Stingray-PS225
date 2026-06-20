#!/bin/bash

# tftp_update.sh is obsolete. Please use image_update.sh
# The command below still allows using tftp_update.sh as
# before (tftp_update.sh <serverip> <tftpdir> <image>),
# but it is just a wrapper to image_update.sh

/usr/share/edk2/image_update.sh -s $1 -d $2 -i $3 -t tftp
