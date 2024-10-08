{ config, pkgs, lib, ... }:
let
  cfg = config.modules.desktop;
in
{
  imports = [
    ./gaming.nix
  ];


  options.modules.desktop = {
    enable = lib.mkEnableOption "Desktop module";

    gaming = {
      enable = lib.mkEnableOption "Gaming";
    };

    # plasma = {
    #   enable = lib.mkEnableOption "Plasma";
    # };
  };

  # Common desktop configuration
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Terminal
      alacritty

      # Media
      obs-studio
      kdenlive
      audacity
      calibre
      mpv

      # Development
      temurin-jre-bin
      zed-editor
      vscode

      # Tools
      imagemagick_light
      impression
      obsidian
      anydesk
      barrier
      szyszka
      ventoy

      # Web
      firefox
      discord
      slack
      thunderbird
    ];

    # Add support for running aarch64 binaries on x86_64
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    # Run non-nix executables
    programs.nix-ld.enable = true;

    # Add reminder for jellyfin
    warnings =
      if pkgs.jellyfin-media-player.version > "1.11.1" then
        [ "Desktop entry may be fixed https://github.com/jellyfin/jellyfin-media-player/issues/649" ]
      else [ ];

    # Setup home for desktop
    home-manager.users.${config.user.name} = {
      imports = [
        ../../extensions/autostart.nix
      ];

      # Hide folders in home
      home.file = {
        ".hidden".text = ''
          Desktop
          Documents
          Downloads
          Music
          Pictures
          Public
          Templates
          Videos
          go
        '';
      };

      xdg = {
        enable = true;
        configFile = {
          # Solaar (Logitech)
          "solaar" = {
            source = ../../dotfiles/solaar;
            recursive = true;
          };

          # Easyeffects
          "easyeffects" = {
            source = ../../dotfiles/easyeffects;
            recursive = true;
          };
        };

        # Custom desktop entries
        desktopEntries = {
          solaar = {
            name = "Solaar";
            icon = "solaar";
            exec = "solaar -w hide";
            categories = [ "Utility" "GTK" ];
          };

          "com.github.iwalton3.jellyfin-media-player" = {
            name = "Jellyfin Media Player";
            icon = "com.github.iwalton3.jellyfin-media-player";
            exec = "jellyfinmediaplayer";
            settings = {
              StartupWMClass = "jellyfinmediaplayer";
            };
            categories = [ "AudioVideo" "Video" "Player" "TV" ];
          };
        };
      };

      # Easyeffects service
      services.easyeffects.enable = true;

      # Autostart
      autostart = {
        enable = true;
        packages = [
          pkgs.solaar
          pkgs.discord
        ];
      };

      programs = {
        # Configure alacritty
        alacritty = {
          enable = true;
          settings = {
            colors.primary.background = "#000000";
            colors.primary.foreground= "#ffffff";
            colors.normal = {
              black = "#000000";
              red = "#fe0100";
              green = "#33ff00";
              yellow = "#feff00";
              blue = "#0066ff";
              magenta = "#cc00ff";
              cyan = "#00ffff";
              white = "#d0d0d0";
            };
            colors.bright = {
              black = "#808080";
              red = "#fe0100";
              green = "#33ff00";
              yellow = "#feff00";
              blue = "#0066ff";
              magenta = "#cc00ff";
              cyan = "#00ffff";
              white = "#FFFFFF";
            };

            font.normal.family = "JetBrainsMono Nerd Font";
            window = {
              opacity = 1;
              dimensions = {
                columns = 140;
                lines = 40;
              };
            };
          };
        };

        # SSH config
        ssh = {
          enable = true;
          extraConfig = ''
Host serverek
	Hostname 192.168.0.109
	User user
	Port 22

Host arm
	Hostname 138.2.183.202
	User ubuntu
	Port 58008

Host work
	Hostname 106.120.84.195
	User f.strzezek
	ProxyCommand nc -X 5 -x 192.168.0.158:1080 %h %p
          '';
        };
      };
    };

    # Firewall
    networking.firewall = {
      enable = true;
      ports = [
        # Barrier
        "24800"
        # Wireguard
        "51820/udp"
        # KDE Connect
        "1714-1764"
      ];

      # https://nixos.wiki/wiki/WireGuard#Setting_up_WireGuard_with_NetworkManager
      extraCommands = ''
        ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
        ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
      '';
      extraStopCommands = ''
        ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
        ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
      '';
    };
    hardware.bluetooth.enable = true; 
    hardware.bluetooth.settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
    hardware.bluetooth.powerOnBoot = true; 
    services.blueman.enable = true;

    # Setup desktop services
    services = {
      xserver = {
        enable = true;

        # Configure keymap in X11
        xkb = {
          layout = "pl";
          variant = "";
        };
      };

      printing = {
        enable = true;
        drivers = with pkgs; [ splix ];
      };

      udisks2.enable = true;
    };

    # Add zram
    # TODO: https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
    # zramSwap = {
    #   enable = true;
    #   memoryPercent = 20;
    # };
    swapDevices =[{
      device = "/swapfile";
      size = 81*1024;
    }];

    # Enable scanners
    hardware.sane.enable = true;

    # Add solaar
    hardware.logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };

    # Enable sound with pipewire.
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
    };

    # Fonts
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        noto-fonts-monochrome-emoji
        (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      ];
      fontDir.enable = true;
      fontconfig.enable = true;
      fontconfig.defaultFonts.monospace = [ "JetBrainsMono Nerd Font" ];
    };

    # Enable KVM
    virtualisation = {
      libvirtd.enable = true;
      spiceUSBRedirection.enable = true;
    };
    programs.virt-manager.enable = true;
  };
}
