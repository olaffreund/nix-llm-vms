{
  config,
  pkgs,
  lib,
  ...
}: {
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;
  networking.hostName = "llm-vm"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "UTC";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Configure console settings instead of X11
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Configure audio - basic ALSA setup for server environment
  services.pulseaudio.enable = false; # Updated from hardware.pulseaudio
  hardware.alsa.enable = true;

  # Define a user account with hashed password
  users.users.admin = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"]; # Enable 'sudo' for the user.
    hashedPassword = "$6$RefgWBbXRkffuCgn$n8byBy3lsG1DzufftJQtC/4ds6qUPRchOhuSp3PwUPxJjD5qbHrhj/cW9k3Oursx41Lefgb2cziSmGdjzZrQH0";
    packages = with pkgs; [
      git
      vim
      wget
      curl
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
  ];

  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # Enable QEMU guest agent
  services.qemuGuest.enable = true;

  # Enable guest additions for better VM experience
  virtualisation.vmware.guest.enable = lib.mkDefault false;
  virtualisation.virtualbox.guest.enable = lib.mkDefault false;

  # Handle VM variant configuration
  virtualisation.vmVariant = {
    # Basic VM-specific audio settings
    services.pulseaudio.enable = false; # Updated from hardware.pulseaudio
    hardware.alsa.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "23.11";
}
