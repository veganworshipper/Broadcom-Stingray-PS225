#!/bin/bash

# reg definions
CDRU_GENPLL2_CONTROL4=0x6641d1bc
CDRU_GENPLL2_CONTROL5=0x6641d1c0
CDRU_GENPLL2_CONTROL6=0x6641d1c4

# read control regs
function read_reg32()
{
	reg_name=$1

	devmem $reg_name 32
}

# 1. calculate VCO
regval=`read_reg32 $CDRU_GENPLL2_CONTROL5`
pdiv=$(($regval & 0xf))

data=`read_reg32 $CDRU_GENPLL2_CONTROL4`
vco=$(($(($data >> 20)) & 0x3ff))
vco=$((100 * $vco / $(($pdiv+1))))
echo "VCO       : $vco MHz"

# 2. get mdiv
regval=`read_reg32 $CDRU_GENPLL2_CONTROL6`
mdiv=$(($regval & 0x1ff))

# 3. get freq
freq=$(($vco / $mdiv))
echo "Nitro Freq: $freq MHz"

# end of file
