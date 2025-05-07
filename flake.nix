{
  description = "NixOS VM using QEMU with GPU passthrough";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux"];
  in
    flake-utils.lib.eachSystem supportedSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            nixos-rebuild
            qemu
            libguestfs
            libguestfs-with-appliance
            cdrkit
            virt-manager
          ];

          shellHook = ''
            echo "NixOS VM development shell"
            echo "Commands:"
            echo "  build-vm    - Build the VM"
            echo "  run-vm      - Run the VM"
          '';
        };
      }
    )
    // {
      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./ollama/default.nix
          ./ollama/open-webui.nix
          ./ollama/gpu-config.nix
          ({
            pkgs,
            lib,
            ...
          }: {
            # VM specific configuration - only basic settings here
            # The GPU passthrough options are now in gpu-config.nix
            virtualisation = {
              vmVariant = {
                # Add the admin user to kvm group to ensure access to vfio devices
                users.users.admin.extraGroups = ["kvm"];

                # Set proper VM memory and cores
                virtualisation = {
                  memorySize = 8192; # MB - increased for LLM usage
                  cores = 4;
                };

                # Ensure QEMU has proper access to vfio devices
                boot.postBootCommands = ''
                  # Fix permissions for VFIO devices if needed
                  if [ -d /dev/vfio ]; then
                    chmod 755 /dev/vfio
                    chmod 660 /dev/vfio/*
                    chown root:kvm /dev/vfio/*
                  fi
                '';
              };
            };

            # Binary cache configuration to speed up builds
            nix = {
              settings = {
                substituters = [
                  "https://cache.nixos.org/"
                  "https://cuda-maintainers.cachix.org"
                ];
                trusted-public-keys = [
                  "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
                  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                ];
                extra-substituters = [
                  # Nix community's cache server
                  "https://nix-community.cachix.org"
                ];
                extra-trusted-public-keys = [
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                ];
              };
            };
          })
        ];
      };
    };
}
