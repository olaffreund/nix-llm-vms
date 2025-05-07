{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  name = "nixos-vm-dev";

  buildInputs = with pkgs; [
    nixos-rebuild
    qemu
    libguestfs
    libguestfs-with-appliance
    cdrkit
    virt-manager
    direnv
    nix-direnv
  ];

  shellHook = ''
    alias build-vm="nixos-rebuild build-vm -I nixos-config=./configuration.nix --flake .#vm"
    alias run-vm="./result/bin/run-nixos-vm"

    echo "NixOS VM Development Environment"
    echo "Available commands:"
    echo "  build-vm    - Build the VM"
    echo "  run-vm      - Run the VM"
  '';
}
