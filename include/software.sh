#!/usr/bin/env bash

declare -A is_installed

#-------------------------------------------------------------------
# Store installation statuses in the '$is_installed' array
#-------------------------------------------------------------------
# Here, you can list the programs and their corresponding way to
# check their statuses with the help of '$software_check' array
#-------------------------------------------------------------------
check_software() {
  declare -A software_check

  local xampp_dir='/opt/lampp'

  software_check[google-chrome]='check_package'
  software_check[okular-extra-backends]='check_package'
  software_check[dolphin-plugins]='check_package'
  software_check[mpv]='check_package'
  software_check[abd]='check_package'
  software_check[scrcpy]='check_package'
  software_check[neofetch]='check_package'
  software_check[gromit-mpx]='check_package'
  software_check[screenkey]='check_package'
  software_check[xampp]="check_directory '${xampp_dir}'"
  software_check[veracrypt]='check_package'
  software_check[qbittorrent]='check_package'
  software_check[obs-studio]='check_package'
  software_check[anki]="check_command anki"

  for key in "${!software_check[@]}"; do
    local value="${software_check[$key]}"

    if [[ "${value}" != "check_package"* ]]; then
      is_installed["${key}"]=$(eval "${value}")
    else
      is_installed["${key}"]=$(eval "${value}" "${key}")
    fi
  done
}

#-------------------------------------------------------------------
# Install any software specified
#-------------------------------------------------------------------
# Here, you will use the status of the software you want to intall
# stored in the '$is_installed' associative array
#-------------------------------------------------------------------
installation() {
  local chrome_deb="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
  local msg=

  # Google Chrome
  install_deb "Google Chrome" "${chrome_deb}" "${is_installed[google-chrome]}"

  # Okular Backends (Format support)
  install_standard "okular-extra-backends" "Okular Backends (Format support)" "${is_installed[okular-extra-backends]}"

  # Dolphin Plugins
  install_standard "dolphin-plugins" "Dolphin Plugins" "${is_installed[dolphin_plugins]}"

  # mpv (Music Player)
  install_standard "mpv" "mpv (Music Player)" "${is_installed[mvp]}"

  # adb (Android USB Debugging)
  install_standard "adb" "adb (Android USB Debugging)" "${is_installed[adb]}"

  # scrcpy (Android on screen)
  install_standard "scrcpy" "scrcpy (Android on screen)" "${is_installed[scrcpy]}"

  # neofetch (System Info)
  install_standard "neofetch" "neofetch (System Info)" "${is_installed[neofetch]}"

  # gromit-mpx
  install_standard "gromit-mpx" "Gromit MPX (Draw on screen)" "${is_installed[gromit-mpx]}"

  # screenkey
  install_standard "screenkey" "screenkey" "${is_installed[screenkey]}"

  # XAMPP
  msg="Manual installation required:\n\nVisit: https://sourceforge.net/projects/xampp/files/latest/download"
  show_manual_install "XAMPP" "${msg}" "${is_installed[xampp]}"

  # Veracrypt
  msg="Manual installation required:\n\nVisit: https://www.veracrypt.fr/en/Downloads.html"
  show_manual_install "VeraCrypt" "${msg}" "${is_installed[veracrypt]}"

  # qBitorrent
  install_PPA "qbittorrent" "qBittorrent" "ppa:qbittorrent-team/qbittorrent-stable" "${is_installed[qbittorrent]}"

  # OBS Studio
  install_PPA "obs-studio" "OBS Studio" "ppa:obsproject/obs-studio" "${is_installed[obs-studio]}"

  # Anki
  install_anki "${is_installed[anki]}"
}

#-------------------------------------------------------------------
# Display a list of software statuses
#-------------------------------------------------------------------
pre_installation() {
  local string='Do you want to continue with the installation?\n\n'

  for key in "${!is_installed[@]}"; do
    string+="$(${is_installed[$key]} && echo ✅ || echo ❌) ${key}\n"
  done

  whiptail --title "Installed software" --scrolltext --yesno "${string}" --yes-button "Continue" \
  --no-button "Exit" --defaultno 15 80
}
