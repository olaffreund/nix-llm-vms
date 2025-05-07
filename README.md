# NixOS VM using QEMU

This repository contains a Nix flake for easily building and running a NixOS virtual machine using QEMU.

## Features

- Preconfigured NixOS VM with GNOME desktop environment
- 4GB RAM and 4 CPU cores allocation
- GTK display with virtio graphics
- Automatic login to the `nixos` user account
- Common development tools pre-installed

## Requirements

- NixOS or Nix with flakes enabled on a Linux system (x86_64 or aarch64)
- Sufficient system resources (at least 4GB RAM to allocate to the VM)

## Quick Start

1. Clone this repository
2. Enter the development shell:
   ```
   nix develop
   ```
3. Build the VM:
   ```
   nixos-rebuild build-vm --flake .#vm
   ```
4. Run the VM:
   ```
   ./result/bin/run-nixos-vm
   ```

## Development Shell

The development shell provides the following commands:
- `build-vm` - Build the VM
- `run-vm` - Run the VM

## VM Configuration

The VM is configured with:
- GNOME Desktop Environment
- NetworkManager for networking
- OpenSSH server enabled
- Initial user: `nixos` with password `nixos` (change on first login)
- QEMU guest agent and SPICE agent for better VM integration

## Customization

Edit the `configuration.nix` file to customize the VM configuration.
Edit the `flake.nix` file to modify VM hardware settings (RAM, CPU cores, display options).

## VFIO GPU Passthrough Configuration

This section explains how to configure GPU passthrough using VFIO-PCI in NixOS.

### Prerequisites

- CPU with virtualization extensions (Intel VT-d or AMD-Vi)
- IOMMU enabled in BIOS/UEFI
- A separate GPU for passthrough (not your primary display)
- Linux kernel 5.4 or newer

### Step 1: Find your GPU IDs

Identify your GPU's PCI address and vendor:device IDs:

```bash
lspci -nnk | grep -i vga
```

Example output:
```
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA104 [GeForce RTX 3070] [10de:2484] (rev a1)
```

Also find any associated audio controllers:
```bash
lspci -nnk | grep -i audio
```

Example output:
```
01:00.1 Audio device [0403]: NVIDIA Corporation GA104 High Definition Audio Controller [10de:228b] (rev a1)
```

Note down the PCI addresses (e.g., `01:00.0` and `01:00.1`) and the vendor:device IDs (e.g., `10de:2484` and `10de:228b`).

### Step 2: Configure VFIO in NixOS

Edit your `gpu-config.nix` file to enable VFIO passthrough:

```nix
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable VFIO kernel modules
  boot.kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
  boot.initrd.kernelModules = [ "vfio_pci" ];
  
  # Bind GPU to VFIO-PCI at boot
  boot.extraModprobeConfig = ''
    options vfio-pci ids=10de:2484,10de:228b disable_vga=1
  '';
  
  # Enable IOMMU
  boot.kernelParams = [
    # Use intel_iommu for Intel CPUs, amd_iommu for AMD
    "intel_iommu=on"
    # "amd_iommu=on"
    "iommu=pt"
  ];
  
  # Blacklist GPU drivers to prevent conflicts
  boot.blacklistedKernelModules = [ "nvidia" "nouveau" ];
  
  # VM configuration for GPU passthrough
  virtualisation.vmVariant = {
    virtualisation.qemu.options = [
      "-device vfio-pci,host=01:00.0,rombar=0"
      "-device vfio-pci,host=01:00.1,rombar=0"
    ];
  };
}
```

### Step 3: Configure Permission Settings

Ensure QEMU has access to VFIO devices by adding the following:

```nix
{
  # Set proper permissions for VFIO devices
  services.udev.extraRules = ''
    SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm", MODE="0660"
  '';
  
  # Ensure your user is part of the kvm group
  users.users.admin.extraGroups = [ "kvm" ];
}
```

### Step 4: Update flake.nix

Make sure your `flake.nix` file includes the GPU configuration:

```nix
nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./configuration.nix
    ./ollama/default.nix
    ./ollama/open-webui.nix
    ./ollama/gpu-config.nix  # GPU passthrough configuration
    // ...other modules...
  ];
};
```

### Step 5: Build and Run

Build the VM with GPU passthrough:

```bash
nixos-rebuild build-vm --flake .#vm
```

Run the VM:

```bash
./result/bin/run-nixos-vm
```

### Troubleshooting

#### Cannot Reset Device

If you see "Cannot reset device" errors, it means your GPU doesn't support FLR (Function Level Reset). Try these solutions:

1. Try removing the GPU from its PCIe slot and reinserting it
2. Add `pcie_acs_override=downstream,multifunction` to kernel parameters
3. For some GPUs, using vendor ROM files may help

#### Permission Denied

If you encounter "Permission denied" errors for VFIO devices:

1. Verify that VFIO devices have the correct permissions: `ls -la /dev/vfio/`
2. Ensure your user is in the `kvm` group: `groups`
3. Try running the VM with sudo once to initialize the VFIO devices

#### IOMMU Groups

If your GPU shares an IOMMU group with other devices, you'll need to pass through all devices in that group. Check IOMMU groups with:

```bash
find /sys/kernel/iommu_groups/ -type l | sort -n -k5 -t/ | xargs -L1 basename -a | xargs -I{} sh -c "echo IOMMU Group {}; ls -l /sys/kernel/iommu_groups/{}/devices/"
```

## Supported Systems

This flake supports the following systems:
- x86_64-linux
- aarch64-linux
