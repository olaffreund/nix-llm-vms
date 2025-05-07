{
  config,
  pkgs,
  lib,
  ...
}: {
  # Define Open WebUI service
  systemd.services.open-webui = {
    description = "Open WebUI for Ollama";
    wantedBy = ["multi-user.target"];
    after = ["network.target" "ollama.service"];
    serviceConfig = {
      ExecStart = "${pkgs.docker}/bin/docker run -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://host.docker.internal:11434 -e HOST=0.0.0.0 -e PORT=8080 --name open-webui --restart=always ghcr.io/open-webui/open-webui:main";
      ExecStop = "${pkgs.docker}/bin/docker stop open-webui";
      ExecStopPost = "${pkgs.docker}/bin/docker rm open-webui";
      Restart = "always";
      User = "root";
    };
  };

  # Open firewall port for Open WebUI
  networking.firewall.allowedTCPPorts = [3000];

  # Create a desktop entry for Open WebUI
  environment.systemPackages = with pkgs; [
    (writeTextDir "share/applications/open-webui.desktop" ''
      [Desktop Entry]
      Type=Application
      Name=Open WebUI
      Exec=${pkgs.firefox}/bin/firefox http://localhost:3000
      Icon=firefox
      Terminal=false
      Categories=Development;
    '')
  ];
}
