moduleConfig:
{ config, lib, pkgs, ... }:

{
  options.services.vscode-server = let
    inherit (lib) mkEnableOption mkOption;
    inherit (lib.types) listOf nullOr package str;
  in {
    enable = mkEnableOption "VS Code Server";

    enableFHS = mkEnableOption "a FHS compatible environment";

    nodejsPackage = mkOption {
      type = nullOr package;
      default = null;
      example = pkgs.nodejs-16_x;
      description = ''
        Whether to use a specific Node.js rather than the version supplied by VS Code server.
      '';
    };

    extraRuntimeDependencies = mkOption {
      type = listOf package;
      default = [ ];
      description = ''
        A list of extra packages to use as runtime dependencies.
        It is used to determine the RPATH to automatically patch ELF binaries with,
        or when a FHS compatible environment has been enabled,
        to determine its extra target packages.
      '';
    };

    installPath = mkOption {
      type = str;
      default = "~/.vscode-server";
      example = "~/.vscode-server-oss";
      description = ''
        The install path.
      '';
    };
  };

  config = let
    inherit (lib) mkDefault mkIf mkMerge;
    cfg = config.services.vscode-server;
  in mkIf cfg.enable (mkMerge [
    {
      services.vscode-server.nodejsPackage = mkIf cfg.enableFHS (mkDefault pkgs.nodejs-16_x);
    }
    (moduleConfig {
      name = "auto-fix-vscode-server";
      description = "Automatically fix the VS Code server used by the remote SSH extension";
      restartIfChanged = true;
      serviceConfig = {
        # When a monitored directory is deleted, it will stop being monitored.
        # Even if it is later recreated it will not restart monitoring it.
        # Unfortunately the monitor does not kill itself when it stops monitoring,
        # so rather than creating our own restart mechanism, we leverage systemd to do this for us.
        Restart = "always";
        RestartSec = 0;
        ExecStart = "${pkgs.callPackage ../../pkgs/auto-fix-vscode-server.nix (removeAttrs cfg [ "enable" ])}/bin/auto-fix-vscode-server";
      };
    })
  ]);
}
