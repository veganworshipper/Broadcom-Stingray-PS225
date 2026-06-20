platform:
  model: BCM958802A8046

memory:
  size: 16384MB
  ecc: enabled
  speed: DDR4-2400

storage:
  boot_media: eMMC

cpu:
  architecture: ARM64
  cores: 8
  type: Cortex-A72

bootloader:
  version: BL2 v2.3
  build_date: 2021-06-21

kernel:
  version: 5.11.0-rc3
  source: https://github.com/Broadcom/arm64-linux

rootfs:
  active_slot: LinuxRoot.1
  alternate_slot: LinuxRoot.2
  recovery_slot: Present
