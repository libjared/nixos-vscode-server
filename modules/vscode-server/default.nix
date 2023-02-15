import ./module.nix ({ name, description, serviceConfig, restartIfChanged }:

{
  systemd.user.services.${name} = {
    inherit description serviceConfig;
    wantedBy = [ "default.target" ];
  };
})
