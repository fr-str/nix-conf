# Home-Manager autostart module for managing desktop applications
# Import inside home-manager.users.${config.user.name}
{ config, lib, ... }:
let
  cfg = config.autostart;
in
{
  options.autostart = {
    enable = lib.mkEnableOption "Enable autostart module";

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "List of packages to be autostarted";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.xdg.enable;
        message = "xdg.enable must be true, required for xdg.configFile";
      }
    ];

    xdg.configFile = builtins.listToAttrs (map
      (pkg:
        let
          name = if pkg ? pname then pkg.pname else pkg.name;
          # Find custom desktop entry
          custom = lib.findFirst (p: p.name == "${name}.desktop") null config.home.packages;
        in
        {
          name = "autostart/" + name + ".desktop";
          value =
            if custom != null then {
              # Use custom desktop entry
              text = custom.text;
            } else if pkg ? desktopItem then {
              # Use desktopItem value
              text = pkg.desktopItem.text;
            } else {
              # Find desktop file in standard location
              source = lib.findFirst
                (x: lib.hasSuffix ".desktop" x)
                null
                (lib.filesystem.listFilesRecursive "${pkg}/share/applications/");
            };
        }
      )
      cfg.packages);
  };
}
