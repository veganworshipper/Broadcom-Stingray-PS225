# PS225 Memory Population Analysis

## Card 03 - PS225-H08 Rev E

Card 03 was inspected with the heatsink/shroud removed.

Observed DRAM package count:

| Side | Count |
|---|---:|
| Front | 6 |
| Rear | 4 |
| Total | 10 |

Rear DRAM marking:

```text
Micron
7VB75
D9TBK
```

Identified Micron FBGA code:

```text
D9TBK
```

Likely part number:

```text
MT40A512M16JY-083E:BFBGA
```

## Device Characteristics

| Field | Value |
|---|---|
| Manufacturer | Micron |
| Type | DDR4 SDRAM |
| Density | 8Gb |
| Organization | 512M x 16 |
| Approx. Raw Capacity | 1GB per package |

## Capacity Calculation

If all 10 devices are identical:

```text
10 x 8Gb = 80Gb raw
```

Broadcom diagrams for PS225/BCM5880X show two DDR4 channels and 72-bit paths, implying ECC-style memory organization.

Likely practical mapping:

```text
64Gb usable data + 16Gb ECC = 8GB usable ECC DDR4
```

This aligns with the PS225-H08 designation for assembly `BCM958802A8028E`.

## Verification Required

Memory size remains to be verified at runtime.

Recommended commands after successful boot:

```bash
free -h
cat /proc/meminfo
dmesg | grep -i memory
```

If accessible from bootloader, capture memory initialization logs as well.
