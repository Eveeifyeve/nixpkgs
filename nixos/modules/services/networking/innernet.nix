{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.tailscale;
  isNetworkd = config.networking.useNetworkd;
in
{
  meta.maintainers = with maintainers; [
    eveeifyeve
  ];

  options.services.innernet = {
    enable = mkEnableOption "Tailscale client daemon";

    port = mkOption {
      type = types.port;
      default = 41641;
      description = "The port to listen on for tunnel traffic (0=autoselect).";
    };

    package = lib.mkPackageOption pkgs "innernet" { };

    openFirewall = mkOption {
      default = false;
      type = types.bool;
      description = "Whether to open the firewall for the specified port.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ]; # for the CLI
    systemd.packages = [ cfg.package ];
    systemd.services.tailscaled-autoconnect = mkIf (cfg.authKeyFile != null) {
      after = [ "network-online.target nss-lookup.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "notify";
      };
      path = [
        cfg.package
        pkgs.jq
      ];
      enableStrictShellChecks = true;
      script = "innernet-server serve";
    };

    networking.firewall.allowedUDPPorts = mkIf cfg.openFirewall [ cfg.port ];

  };
}
