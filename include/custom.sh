#!/usr/bin/env bash

install_anki(){
  if $1; then return; fi

  if (! whiptail --title '🚀 Anki 🚀' --yesno "Do you want to install 'Anki'?" --defaultno 9 60); then
    whiptail --title '❌ Anki ❌' --msgbox "Installation canceled" 9 60
  fi

  __log_separator__ 'Anki'

  anki_url="https://api.github.com/repos/ankitects/anki/releases/latest"

  local final_url
  local file_name

  final_url=$(curl -s "${anki_url}" | jq -r '.assets[2].browser_download_url')
  file_name=$(curl -s "${anki_url}" | jq -r '.assets[2].name')

  # Download
  # shellcheck disable=SC2154
  curl -fsSL "${final_url}" -o "/tmp/${file_name}" 2>> "${error}" &
  if ! __infobox_spinner__ $! 'Anki' 'Downloading Anki'; then
    __error_handler__ 'Anki' 'Download failure!'
  fi

  mkdir -p "/tmp/anki"

  # Decompress
  tar xaf "/tmp/${file_name}" -C "/tmp/anki" --strip-components=1 2>> "${error}" &
  if ! __infobox_spinner__ $! 'Anki' 'Decompressing Anki'; then
    __error_handler__ 'Anki' 'Decompression failure!'
  fi

  # Installation
  if [ ! -f "/tmp/anki/install.sh" ];then
    echo "E: /tmp/anki/install.sh file not found" >> "${error}"
    __error_handler__ 'Anki'
  fi

  cd /tmp/anki 2>> "${error}" || return
  sudo ./install.sh > /dev/null 2>> "${error}" &
  if ! __infobox_spinner__ $! 'Anki' 'Installing Anki'; then
    echo "E: /tmp/anki/install.sh something went wrong!" >> "${error}"
    __error_handler__ 'Anki' 'Installation failure!'
  fi

  # shellcheck disable=SC2154
  cd "${init_dir}" 2>> "${error}" || return

  whiptail --title "✅ Anki ✅" --msgbox "Installation completed" 9 60
}
