{ config, pkgs, buildins, ... }:
{
  home-manager.users.${config.user.name} = {
    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "23.11";

    home.sessionVariables = {
      CGO_ENABLED = 0;
      DOCKER_BUILDKIT = 1;
      GREP_FZF_CMD="grep -Rn ";

      PATH = "$HOME/go/bin:$PATH";

      # Use bat for man
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      MANROFFOPT = "-c";
    };

    programs.zsh = {
      enable = true;
      # defaultKeymap = "emacs";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true; 
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "docker" "docker-compose" "sudo" "history" "dirhistory" "kubectl" ];
        theme = "refined";
      };

#      plugins = [
#        {
#          name = "cmdtime";
#          src = pkgs.fetchFromGitHub {
#            owner = "tom-auger";
#            repo = "cmdtime";
#            rev = "main";
#            sha256 = "v6wCfNoPXDD3sS6yUYE6lre8Ir1yJcLGoAW3O8sUOCg=";
#          };
#        }
#      ];

      localVariables = {
        HIST_STAMPS = "yyyy-mm-dd";
      };

      shellAliases = {
        mkdir = "mkdir -p";
        dmesg = "sudo dmesg";
        lzg="lazygit";
        k="kubectl";
        lzd="lazydocker";
        cat="bat";
        rag=". ranger";
        gic="git clone";
        rr="rm -rf";
        mult="sed -e 's/, \"/,\n\t\"/g' -e 's/{/{\n\t/g' -e 's/\}/\n}/g'";
        touchg="vmtouch_game";
        touchgi="vmtouch_game info";

        # NixOS aliases
        nix-apply = "sudo " + config.environment.shellAliases.nix-apply;
        nix-upgrade = "sudo -s " + config.environment.shellAliases.nix-upgrade;
      };

      initExtra = ''
       	export EDITOR=nvim
  alias tldrf='tldr --list | fzf --preview "tldr {1} --color=always" --preview-window=right,70% | xargs tldr'
	upgo='dupa=$PWD && cd ~/.update-golang && git pull && $su ~/.update-golang/update-golang.sh && cd $dupa';
	find_dirs="\$(find . -type d \( -name '.cache' -o -name 'cache' -o -name '.git' -o -name 'node_modules' \) -prune -o -type d -print 2> /dev/null | fzf)"
	alias ff='f(){ find . -type d \( -name "node_modules" -o -name ".cache" \) -prune -o -type f -name $1 -print | fzf;}; f';
	alias cdf="cd $find_dirs";
	
	alias vimf="nvim \$(find . -type d \( -name 'node_modules' -o -name '.cache' \) -prune -o -type f -print | fzf)";
	alias vimf="nvim \$(find . -type d \( -name 'node_modules' -o -name '.cache' \) -prune -o -type f -print | fzf)";
	alias vimg='fzf --ansi --bind "start:reload:$GREP_FZF_CMD {q}" --bind "change:reload:sleep 0.1; $GREP_FZF_CMD {q} || true" --preview "bat --color=always {1} --highlight-line {2}" --preview-window "up,60%,border-bottom,+{2}+3/3,~3" --delimiter : --bind "enter:become(nvim {1} +{2})"'

	alias gocd='f(){ CompileDaemon -build="$2" -directory="$3" -include="*.rs" -include="*.html" -include="*.sh" -include="*.toml" -include="*.zig" -color=true -log-prefix=false -command="$1" -command-stop=true; }; f';

        PS1="%(?.%F{green}.%F{red})❯ %f"
        # Functions
        function localip() {
            echo $(ip route get 1.1.1.1 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
        }

        function vmtouch_game() {
            local game=$(ls "/mnt/games/SteamLibrary/steamapps/common/" | fzf)
            
            # Check if fzf returned an empty result
            if [ -z "$game" ]; then
                echo "No game selected."
                return 1
            fi
            
            # Check if the first argument is empty
            # if so print cache info
            if [ -n "$1" ]; then
                vmtouch "/mnt/games/SteamLibrary/steamapps/common/$game"
                return 0
            else
                # load selected game to cache
                vmtouch -t "/mnt/games/SteamLibrary/steamapps/common/$game"
            fi
        }

        # Better help formatting with ? or --help
        function help {
            # Replace ? with --help flag
            if [[ "$BUFFER" =~ '^(-?\w\s?)+\?$' ]]; then
                BUFFER="''${BUFFER::-1} --help"
            fi

            # If --help flag found, pipe output through bat
            if [[ "$BUFFER" =~ '^(-?\w\s?)+ --help$' ]]; then
                BUFFER="$BUFFER | bat -p -l help"
            fi

            # press enter
            zle accept-line
        }

	autoload -U add-zsh-hook
 	add-zsh-hook chpwd tmux-window-name
	bindkey -r '^[l'
	bindkey '^[l' autosuggest-accept

        # Define new widget in Zsh Line Editor
        zle -N help
        # Bind widget to enter key
        bindkey '^J' help
        bindkey '^M' help
      '';
    };

    # tmux
    programs.tmux = {
    enable = true;
    clock24 = true;
    extraConfig = ''
set -g mouse on
setw -g mode-keys vi

set -s set-clipboard on
set -g base-index 1
set -g pane-base-index 1
set -g focus-events on
set -g terminal-overrides ',xterm*:Tc'
set -g terminal-overrides ',xterm-256color:RGB'
set -g @cpu_percentage_format "%5.1f%%"
set -g @ram_percentage_format "%5.1f%%"
set -g status-right '#{cpu_bg_colour} CPU: #{cpu_icon} #{cpu_percentage} | RAM: #{ram_percentage} | %a %d-%h %H:%M '

set-option -g update-environment 'XDG_SESSION_TYPE'

unbind C-b
set -g prefix C-a
bind C-a send-prefix
bind -n M-` last-pane 
bind -n M-H previous-window
bind -n M-L next-window
bind '"' split-window -v -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"
bind -r C-f display-popup -E -w 80% -h 80% zsh

bind -r f run-shell "tmux neww ~/.local/bin/tmux-sessionizer"

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'ofirgall/tmux-window-name'
#set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'christoomey/vim-tmux-navigator'
set -g @plugin 'tmux-plugins/tmux-cpu'
set -g @plugin '27medkamal/tmux-session-wizard'

if "test ! -d ~/.tmux/plugins/tpm" \
   "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins'"

run '~/.tmux/plugins/tpm/tpm'
        '';
    };

    home.file.".local/bin/tmux-sessionizer".text = ''
#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/work-repos ~/code ~/projects ~/ ~/work ~/personal -mindepth 1 -maxdepth 1 -type d | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s $selected_name -c $selected
    exit 0
fi

if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected
fi

tmux switch-client -t $selected_name
    '';
    home.file.".local/bin/tmux-sessionizer".executable = true;

    # nvim
    home.file.".config/nvim/init.lua".source = "/etc/nixos/extra_configs/init.lua";
    programs.neovim={
      enable = true;
      defaultEditor = true;
    };


    programs.git = {
      enable = true;

#      aliases = {
#        s = "status";
#        b = "branch -avv";
#        f = "fetch --all --prune";
#        cb = "checkout -b";
#        co = "checkout";
#        l = "log";
#        lo = "log --oneline";
#        lg = "log --graph";
#        log-graph = "log --graph --all --oneline --decorate";
#        sps = "!git stash && git pull && git stash pop";
#      };

      extraConfig = {
        pull.rebase = true;
        url."git@github.com:".insteadOf = "https://github.com/";
      };
    };
  };
}
