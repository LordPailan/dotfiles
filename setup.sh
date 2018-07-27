#!/bin/bash
BOLD=$(tput bold)
BLUECOLOR=$(tput setaf 4)
REDCOLOR=$(tput setaf 1)
GREENCOLOR=$(tput setaf 2)
BLUECOLOR_BOLD=$BLUECOLOR$BOLD
REDCOLOR_BOLD=$REDCOLOR$BOLD
GREENCOLOR_BOLD=$GREENCOLOR$BOLD
ENDCOLOR=$(tput sgr0)

# Copies of system files will be kept here
BACKUP_FOLDER="${HOME}/backup"

# return the absolute path of a local file
dotfiles_absolute() {
  local file=$1
  echo "$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
}

# Easily choose the link method between a symbolic link or a copy
dotfiles_link() {
  local local_dotfile system_dotfile
  local_dotfile=$(dotfiles_absolute "$1")
  system_dotfile="$2"

  [ ! -d "$BACKUP_FOLDER" ] && mkdir -p "$BACKUP_FOLDER"

  # save a copy of the system file, if it is not a link already
  readlink "$system_dotfile" >/dev/null && \
    mv "$system_dotfile" "$BACKUP_FOLDER" > /dev/null 2>&1
  ln -sf "$local_dotfile" "$system_dotfile"
}

setup_git() {
  echo && echo "${GREENCOLOR}Setting up some git defaults.....${ENDCOLOR}"
  while read -r line ; do

    echo "${BLUECOLOR}${line}${ENDCOLOR}"
    section=$(echo "$line" | cut -d" " -f1)
    value=$(echo "$line" | cut -d" " -f2-)

    git config --global "$section" "$value"
  done < .gitconfig

  printf "\n%s\n" "Remember to execute: ${GREENCOLOR_BOLD}git config --global user.email <YOUR_EMAIL>${ENDCOLOR}"
}

setup_vim() {
  [ -z $(which vim) ] && \
    echo "You don't have VIM installed.... you suck" && return

  VIMDIR=~/.vim
  echo && echo "${GREENCOLOR}Setting up VIM in ${VIMDIR} ...${ENDCOLOR}"
  rm -rf "${VIMDIR}/bundle"
  mkdir -p "${VIMDIR}/tmp" "${VIMDIR}/backup" "${VIMDIR}/colors" > /dev/null 2>&1
  cp .vim/colors/monokai.vim "${VIMDIR}/colors/"
  git clone https://github.com/gmarik/Vundle.vim ${VIMDIR}/bundle/Vundle.vim
  dotfiles_link .vimrc ~/.vimrc
  vim +PluginInstall +qall
}

setup_dotfiles() {
  echo && echo "${GREENCOLOR}Setting up bash dotfiles_....${ENDCOLOR}"
  touch ~/.bash_profile # in case it does not exist..
  [ "$(grep -c "\. ~/.bashrc" ~/.bash_profile)" -ne 1 ] && cat .bash_profile  >> ~/.bash_profile

  dotfiles_link .bashrc ~/.bashrc
  dotfiles_link .bash_local_aliases ~/.bash_local_aliases

  # shellcheck source=/dev/null
  . ~/.bash_profile 2>&1 > /dev/null

  printf "\nNew functions and aliases installed, type '%s' tp check them out!\n" "${BLUECOLOR_BOLD}my_commands${ENDCOLOR}"
}

setup_ruby() {
  [ ! -f ~/.irbrc ] && return
  echo && echo "${GREENCOLOR}Setting up some Ruby defaults.....${ENDCOLOR}"
  ! grep -q 'irb/completion' ~/.irbrc && \
    echo "require 'irb/completion'" >> ~/.irbrc
}

setup_postgres() {
  [ ! -f ~/.psqlrc ] && return
  echo "${GREENCOLOR}Setting up some PostgreSQL defaults.....${ENDCOLOR}"
  dotfiles_link .psqlrc ~/.psqlrc
}

setup_configs() {
  [ ! -z $(which terminator) ] && \
    echo && echo "${GREENCOLOR}Setting my terminator config...${ENDCOLOR}" && \
    mkdir -p "$HOME/.config/terminator" && \
    dotfiles_link .config/terminator/config "$HOME/.config/terminator/config"
}

setup_gnome_extensions() {
  # If not in Linux, just get out:
  is.mac && return

  # Maybe gnome stuff is not set up correctly
  [ -z $(which gnome-shell-extension-installer) ] && return
  [ -z $(which gnome-shell) ] && return

  # Download magnificent and already-created script for shell extension's management
  if [ ! -f "$HOME/bin/gnome-shell-extension-installer" ] ; then
    mkdir -p "$HOME/bin"
    curl -qsS https://raw.githubusercontent.com/brunelli/gnome-shell-extension-installer/master/gnome-shell-extension-installer -o "$HOME/bin/gnome-shell-extension-installer"
    chmod +x "$HOME/bin/gnome-shell-extension-installer"
  fi

  # Install my main extensions
  gnome-shell-extension-installer 307 3.18 # Dash to dock
  gnome-shell-extension-installer 112 3.18 # remove accesibility
  gnome-shell-extension-installer 613 3.14 # Weather
  gnome-shell-extension-installer 545  # Hide top bar
  gnome-shell-extension-installer 442 3.20 # Dropdown terminal

  # restart shell - the ampersand is mandatory
  gnome-shell --replace &
}

setup_repo_change_script() {
  autocomplete_route="$(_get_bash_completion)"
  [ ! -f "${autocomplete_route}" ] && \
    echo "Bash auto-completion not installed, or not found in '${autocomplete_route}', refusing to install repo autocomplete" && return

  # I instead of symlinking because I want to keep the original file versioned
  cp -f ./files/repo "${autocomplete_route}.d/"

  printf "\nAutocompletion for the %s command has been installed.\nRun it once to configure it, and then %s.\n" \
    "${BLUECOLOR_BOLD}repo${ENDCOLOR}" "${REDCOLOR_BOLD}START A NEW SHELL${ENDCOLOR}"
}

# Lots of fancy functions here:
# shellcheck source=/dev/null
source .bash_local_aliases

setup_all() {
  setup_vim
  setup_dotfiles
  setup_git
  setup_postgres
  setup_ruby
  setup_configs
  setup_gnome_extensions
  setup_repo_change_script
}

mode=${1:-all}
case "${mode}" in
  all)      setup_all ;;
  vim)      setup_vim ;;
  dotfiles) setup_dotfiles ;;
  git)      setup_git ;;
  postgres) setup_postgres ;;
  ruby)     setup_ruby ;;
  configs)  setup_configs ;;
  gnome)    setup_gnome_extensions ;;
  repo)     setup_repo_change_script ;;
  help|*)
    echo && echo "${GREENCOLOR_BOLD}setup.sh${ENDCOLOR}"
    echo "One-time, not-interactive setup for optimal CLI - by Juan Arias"
    echo ; echo "Args:"
    echo "* [no args] - Default option, installs everything in one go"
    echo "* vim - installs my .vimrc file and most useful Plugins using Vundle (requires vim)"
    echo "* dotfiles - installs my .bash* files, including Prompt and Aliases"
    echo "* git - Some useful git aliases"
    echo "* postgres - Basically a simple .psqlrc file"
    echo "* ruby - Small improvement over default irb config"
    echo "* configs - For now, only some terminator tweaks (requires Linux && terminator)"
    echo "* gnome - Installs some really useful Gnome addons (requires Gnome 3.x)"
    echo "* repo - If you have a lot of repos, you'll love this"
    echo "* help - this message"
    echo && exit 0
    ;;
esac

printf "\n%s\n" "${GREENCOLOR_BOLD}Everything is done, enjoy!${ENDCOLOR}"
