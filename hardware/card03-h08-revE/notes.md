# Card 03 - Broadcom Stingray PS225-H08 Rev E

## Identification

| Field | Value |
|---|---|
| Card ID | Card 03 |
| Assembly Number | BCM958802A8028E |
| Model | PS225-H08 |
| Revision | E |
| SoC | BCM58802H |
| Expected Usable DDR4 | 8GB |
| Status | Untested |
| UART Console | Present, 3.5mm TRRS on bracket |
| SFP28 Ports | Dual |
| Fan Assembly | Present |

## Observed Labels / Markings

- Bottom-left rear board sticker: `BCM958802A8028E`
- Front sticker near PCIe edge: `BCM58802H A1KF8FG0G`
- Inventory sticker: `BCEM0001519`

## Internal Inspection

The heatsink/shroud was removed for documentation.

Observed:

- Broadcom Stingray SoC package exposed at center of card.
- DRAM population visible around the SoC.
- Fan connector and 10-pin debug/manufacturing header visible near rear edge.
- Dual SFP28 cages and 3.5mm UART console jack present at bracket.

## Memory Population

Observed DRAM package count:

| Side | Count |
|---|---:|
| Front | 6 |
| Rear | 4 |
| Total | 10 |

Rear DRAM marking observed:

```text
Micron
7VB75
D9TBK
```

Identified Micron FBGA code:

```text
D9TBK
```

Likely corresponding Micron part:

```text
MT40A512M16JY-083E:BFBGA
```

Known/identified specifications:

| Field | Value |
|---|---|
| Manufacturer | Micron |
| Type | DDR4 SDRAM |
| Density | 8Gb per package |
| Organization | 512M x 16 |
| Speed Grade | 083E |
| Approx. Capacity Per Package | 1GB raw |

### Memory Analysis

If all 10 DRAM packages are the same Micron D9TBK / MT40A512M16JY-083E device:

```text
10 x 8Gb = 80Gb raw physical DRAM
```

Given the Broadcom block diagram shows two DDR4 channels with ECC-style 72-bit paths, this likely maps to:

```text
64Gb usable data + 16Gb ECC = 8GB usable ECC DDR4
```

This matches the PS225-H08 class designation.

Runtime verification still required using serial console / Linux:

```bash
free -h
cat /proc/meminfo
```

## Headers / Connectors

### UART Console

- 3.5mm TRRS jack on bracket.
- Official Broadcom USB-to-TRRS serial cable available.

### J4001

- Visible near rear/fan side.
- Appears to be 2x5, 10-pin.
- Function currently unknown.

Possible functions:

- JTAG
- Manufacturing/debug interface
- Recovery interface
- NC-SI or board management debug

Further probing required.

## Photos

| File | Description |
|---|---|
| `front.jpg` | Front side with heatsink/shroud installed |
| `rear.jpg` | Rear side overview |
| `bottom-left-id-sticker.jpg` | Small assembly ID sticker showing BCM958802A8028E |
| `heatsink-removed.jpg` | Front side with shroud/heatsink removed |
| `rear-dram-micron-d9tbk-closeup.jpg` | Rear Micron DDR4 D9TBK close-up |

## Bring-Up Notes

Do not flash firmware before capturing original state.

Recommended first steps:

1. Capture UART boot log.
2. Capture `lspci -nnvv` from host.
3. Confirm memory size from Linux/bootloader output.
4. Dump eMMC/SPI only after establishing stable console access.
