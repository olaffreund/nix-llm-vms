{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable kernel modules required for VFIO-PCI
  boot.kernelModules = ["vfio" "vfio_iommu_type1" "vfio_pci"];

  # Add kernel parameters for better IOMMU handling
  boot.kernelParams = [
    "vfio-pci.disable_vga=1"
    "pcie_acs_override=downstream,multifunction"
    # Enable these for your CPU type
    "intel_iommu=on" # For Intel processors
    # "amd_iommu=on"  # For AMD processors
  ];

  # VM specific configuration that integrates with the flake.nix setup
  virtualisation.vmVariant = {
    # Fix display handling by using curses or none for headless
    environment.variables = {
      QEMU_AUDIO_DRV = "none";
    };

    virtualisation.qemu.options = [
      # Use simple display option for headless operation
      "-nographic"

      # Pass through the NVIDIA GPU with options
      # Note: Using x-vga=on may not work on all QEMU versions, removed for compatibility
      "-device vfio-pci,host=0000:c1:00.0,rombar=0"

      # Pass through the audio controller with minimal options
      "-device vfio-pci,host=0000:c1:00.1,rombar=0"
    ];
  };
}
