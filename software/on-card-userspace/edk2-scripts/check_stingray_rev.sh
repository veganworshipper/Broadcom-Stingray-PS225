#!/bin/bash

#
# Check paxc root complex Pci Id from lspci.
# For Bx it should be d750.
# For Ax it is different and the same as pf0 (16f0, d802, etc.).
#
lspci | grep "d750" >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "Stingray Bx"
else
  echo "Stingray Ax"
fi

# end of file
