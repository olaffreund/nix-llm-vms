{
  config,
  pkgs,
  ...
}: {
  # Enable Ollama service
  services.ollama = {
    enable = true;
    # Use CUDA acceleration for NVIDIA GPUs
    acceleration = "cuda";
    # Set to listen on all interfaces (so it's accessible from host)
    host = "0.0.0.0";
    port = 11434;
  };

  # Set Ollama models directory via environment variable
  systemd.services.ollama = {
    environment = {
      OLLAMA_MODELS = "/var/lib/ollama/models";
    };
  };

  # Open firewall port for Ollama
  networking.firewall.allowedTCPPorts = [11434];

  # Install nvidia drivers if needed
  hardware.graphics = {
    enable = true; # Updated from hardware.opengl.enable
    enable32Bit = true; # Updated from hardware.opengl.driSupport32Bit
  };

  # Configure NVIDIA drivers properly
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;

    # Uncomment this for datacenter GPUs
    # datacenter.enable = true;

    # Add this setting for headless environments without X
    open = false;
  };

  # Add NVIDIA to video drivers (required by nvidia-container-toolkit)
  services.xserver.videoDrivers = ["nvidia"];

  # Additional system packages for Ollama
  environment.systemPackages = with pkgs; [
    ollama
    btop
    iotop
    lm_sensors
  ];

  # Add persistent storage for Ollama models
  fileSystems."/var/lib/ollama" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["size=10G" "mode=777"];
  };

  # Enable Docker for container-based workflows (optional)
  virtualisation.docker = {
    enable = true;
  };

  # Enable NVIDIA Container Toolkit with proper configuration
  hardware.nvidia-container-toolkit = {
    enable = true;
    # Enable this since we're in a headless VM environment
    suppressNvidiaDriverAssertion = true;
  };

  # Add user to docker group
  users.users.admin.extraGroups = ["docker"];
}
