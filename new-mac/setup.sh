#!/bin/sh

#===============================================================================
# title           setup.sh
# author          Yosef Serkez
#                 https://github.com/4till2
#===============================================================================
#   A shell script to help with the quick setup and installation of tools and
#   applications for new developers at IdeaCrew.
#
#   Quick Instructions:
#
#   1. Make the script executable:
#      chmod +x ./setup.sh
#
#   2. Run the script:
#      ./setup.sh
#
#   3. Some installs will need your input
#
#
#===============================================================================

#===============================================================================
#  Helper Functions
#===============================================================================

PROJECT_FOLDER=~/Projects

printHeading() {
  printf "\n\n\n\e[0;36m$1\e[0m \n"
}

printActionRequired() {
  # Define ANSI escape codes for colors and bold
  BOLD=$(tput bold)
  NORMAL=$(tput sgr0)
  LIGHT_RED=$(tput setaf 1)
  BG_LIGHT_RED=$(tput setab 1)

  # Print the headline in bold light red
  echo "${BG_LIGHT_RED}${BOLD}ACTION REQUIRED${NORMAL}"

  # Print the given string in bold light red
  echo "${LIGHT_RED}${BOLD}${1}${NORMAL}"
}

printHighlightYellow() {
  YELLOW=$(tput setaf 3)
  UNDERLINE=$(tput smul)
  NORMAL=$(tput sgr0)

  # Print the given string in yellow and underlined
  echo "${YELLOW}${UNDERLINE}${1}${NORMAL}"
}

# Prints a line of dashes that spans the width of the terminal.
# It uses the value of the COLUMNS environment variable to determine the width.
# The line serves as a visual divider between sections or segments of output.
#
# Usage: printDivider
printDivider() {
  printf %"$COLUMNS"s | tr " " "-"
  printf "\n"
}

printLogo() {
  cat <<"EOT"
  _____    _             _____
 |_   _|  | |           / ____|
   | |  __| | ___  __ _| |     _ __ _____      __
   | | / _` |/ _ \/ _` | |    | '__/ _ \ \ /\ / /
  _| || (_| |  __/ (_| | |____| | |  __/\ V  V /
 |_____\__,_|\___|\__,_|\_____|_|  \___| \_/\_/

       Q U I C K   S E T U P   S C R I P T


NOTE:
You can exit the script at any time by
pressing CONTROL+C a bunch
EOT
}

# Usage: commandExists <command>
# Returns: 0 if the command exists, 1 otherwise
commandExists() {
  command -v "$1" >/dev/null 2>&1
}

# Usage: printStep <step> <command>
# Prints the step message and executes the command. If the command fails, it prints an error.
printStep() {
  printf %"$COLUMNS"s | tr " " "-"
  printf "\nInstalling $1...\n"
  $2 || printError "$1"
}

# Usage: fancy_echo <format> [<arguments>...]
# Prints a formatted message using the specified format and arguments.
fancy_echo() {
  local fmt="$1"
  shift

  # shellcheck disable=SC2059
  printf "\\n$fmt\\n" "$@"
}

# Usage: append_to_zshrc <text> [<skip_new_line>]
# Appends the given text to the .zshrc file. If skip_new_line is 1, appends without a new line.
append_to_zshrc() {
  local text="$1" zshrc
  local skip_new_line="${2:-0}"

  if [ -w "$HOME/.zshrc.local" ]; then
    zshrc="$HOME/.zshrc.local"
  else
    zshrc="$HOME/.zshrc"
  fi

  if ! grep -Fqs "$text" "$zshrc"; then
    if [ "$skip_new_line" -eq 1 ]; then
      printf "%s\\n" "$text" >>"$zshrc"
    else
      printf "\\n%s\\n" "$text" >>"$zshrc"
    fi
  fi
}

# Usage: createDirectory <directory>
# Checks if the directory exists. If not, creates it.
createDirectory() {
  [ -d "$1" ] || mkdir -p "$1"
}

# Configures Git with user email and name
configureGit() {
  printDivider
  if [ -n "$(git config --global user.email)" ]; then
    echo "✔ Git email is set to $(git config --global user.email)"
  else
    read -p 'What is your Git email address?: ' gitEmail
    git config --global user.email "$gitEmail"
  fi
  if [ -n "$(git config --global user.name)" ]; then
    echo "✔ Git display name is set to $(git config --global user.name)"
  else
    read -p 'What is your Git display name (Firstname Lastname)?: ' gitName
    git config --global user.name "$gitName"
  fi
  printDivider
}

checkSshKeyExists() {
  if [[ -f ~/.ssh/id_ed25519.pub ]]; then
    return 0
  else
    return 1
  fi
}

checkGpgKeyExists() {
  if [[ $(gpg --list-secret-keys) ]]; then
    return 0
  else
    return 1
  fi
}

# Generates and configures SSH key for Github
generateSshKey() {
  if checkSshKeyExists; then
    printHighlightYellow "$(cat ~/.ssh/id_ed25519.pub)"
  else
    fancy_echo "Creating an SSH key for you..."
    ssh-keygen -t ed25519
  fi
  printDivider
  printActionRequired "Please add the above public key to Github (https://github.com/account/ssh)."
  echo "NOTE: This step is only required once. Skip if already completed"
  fancy_echo "LEARN MORE: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account?tool=webui#adding-a-new-ssh-key-to-your-account"
  read -p "Press [Enter] key after this..."
}

# Generates and configures GPG key for signing commits
generateGpgKey() {
  if checkGpgKeyExists; then
    echo "GPG key already exists. Skipping key generation."
  else
    fancy_echo "Generating a new GPG key for signing commits..."
    gpg --full-generate-key
  fi
}

setGpgKey() {
  fancy_echo "Configuring the GPG key..."
  GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep 'sec' | awk '{print $2}')
  GPG_KEY_ID=${GPG_KEY_ID#*/} # This line removes the key type part, leaving only the Key ID

  echo $GPG_KEY_ID

  # You may need to run 'git config --global --unset gpg.format' if the gpg format was previously set"
  git config --global user.signingkey $GPG_KEY_ID
  git config --global commit.gpgsign true

  # Use Apple Keychain
  echo "pinentry-program $(which pinentry-mac)" >~/.gnupg/gpg-agent.conf
  killall gpg-agent

  gpg --armor --export "$GPG_KEY_ID" | pbcopy
  printActionRequired "Your GPG public key ($GPG_KEY_ID) has been copied to the clipboard. Add it to Github (https://github.com/account/ssh)."
  echo "NOTE: This step is only required once. Skip if already completed"
  fancy_echo "LEARN MORE: https://docs.github.com/en/authentication/managing-commit-signature-verification/adding-a-gpg-key-to-your-github-account"
  read -p "Press [Enter] key after this..."
}

#===============================================================================
# Execute Script
#===============================================================================
printLogo
# shellcheck disable=SC2154
trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT
set -e

# Determine Homebrew prefix
arch="$(uname -m)"
if [ "$arch" = "arm64" ]; then
  HOMEBREW_PREFIX="/opt/homebrew"
else
  HOMEBREW_PREFIX="/usr/local"
fi

printHeading "Configure directories"
if [ ! -d "$HOME/.bin/" ]; then
  mkdir "$HOME/.bin"
fi

if [ ! -f "$HOME/.zshrc" ]; then
  touch "$HOME/.zshrc"
fi

# shellcheck disable=SC2016
append_to_zshrc 'export PATH="$HOME/.bin:$PATH"'

printHeading "Configuring Xcode"
if ! commandExists xcode-select; then
  fancy_echo "Installing Xcode Command Line Tools..."
  xcode-select --install &
else
  fancy_echo "Xcode Command Line Tools are already installed."
fi
# Wait for Xcode Command Line Tools installation to finish
wait

printHeading "Configuring shell to use zsh"
update_shell() {
  local shell_path
  shell_path="$(command -v zsh)"

  fancy_echo "Changing your shell to zsh ..."
  if ! grep "$shell_path" /etc/shells >/dev/null 2>&1; then
    fancy_echo "Adding '$shell_path' to /etc/shells"
    sudo sh -c "echo $shell_path >> /etc/shells"
  fi
  sudo chsh -s "$shell_path" "$USER"
}

case "$SHELL" in
*/zsh)
  if [ "$(command -v zsh)" != "$HOMEBREW_PREFIX/bin/zsh" ]; then
    update_shell
  fi
  ;;
*)
  update_shell
  ;;
esac

printHeading "Configuring Rosetta if necessary"
if [ "$(uname -m)" = "arm64" ]; then
  # checks if Rosetta is already installed
  if ! pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
    echo "Installing Rosetta"
    # Installs Rosetta2
    softwareupdate --install-rosetta --agree-to-license
  else
    echo "Rosetta is installed"
  fi
fi

printHeading "Configuring Homebrew"
# Install homebrew and run brew
if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew ..."

  /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  append_to_zshrc "eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\""
  export PATH="$HOMEBREW_PREFIX/bin:$PATH"
fi

if brew list | grep -Fq brew-cask; then
  fancy_echo "Uninstalling old Homebrew-Cask ..."
  brew uninstall --force brew-cask
fi

printHeading "Updating Homebrew formulae ..."
brew update --force                # https://github.com/Homebrew/brew/issues/1151
brew bundle --file=- <<EOF || true # Continue with script on error
tap "homebrew/services"
tap "mongodb/brew"

brew "tmux"
brew "git"
brew "zsh"
brew "rabbitmq"
brew "pinentry-mac"
brew "mongodb-community"
cask "docker" 
EOF

brew cleanup

printHeading "Configuring asdf as your version manager"
if [ ! -d "$HOME/.asdf" ]; then
  brew install asdf
  append_to_zshrc "source $(brew --prefix asdf)/libexec/asdf.sh" 1
fi

alias install_asdf_plugin=add_or_update_asdf_plugin
add_or_update_asdf_plugin() {
  local name="$1"
  local url="$2"

  if ! asdf plugin-list | grep -Fq "$name"; then
    asdf plugin-add "$name" "$url"
  else
    asdf plugin-update "$name"
  fi
}

# shellcheck disable=SC1091
. "$(brew --prefix asdf)/libexec/asdf.sh"
add_or_update_asdf_plugin "ruby" "https://github.com/asdf-vm/asdf-ruby.git"
add_or_update_asdf_plugin "nodejs" "https://github.com/asdf-vm/asdf-nodejs.git"

install_asdf_language() {
  local language="$1"
  local version="$2"
  if [[ -z "$version" ]]; then
    version="$(asdf list-all "$language" | grep -v "[a-z]" | tail -1)"
  fi

  if ! asdf list "$language" | grep -Fq "$version"; then
    asdf install "$language" "$version"
    asdf global "$language" "$version"
  fi
}

fancy_echo "Installing latest Ruby ..."
install_asdf_language "ruby"
gem update --system
number_of_cores=$(sysctl -n hw.ncpu)
bundle config --global jobs $((number_of_cores - 1))

fancy_echo "Installing latest Node ..."
install_asdf_language "nodejs"

printHeading "Configuring Git"
configureGit
printHeading "Configuring SSH"
generateSshKey
printHeading "Configuring signed commits with GPG"
generateGpgKey
setGpgKey

printHeading "Downloading and configuring remote repositiories"
# shellcheck disable=SC2039
repos=(
  "git@github.com:ideacrew/ea_enterprise.git"
  "git@github.com:ideacrew/enroll.git"
  "git@github.com:ideacrew/fdsh_gateway.git"
  "git@github.com:ideacrew/medicaid_gateway.git"
  "git@github.com:ideacrew/medicaid_eligibility.git"
  "git@github.com:ideacrew/polypress.git"
)

createDirectory $PROJECT_FOLDER
cd $PROJECT_FOLDER

for repo in "${repos[@]}"; do
  # Extract the repo name from the URL
  repo_name=$(basename "$repo" .git)

  # Clone the repo if not already cloned
  if [ ! -d "$repo_name" ]; then
    git clone "$repo"
  else
    echo "Repo $repo_name is already cloned."
  fi
done

cd $PROJECT_FOLDER/ea_enterprise/
git fetch
git checkout -B 2022_update origin/2022_update
cp ./env-example.dev .env

printHighlightYellow "In the future you can now start your local development environment by opening Docker Desktop and running docker-compose up within $PROJECT_FOLDER/ea_enterprise. This time we'll do it for you ;)"

printHeading "Starting containers"
# Check if Docker daemon is running
while ! docker info &>/dev/null; do
  echo "Waiting for Docker daemon to start..."
  open --background -a Docker
  sleep 3
done

echo "Docker daemon is running."
echo "Starting Docker..."

tmux new-session -d -s dockersession "docker-compose up -d"

# Check if the Docker image is running
while ! docker ps --format "{{.Image}}" | grep mongo &>/dev/null; do
   echo "Waiting for Mongo image to be running."
   sleep 3
done
echo "Mongo is running."

printHeading "You'll want to restore the database. You can reach out to someone for a datadump and then run..."
cat <<"EOT"
  docker compose cp $PROJECT_FOLDER/ideacrew-db-dumps/super_dump/. mongodb:/dump
  docker-compose exec mongodb mongorestore --drop
EOT
