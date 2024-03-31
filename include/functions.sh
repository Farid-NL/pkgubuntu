#!/usr/bin/env bash

# Utilities
error="${HOME}/error.log"

#-------------------------------------------------------------------
# Error handler
#-------------------------------------------------------------------
# @arg $1 Title of the box (context of the error)
# @arg $2 Message
#-------------------------------------------------------------------
__error_handler__() {
  local msg="${2:-Something failed!}\n\nCheck error log"

  if (whiptail --title "❗ $1 ❗" --yesno "${msg}" --yes-button 'Show error log' \
      --no-button 'Exit' --defaultno 9 60)
  then
    whiptail --title 'Error log file' --scrolltext --textbox "${error}" 15 80
  fi

  exit 1
}

#-------------------------------------------------------------------
# Reset everything as it was before runnig the script
#-------------------------------------------------------------------
__cleanup__() {
  tput cnorm
  rm -f /tmp/package.deb
  # shellcheck disable=SC2154
  cd "${init_dir}" || return
}

#-------------------------------------------------------------------
# Display the final message or the error log given the user's choice
#-------------------------------------------------------------------
# @arg $1 Message
#-------------------------------------------------------------------
final_message() {

  if (whiptail --title 'Goodbye!' --yesno "$1" --yes-button 'Show error log' \
      --no-button 'Exit' --defaultno --scrolltext 15 80)
  then
    whiptail --title 'Error log file' --scrolltext --textbox "${error}" 15 80
  fi
}

#-------------------------------------------------------------------
# Append a separator in the error log with the name of the package
#-------------------------------------------------------------------
# @arg $1 Name of the package
# @arg $2 Target file
#-------------------------------------------------------------------
__log_separator__() {
  echo -e "---------------$1---------------" >> "${error}"
}

#-------------------------------------------------------------------
# Display infobox with a spinner showing that a process is running
#-------------------------------------------------------------------
# @arg $1 Command to be executed
# @arg $2 Title of the infobox
# @arg $3 Message of the infobox
#-------------------------------------------------------------------
__infobox_spinner__() {
  local frames=('▰ ▱ ▱ ▱ ▱' '▱ ▰ ▱ ▱ ▱' '▱ ▱ ▰ ▱ ▱' '▱ ▱ ▱ ▰ ▱' '▱ ▱ ▱ ▱ ▰')

  tput civis # cursor invisible

  local pid=$1

  while kill -0 "${pid}" 2&> /dev/null; do
    local i=$(( (i + 1) % ${#frames[@]} ))
    TERM=ansi; whiptail --title "🔨 $2 🔨" --infobox "$3\n${frames[$i]}" 9 60; TERM=xterm-256color
    sleep 0.1
  done

  tput cnorm # cursor back to normal
  wait "${pid}" # capture exit code
  return $?
}

#-------------------------------------------------------------------
# Install package from default repository
#-------------------------------------------------------------------
# @arg $1 Human-readable name of the package
# @arg $2 Name of the package
# @arg $3 Installed?
#
# @example
#   install_standard "Yakuake" "yakuake" "${is_installed[yakuake]}"
#-------------------------------------------------------------------
install_standard() {
  if $3; then return; fi

  if (! whiptail --title "🚀 $1 🚀" --yesno "Do you want to install '$1'?" --defaultno 9 60); then
    whiptail --title "❌ $1 ❌" --msgbox 'Installation canceled' 9 60
    return
  fi

  __log_separator__ "$1"

  # Installation
  sudo apt-get install "$2" -qq > /dev/null 2>> "${error}" &
  if ! __infobox_spinner__ $! "$1" 'Installing'; then
    __error_handler__ "$1" 'Installation failure!'
  fi

  whiptail --title "✅ $1 ✅" --msgbox 'Installation completed' 9 60
}

#-------------------------------------------------------------------
# Install package from PPA
#-------------------------------------------------------------------
# @arg $1 Human-readable name of the package
# @arg $2 Name of the package
# @arg $3 PPA
# @arg $4 Installed?
#
# @example
#   install_PPA "git" "git" "ppa:git-core/ppa" "${is_installed[git]}"
#-------------------------------------------------------------------
install_PPA() {
  if $4; then return; fi

  if (! whiptail --title "🚀 $1 🚀" --yesno "Do you want to install '$1'?" --defaultno 9 60); then
    whiptail --title "❌ $1 ❌" --msgbox 'Installation canceled' 9 60
    return
  fi

  __log_separator__ "$1"

  # PPA set up
  sudo add-apt-repository -y "$3" > /dev/null 2>> "${error}" &
  if ! __infobox_spinner__ $! "$1" 'Setting PPA'; then
    __error_handler__ "$1" 'PPA configuration failure!'
  fi

  # Update
  sudo apt-get update -qq > /dev/null 2>> "${error}" &
  if ! __infobox_spinner__ $! "$1" 'Updating packages'; then
    __error_handler__ "$1" 'Update failure!'
  fi

  # Installation
  sudo apt-get install "$2" -qq > /dev/null 2>> "${error}" &
  if ! __infobox_spinner__ $! "$1" "Installing $2"; then
    __error_handler__ "$1" 'Installation failure!'
  fi

  whiptail --title "✅ $1 ✅" --msgbox 'Installation completed' 9 60
}

#-------------------------------------------------------------------
# Install the package from the downloaded DEB file
#-------------------------------------------------------------------
# @arg $1 Human-readable name of the package
# @arg $2 URL of DEB file
# @arg $3 Installed?
#
# @example
#   install_deb "Chrome" "${chrome_url}" "${is_installed[google-chrome]}"
#   install_deb "VSCode" "${code_url}" "${is_installed[code]}"
#-------------------------------------------------------------------
install_deb() {
  if $3; then return; fi

  if (! whiptail --title "🚀 $1 🚀" --yesno "Do you want to install '$1'?" --defaultno 9 60); then
    whiptail --title "❌ $1 ❌" --msgbox 'Installation canceled' 9 60
    return
  fi

  __log_separator__ "$1"

  # Download
  curl -fsSL "$2" -o /tmp/package.deb 2>> "${error}" &
  if ! __infobox_spinner__ $! "$1" 'Downloading'; then
    __error_handler__ "$1" 'Download (DEB) failure!'
  fi

  # Installation
  sudo apt-get install /tmp/package.deb -qq > /dev/null 2>> "${error}" &
  if ! __infobox_spinner__ $! "$1" 'Installing'; then
    __error_handler__ "$1" 'Installation failure!'
  fi

  # Cleanup
  rm /tmp/package.deb

  whiptail --title "✅ $1 ✅" --msgbox 'Installation completed' 9 60
}

#-------------------------------------------------------------------
# Check if a package is installed
#-------------------------------------------------------------------
# @arg $1 Package name
#
# @example
#   check_package curl
#-------------------------------------------------------------------
check_package() {
  if ! dpkg --get-selections | grep -wq "$1"; then
    echo false
  else
    echo true
  fi
}

#-------------------------------------------------------------------
# Check if file exists
#-------------------------------------------------------------------
# @arg $1 File path
#
# @example
#   check_file "${HOME}/path/to/file.txt"
#-------------------------------------------------------------------
check_file() {
  if [ ! -f "$1" ]; then
    echo false
  else
    echo true
  fi
}

#-------------------------------------------------------------------
# Check if directory exists
#-------------------------------------------------------------------
# @arg $1 Directory path
#
# @example
#   check_directory "${HOME}/path/to/directory"
#-------------------------------------------------------------------
check_directory() {
  if [ ! -d "$1" ]; then
    echo false
  else
    echo true
  fi
}

#-------------------------------------------------------------------
# Check if command exists
#-------------------------------------------------------------------
# @arg $1 Name of command
#
# @example
#   check_command anki
#-------------------------------------------------------------------
check_command() {
  if ! command -v "$1" > /dev/null; then
    echo false
  else
    echo true
  fi
}

#-------------------------------------------------------------------
# Helper that display a prompt about a required manual installation
#-------------------------------------------------------------------
# @arg $1 Name of package
# @arg $2 Message
# @arg $3 Installed?
# @arg $4 Scrollable?
#
# @example
#     show_manual_install "nvm" "${is_installed_nvm}" "${msg}"
#     show_manual_install "MySQL" "${is_installed_mysql}" "${msg}" true
#-------------------------------------------------------------------
show_manual_install(){
  if $3; then return; fi

  if [ -z "$4" ]; then
    whiptail --title "🔨 $1 🔨" --msgbox "$2" 11 60
  else
    whiptail --title "🔨 $1 🔨" --scrolltext --msgbox "$2" 11 60
  fi
}
