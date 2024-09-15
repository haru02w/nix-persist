{ lib, config, ... }:
with lib;
let cfg = config.environment.nix-persist;
in {
  imports = [ ./common.nix ./essential.nix ];
  options.environment.nix-persist = mkOption {
    description = "nix-persist settings";
    default = { };
    type = types.submodule {
      options = {
        enable = mkEnableOption "nix-persist";
        path = mkOption {
          description = "Default path for persistence";
          default = throw "You must set path to persistent storage";
          example = "/persist/nixos";
          type = types.str;
        };
        directories = mkOption {
          type = with types; listOf (either str attrs);
          default = [ ];
          description = "Extra directories to persist";
        };
        files = mkOption {
          type = with types; listOf (either str attrs);
          default = [ ];
          description = "Extra files to persist";
        };
        persistHome.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Persist /home/$USER directory";
        };
        persistHome.users = mkOption {
          type = with types; listOf attrs;
          default = lib.optionals cfg.persistHome.enable
            (throw "Set users' home to persist");
          description = "users to persist home";
        };
        persistTmp.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Persist /tmp (and clean on boot)";
        };
      };
    };
  };

  config = mkIf cfg.enable (let
    mkHomePersist = user: ''
      mkdir -p ${cfg.path}/${user.home}
      chown ${user.name}:${user.group} ${cfg.path}/${user.home}
      chmod ${user.homeMode} ${cfg.path}/${user.home}
    '';
    users = builtins.filter (user: user.createHome)
      (lib.attrValues cfg.persistHome.users);
  in {
    # wipe /tmp at boot
    boot.tmp.cleanOnBoot = lib.mkIf cfg.persistTmp.enable true;

    environment.persistence.${cfg.path} = {
      hideMounts = true;
      directories = cfg.directories ++ (lib.optionals cfg.persistTmp.enable [{
        directory = "/tmp";
        user = "root";
        group = "root";
        mode = "1777";
      }]) ;
      # ++ (lib.optionals cfg.persistHome.enable (map (user: {
      #   directory = "${user.home}";
      #   user = user.name;
      #   group = user.group;
      #   mode = user.homeMode;
      # }) users));
      files = cfg.files;
    };
    programs.fuse.userAllowOther = true;

    # system.activationScripts = lib.optionalAttrs cfg.persistHome.enable {
    #   persistent-dirs.text = lib.concatLines (map mkHomePersist users);
    # };
  });
}
