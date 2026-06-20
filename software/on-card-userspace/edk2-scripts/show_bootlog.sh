#!/bin/bash

log_mem_addr="0x8f110000"
log_size_bytes=8192

if [ "$1" != "" ]; then
	log_mem_addr="$1"
fi

if [ "$2" != "" ]; then
	log_size_bytes=$2
fi

for ((n = 0; n < log_size_bytes; n++)); do
	printf "\x$(printf %x $(devmem $((n + $log_mem_addr)) 8))"
done

echo -e "\n"
