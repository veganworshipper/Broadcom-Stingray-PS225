#!/bin/bash

MCU_INTR_CLEAR=0x66424048

crmu_event_reg=("RESET_EVENT_LOG" 0x66424064
                "POWER_EVENT_LOG" 0x66424068
                "ERROR_EVENT_LOG" 0x6642406c)

sw_persist_reg=("SW_PERSISTENT_REG0" 0x66424c54
                "SW_PERSISTENT_REG1" 0x66424c58
                "SW_PERSISTENT_REG2" 0x66424c5c
                "SW_PERSISTENT_REG3" 0x66424c60
                "SW_PERSISTENT_REG4" 0x66424c64
                "SW_PERSISTENT_REG5" 0x66424c68
                "SW_PERSISTENT_REG6" 0x66424c6c
                "SW_PERSISTENT_REG7" 0x66424c70
                "SW_PERSISTENT_REG8" 0x66424c74
                "SW_PERSISTENT_REG9" 0x66424c88
                "SW_PERSISTENT_REG10" 0x66424c8c
                "SW_PERSISTENT_REG11" 0x66424c94)

function record_reg_log()
{
  reg_name=$1
  reg_addr=$2
  log_file=$3

  echo "$reg_name: `devmem $reg_addr 32`" >> $log_file
}

function write_reg32()
{
  reg_addr=$1
  reg_val=$2

  devmem $reg_addr 32 $reg_val
}

# check whether if file exists
CLEAR_LOG="/usr/share/edk2/log_crmu_regs.log"
if [ ! -f $CLEAR_LOG ]; then
  touch $CLEAR_LOG
fi

# limit LOG size to 128KB
# only backup once
LOGSIZE=$(stat -c%s "$CLEAR_LOG")
LOGLIMIT=$((128*1024))
if [ $LOGSIZE -gt $LOGLIMIT ]; then
  gzip -f $CLEAR_LOG
  touch $CLEAR_LOG
fi

# dump crmu event regs
echo "[`date +"%Y-%m-%d %H:%M:%S"`]" >> $CLEAR_LOG
for ((i=0; i<${#crmu_event_reg[@]}; i+=2)); do
  record_reg_log ${crmu_event_reg[$i]} ${crmu_event_reg[$(($i+1))]} $CLEAR_LOG
done

# Clear events after read
write_reg32 $MCU_INTR_CLEAR 0x00000e00

# dump crmu persistent registers
for ((i=0; i<${#sw_persist_reg[@]}; i+=2)); do
  record_reg_log ${sw_persist_reg[$i]} ${sw_persist_reg[$(($i+1))]} $CLEAR_LOG
done

# Clear persistent regs after read
for ((i=0; i<${#sw_persist_reg[@]}; i+=2)); do
  write_reg32 ${sw_persist_reg[$(($i+1))]} 0
done

# end of file
