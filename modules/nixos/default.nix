{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.environment.nix-persist;
in {
  imports = [./common.nix ./essential.nix];
  options.environment.nix-persist = mkOption {
    description = "nix-persist settings";
    default = {};
    type = types.submodule {
      options = {
        enable = mkEnableOption "nix-persist";
        path = mkOption {
          description = "Default path for persistence";
          default = null;
          example = "/persist/nixos";
          type = with types; nullOr str;
        };
        directories = mkOption {
          type = with types; listOf (either str attrs);
          default = [];
          description = "Extra directories to persist";
        };
        files = mkOption {
          type = with types; listOf (either str attrs);
          default = [];
          description = "Extra files to persist";
        };
        persistTmp = mkOption {
          type = types.bool;
          default = false;
          description = "Persist /tmp (and clean on boot)";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.path != null;
        message = "You must set path to persistent storage";
      }
    ];
    # wipe /tmp at boot
    boot.tmp.cleanOnBoot = lib.mkIf cfg.persistTmp true;

    environment.persistence.${cfg.path} = {
      hideMounts = true;
      directories =
        cfg.directories
        ++ (lib.optionals cfg.persistTmp [
          {
            directory = "/tmp";
            user = "root";
            group = "root";
            mode = "1777";
          }
        ]);
      files = cfg.files;
    };
    programs.fuse.userAllowOther = true;
  };
}
