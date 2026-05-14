#!/usr/bin/env bash
set -euo pipefail

DOTFILES=$(dirname "$(pwd)/$0")

copy() {
  local SRC=$1
  local DEST=$2

  mkdir -p "$(dirname "$DEST")"
  cp -rf "$SRC" "$DEST"
}

link() {
  local SRC=$1
  local DEST=$2

  mkdir -p "$(dirname "$DEST")"
  ln -sf "$SRC" "$DEST"
}

render() {
  local SRC=$1
  local DEST=$2

  mkdir -p "$(dirname "$DEST")"
  awk -f "$DOTFILES/render.awk" "$SRC" >"$DEST"
}

linux() {
  if command -v apt >/dev/null 2>&1; then
    apt install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    yum install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    pacman -S --noconfirm "$@"
  elif command -v zypper >/dev/null 2>&1; then
    zypper install -y "$@"
  fi
}

install() {
  if command -v winget >/dev/null 2>&1; then
    export WINDOWS=1
    winget source update
    powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('MSYS2_PATH_TYPE', 'inherit', 'User')"
  elif command -v termux-info >/dev/null 2>&1; then
    export ANDROID=1
    pkg update -y
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "linux" ]]; then
    export LINUX=1
    if command -v apt >/dev/null 2>&1; then
      apt update -y
      if ! command -v flatpak >/dev/null 2>&1 && [[ -n "$XDG_CURRENT_DESKTOP" || -n "$DESKTOP_SESSION" ]]; then
        apt install -y flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      fi
    elif command -v dnf >/dev/null 2>&1; then
      dnf makecache
      if ! command -v flatpak >/dev/null 2>&1 && [[ -n "$XDG_CURRENT_DESKTOP" || -n "$DESKTOP_SESSION" ]]; then
        dnf install -y flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      fi
    elif command -v yum >/dev/null 2>&1; then
      yum makecache
      if ! command -v flatpak >/dev/null 2>&1 && [[ -n "$XDG_CURRENT_DESKTOP" || -n "$DESKTOP_SESSION" ]]; then
        yum install -y flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      fi
    elif command -v pacman >/dev/null 2>&1; then
      pacman -Sy
      if ! command -v flatpak >/dev/null 2>&1 && [[ -n "$XDG_CURRENT_DESKTOP" || -n "$DESKTOP_SESSION" ]]; then
        pacman -S --noconfirm flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      fi
    elif command -v zypper >/dev/null 2>&1; then
      zypper refresh
      if ! command -v flatpak >/dev/null 2>&1 && [[ -n "$XDG_CURRENT_DESKTOP" || -n "$DESKTOP_SESSION" ]]; then
        zypper install -y flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      fi
    else
      echo "Unsupported Linux package manager"
      exit 1
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "darwin" ]]; then
    export OSX=1
    if ! command -v brew >/dev/null 2>&1; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  else
    echo "Unsupported OS for installation"
    exit 1
  fi
}

install_bash() {
  if command -v winget >/dev/null 2>&1; then
    if ! command -v git >/dev/null 2>&1; then
      echo "Git not found. Installing Git..."
      winget install -e --disable-interactivity Git.Git
    fi
    if ! command -v wget >/dev/null 2>&1; then
      echo "Wget not found. Installing Wget..."
      winget install -e --disable-interactivity JernejSimoncic.Wget
    fi
  elif command -v termux-info >/dev/null 2>&1; then
    if ! command -v git >/dev/null 2>&1; then
      echo "Git not found. Installing Git..."
      pkg install -y git
    fi
    if ! command -v bash >/dev/null 2>&1; then
      echo "Bash not found. Installing Bash..."
      pkg install -y bash
    fi
    if ! command -v curl >/dev/null 2>&1; then
      echo "Curl not found. Installing Curl..."
      pkg install -y curl
    fi
    if ! command -v wget >/dev/null 2>&1; then
      echo "Wget not found. Installing Wget..."
      pkg install -y wget
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "linux" ]]; then
    if ! command -v git >/dev/null 2>&1; then
      echo "Git not found. Installing Git..."
      linux git
    fi
    if ! command -v bash >/dev/null 2>&1; then
      echo "Bash not found. Installing Bash..."
      linux bash
    fi
    if ! command -v curl >/dev/null 2>&1; then
      echo "Curl not found. Installing Curl..."
      linux curl
    fi
    if ! command -v wget >/dev/null 2>&1; then
      echo "Wget not found. Installing Wget..."
      linux wget
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "darwin" ]]; then
    if ! command -v git >/dev/null 2>&1; then
      echo "Git not found. Installing Git..."
      brew install git
    fi
    if ! command -v bash >/dev/null 2>&1; then
      echo "Bash not found. Installing Bash..."
      brew install bash
    fi
    if ! command -v curl >/dev/null 2>&1; then
      echo "Curl not found. Installing Curl..."
      brew install curl
    fi
    if ! command -v wget >/dev/null 2>&1; then
      echo "Wget not found. Installing Wget..."
      brew install wget
    fi
  else
    echo "Unsupported OS for Bash installation"
    return
  fi

  link "$DOTFILES/bash/.bashrc" "$HOME/.bashrc"
  link "$DOTFILES/bash/.profile" "$HOME/.profile"
  link "$DOTFILES/bash/.profile" "$HOME/.zprofile"
  link "$DOTFILES/bash/.gitconfig" "$HOME/.gitconfig"
  if [ ! -f "$HOME/.gitconfig.local" ]; then
    touch "$HOME/.gitconfig.local"
  fi
}

install_tmux() {
  if command -v winget >/dev/null 2>&1; then
    PLATFORM="windows"
    if ! command -v tmux >/dev/null 2>&1; then
      echo "Tmux not found. Installing Tmux..."
      cp -Rf "$DOTFILES/tmux/windows/"* /usr/bin/
    fi
  elif command -v termux-info >/dev/null 2>&1; then
    PLATFORM="android"
    if ! command -v tmux >/dev/null 2>&1; then
      echo "Tmux not found. Installing Tmux..."
      pkg install -y tmux
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "linux" ]]; then
    PLATFORM="linux"
    if ! command -v tmux >/dev/null 2>&1; then
      echo "Tmux not found. Installing Tmux..."
      install tmux
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "darwin" ]]; then
    PLATFORM="osx"
    if ! command -v tmux >/dev/null 2>&1; then
      echo "Tmux not found. Installing Tmux..."
      brew install tmux
    fi
  else
    echo "Unsupported OS for Tmux installation"
    return
  fi

  render "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"
}

install_mise() {
  if command -v winget >/dev/null 2>&1; then
    if ! command -v mise >/dev/null 2>&1; then
      echo "Mise not found. Installing Mise..."
      winget install -e --disable-interactivity jdx.mise
    fi
  elif command -v termux-info >/dev/null 2>&1; then
    echo "Mise installation not supported in Termux yet"
    return
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "linux" ]]; then
    if ! command -v mise >/dev/null 2>&1; then
      echo "Mise not found. Installing Mise..."
      curl https://mise.run | sh
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "darwin" ]]; then
    if ! command -v mise >/dev/null 2>&1; then
      echo "Mise not found. Installing Mise..."
      brew install mise
    fi
  else
    echo "Unsupported OS for Mise installation"
    return
  fi

  link "$DOTFILES/mise/mise.toml" "$HOME/.config/mise/mise.toml"
  mise install -y
}

install_ssh() {
  if command -v winget >/dev/null 2>&1; then
    if ! command -v ssh >/dev/null 2>&1; then
      echo "OpenSSH not found. Installing OpenSSH..."
      winget install -e --disable-interactivity Microsoft.OpenSSH.Beta
    fi
  elif command -v termux-info >/dev/null 2>&1; then
    if ! command -v ssh >/dev/null 2>&1; then
      echo "OpenSSH not found. Installing OpenSSH..."
      pkg install -y openssh
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "linux" ]]; then
    if ! command -v ssh >/dev/null 2>&1; then
      echo "OpenSSH not found. Installing OpenSSH..."
      linux openssh openssh-client
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "darwin" ]]; then
    if ! command -v ssh >/dev/null 2>&1; then
      echo "OpenSSH not found. Installing OpenSSH..."
      brew install openssh
    fi
  else
    echo "Unsupported OS for OpenSSH installation"
    return
  fi

  if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo "OpenSSH key not found. Generating OpenSSH key..."
    ssh-keygen -t rsa -b 4096 -C "$(git config --global user.email)" -f "$HOME/.ssh/id_rsa" -N ""
  fi
}

install_vim() {
  if command -v winget >/dev/null 2>&1; then
    if ! command -v vim >/dev/null 2>&1; then
      echo "Vim not found. Installing Vim..."
      winget install -e --disable-interactivity vim.vim
    fi
  elif command -v termux-info >/dev/null 2>&1; then
    if ! command -v vim >/dev/null 2>&1; then
      echo "Vim not found. Installing Vim..."
      pkg install -y vim
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "linux" ]]; then
    if ! command -v vim >/dev/null 2>&1; then
      echo "Vim not found. Installing Vim..."
      linux vim
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "darwin" ]]; then
    if ! command -v vim >/dev/null 2>&1; then
      echo "Vim not found. Installing Vim..."
      brew install vim
    fi
  else
    echo "Unsupported OS for Vim installation"
    return
  fi

  link "$DOTFILES/vim/.vimrc" "$HOME/.vimrc"
  git clone https://github.com/morhetz/gruvbox.git "$HOME/.vim" || true
}

install_fonts() {
  if command -v winget >/dev/null 2>&1; then
    for font in "$DOTFILES/fonts/"*.ttf; do
      copy "$font" "/c/Windows/Fonts/$(basename "$font")"
    done
  elif command -v termux-info >/dev/null 2>&1; then
    copy "$DOTFILES/fonts/MesloLGMNerdFont-Regular.ttf" "$HOME/.termux/font.ttf"
    termux-reload-settings
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "linux" ]]; then
    for font in "$DOTFILES/fonts/"*.ttf; do
      copy "$font" "$HOME/.local/share/fonts/$(basename "$font")"
    done
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "darwin" ]]; then
    for font in "$DOTFILES/fonts/"*.ttf; do
      copy "$font" "/Library/Fonts/$(basename "$font")"
    done
  else
    echo "Unsupported OS for Fonts installation"
    return
  fi
}

install_starship() {
  if command -v winget >/dev/null 2>&1; then
    if ! command -v starship >/dev/null 2>&1; then
      echo "Starship not found. Installing Starship..."
      winget install -e --disable-interactivity Starship.Starship
    fi
  elif command -v termux-info >/dev/null 2>&1; then
    if ! command -v starship >/dev/null 2>&1; then
      echo "Starship not found. Installing Starship..."
      pkg install -y starship
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "linux" ]]; then
    if ! command -v starship >/dev/null 2>&1; then
      echo "Starship not found. Installing Starship..."
      curl -sS https://starship.rs/install.sh | sh
    fi
  elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" == "darwin" ]]; then
    if ! command -v starship >/dev/null 2>&1; then
      echo "Starship not found. Installing Starship..."
      brew install starship
    fi
  else
    echo "Unsupported OS for Starship installation"
    return
  fi

  link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
}

install_alacritty() {
  if command -v winget >/dev/null 2>&1; then
    PLATFORM="windows"
    ALACRITTY_HOME="$HOME/AppData/Roaming/alacritty"
    if ! command -v alacritty >/dev/null 2>&1; then
      echo "Alacritty not found. Installing Alacritty..."
      winget install -e --disable-interactivity Alacritty.Alacritty
      powershell -NoProfile -Command '$lnk="C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Alacritty\Alacritty.lnk"; $ws=New-Object -ComObject WScript.Shell; $sc=$ws.CreateShortcut($lnk); $sc.WorkingDirectory=$env:USERPROFILE; $sc.Save()'
    fi
  elif command -v flatpak >/dev/null 2>&1; then
    PLATFORM="linux"
    ALACRITTY_HOME="$HOME/.var/app/com.alacritty.Alacritty/config/alacritty"
    if ! command -v alacritty >/dev/null 2>&1; then
      echo "Alacritty not found. Installing Alacritty..."
      flatpak install -y flathub com.alacritty.Alacritty
    fi
  elif command -v brew >/dev/null 2>&1; then
    PLATFORM="osx"
    ALACRITTY_HOME="$HOME/.config/alacritty"
    if ! command -v alacritty >/dev/null 2>&1; then
      echo "Alacritty not found. Installing Alacritty..."
      brew install --cask alacritty
      xattr -dr com.apple.quarantine /Applications/Alacritty.app
    fi
  else
    echo "Unsupported OS for Alacritty installation"
    return
  fi

  render "$DOTFILES/alacritty/alacritty.toml.tpl" "$ALACRITTY_HOME/alacritty.toml"
  read rows columns < <(alacritty -v -o 'window.startup_mode="Maximized"' -e echo | awk '/PTY dimensions:/{print $7, $9}') && lines=$(($rows * 2 / 3))
  sed -i.bak -e "s/lines = 0/lines = $lines/" -e "s/columns = 0/columns = $columns/" "$ALACRITTY_HOME/alacritty.toml" && rm "$ALACRITTY_HOME/alacritty.toml.bak"
  # TODO: Add Alacritty toggle hotkey setup (on-boot => first run)
}

install_vscode() {
  if command -v winget >/dev/null 2>&1; then
    VSCODE_HOME="$HOME/AppData/Roaming/Code/User"
    if ! command -v code >/dev/null 2>&1; then
      echo "VSCode not found. Installing VSCode..."
      winget install -e --disable-interactivity Microsoft.VisualStudioCode
    fi
  elif command -v flatpak >/dev/null 2>&1; then
    VSCODE_HOME="$HOME/.var/app/com.visualstudio.code/config/Code/User"
    if ! command -v code >/dev/null 2>&1; then
      echo "VSCode not found. Installing VSCode..."
      flatpak install -y flathub com.visualstudio.code
    fi
  elif command -v brew >/dev/null 2>&1; then
    VSCODE_HOME="$HOME/Library/Application Support/Code/User"
    if ! command -v code >/dev/null 2>&1; then
      echo "VSCode not found. Installing VSCode..."
      brew install --cask visual-studio-code
      xattr -dr com.apple.quarantine /Applications/Visual\ Studio\ Code.app
    fi
  else
    echo "Unsupported OS for VSCode installation"
    return
  fi

  link "$DOTFILES/vscode/settings.json" "$VSCODE_HOME/settings.json"
  link "$DOTFILES/vscode/keybindings.json" "$VSCODE_HOME/keybindings.json"
  if [ ! -f "$VSCODE_HOME/extensions.txt" ]; then
    link "$DOTFILES/vscode/extensions.txt" "$VSCODE_HOME/extensions.txt"
    sed 's/\r$//' "$VSCODE_HOME/extensions.txt" | while read -r extension; do
      code --install-extension "$extension"
    done
  fi
}

install_docker() {
  if command -v winget >/dev/null 2>&1; then
    DOCKER_HOME="$HOME/.docker"
    if ! command -v docker >/dev/null 2>&1; then
      echo "Docker not found. Installing Docker..."
      winget install -e --disable-interactivity Docker.DockerDesktop
    fi
  elif command -v flatpak >/dev/null 2>&1; then
    DOCKER_HOME="/etc/docker"
    if ! command -v docker >/dev/null 2>&1; then
      echo "Docker not found. Installing Docker..."
      curl -fsSL https://get.docker.com | sh
    fi
  elif command -v brew >/dev/null 2>&1; then
    DOCKER_HOME="$HOME/.docker"
    if ! command -v docker >/dev/null 2>&1; then
      echo "Docker not found. Installing Docker..."
      brew install --cask docker
      # xattr -dr com.apple.quarantine /Applications/Docker.app
    fi
  else
    echo "Unsupported OS for Docker installation"
    return
  fi

  copy "$DOTFILES/docker/daemon.json" "$DOCKER_HOME/daemon.json"
}

install_chrome() {
  if command -v winget >/dev/null 2>&1; then
    if ! winget list --id Google.Chrome >/dev/null 2>&1; then
      echo "Chrome not found. Installing Chrome..."
      winget install -e --disable-interactivity Google.Chrome
    fi
  elif command -v flatpak >/dev/null 2>&1; then
    if ! flatpak info com.google.Chrome >/dev/null 2>&1; then
      echo "Chrome not found. Installing Chrome..."
      flatpak install -y flathub com.google.Chrome
    fi
  elif command -v brew >/dev/null 2>&1; then
    if ! brew list --cask google-chrome >/dev/null 2>&1; then
      echo "Chrome not found. Installing Chrome..."
      brew install --cask google-chrome
      xattr -dr com.apple.quarantine /Applications/Google\ Chrome.app
    fi
  else
    echo "Unsupported OS for Chrome installation"
    return
  fi
}

install_firefox() {
  if command -v winget >/dev/null 2>&1; then
    if ! winget list --id Mozilla.Firefox >/dev/null 2>&1; then
      echo "Firefox not found. Installing Firefox..."
      winget install -e --disable-interactivity Mozilla.Firefox
    fi
  elif command -v flatpak >/dev/null 2>&1; then
    if ! flatpak info org.mozilla.firefox >/dev/null 2>&1; then
      echo "Firefox not found. Installing Firefox..."
      flatpak install -y flathub org.mozilla.firefox
    fi
  elif command -v brew >/dev/null 2>&1; then
    if ! brew list --cask firefox >/dev/null 2>&1; then
      echo "Firefox not found. Installing Firefox..."
      brew install --cask firefox
      xattr -dr com.apple.quarantine /Applications/Firefox.app
    fi
  else
    echo "Unsupported OS for Firefox installation"
    return
  fi
}

install_fdm() {
  if command -v winget >/dev/null 2>&1; then
    if ! winget list --id SoftDeluxe.FreeDownloadManager >/dev/null 2>&1; then
      echo "Free Download Manager not found. Installing Free Download Manager..."
      winget install -e --disable-interactivity SoftDeluxe.FreeDownloadManager
    fi
  elif command -v flatpak >/dev/null 2>&1; then
    if ! flatpak info org.freedownloadmanager.Manager >/dev/null 2>&1; then
      echo "Free Download Manager not found. Installing Free Download Manager..."
      flatpak install -y flathub org.freedownloadmanager.Manager
    fi
  elif command -v brew >/dev/null 2>&1; then
    if ! brew list --cask free-download-manager >/dev/null 2>&1; then
      echo "Free Download Manager not found. Installing Free Download Manager..."
      brew install --cask free-download-manager
      # xattr -dr com.apple.quarantine /Applications/Free\ Download\ Manager.app
    fi
  else
    echo "Unsupported OS for Free Download Manager installation"
    return
  fi
}

install_mpv() {
  if command -v winget >/dev/null 2>&1; then
    if ! winget list --id mpv.net >/dev/null 2>&1; then
      echo "MPV not found. Installing MPV..."
      winget install -e --disable-interactivity mpv.net
    fi
  elif command -v flatpak >/dev/null 2>&1; then
    if ! flatpak info io.mpv.Mpv >/dev/null 2>&1; then
      echo "MPV not found. Installing MPV..."
      flatpak install -y flathub io.mpv.Mpv
    fi
  elif command -v brew >/dev/null 2>&1; then
    if ! brew list --cask mpv >/dev/null 2>&1; then
      echo "MPV not found. Installing MPV..."
      brew install --cask mpv
      xattr -dr com.apple.quarantine /Applications/mpv.app
    fi
  else
    echo "Unsupported OS for MPV installation"
    return
  fi
}

install
install_bash
install_tmux
install_mise
install_ssh
install_vim
install_fonts
install_starship
install_alacritty
install_vscode
install_docker
install_chrome
install_firefox
install_fdm
install_mpv

echo "All installations completed."
