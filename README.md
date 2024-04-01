<h1 align="center">pkgubuntu</h1>

<p align="center">
    Whiptail based software intaller for Ubuntu based systems
</p>

## Description

CLI tool for installing whatever software you like with (somewhat) ease

## Usage

### Check if package is installed

You can check if a software, cli tool, package, whatever... is installed via these functions:

- `check_package()` (via `dpkg`)
- `check_file()`
- `check_directory()`
- `check_command()` (via `command`)

### Add your software to the list

You can place your software by adding them to the associative array `software_check` located in `includes/software.sh`:

- The `key` is the package name *(lower-kebab-case)*
- The `value` is how the script will check the installation status of the software *(see step above*)
```shell
local nvm_dir="${HOME}/.config/nvm"

software_check[neofetch]='check_package'
software_check[nvm]="check_directory '${nvm_dir}'"
```
> Note: Surround the variable with single quotes `'${var}'` in case the string contains spaces

### Install your software

You can install your software **calling the following functions** inside `installation()` located in `includes/software.sh` and the help of an associative array called `$is_installed`:

> `$is_installed` is an associative array with the installation status of every software you add in the previous step

#### `install_standard()`

Syntax
- `$1`: Human-readable name of the package
- `$2`: Name of the package
- `$3`: Installed?

Example

```shell
install_standard "Yakuake" "yakuake" "${is_installed[yakuake]}"
```

#### `install_PPA()`

Syntax
- `$1`: Human-readable name of the package
- `$2`: Name of the package
- `$3`: PPA
- `$4`: Installed?

Example

```shell
install_PPA "GIT" "git" "ppa:git-core/ppa" "${is_installed[git]}"
```

#### `install_deb()`

Syntax
- `$1`: Human-readable name of the package
- `$2`: URL of DEB file
- `$3`: Installed?

Example

```shell
local code_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
install_deb "VSCode" "${code_url}" "${is_installed[code]}"
```
## Custom installation process

You can place custom installation processes in the `include/custom.sh` script.

1. Create a function with the following name structure: `install_<name-kebab-case>()`
2. Use the `install_anki()` function as an example.
3. Add your software name to the [list](#add-your-software-to-the-list)
4. Place your newly created function in the [`installation()` function](#install-your-software)
    ```shell
    # Anki
    install_anki "${is_installed[anki]}"
    ```

## Example

`include/software.sh`

```shell
check_software() {
  local nvm_dir="${HOME}/.config/nvm"

  software_check[neofetch]='check_package'
  software_check[nvm]="check_directory '${nvm_dir}'"
  software_check[qbittorrent]='check_package'
  software_check[code]='check_package'

  #...
}

installation() {
  # ...

  # neofetch (System Info)
  install_standard "neofetch" "neofetch (System Info)" "${is_installed[neofetch]}"

  # qBitorrent
  install_PPA "qbittorrent" "qBittorrent" "ppa:qbittorrent-team/qbittorrent-stable" "${is_installed[qbittorrent]}"

  # VSCode
  local code_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
  install_deb "VSCode" "${code_url}" "${is_installed[code]}"

  # Custom installation
  # nvm
  install_nvm "${is_installed[nvm]}"
}
```

`include/custom.sh`

```shell
install_nvm(){
  if $1; then return; fi

  if (! whiptail --title '🚀 nvm 🚀' --yesno "Do you want to install 'nvm'?" --defaultno 9 60); then
    whiptail --title '❌ nvm ❌' --msgbox "Installation canceled" 9 60
  fi

  __log_separator__ 'nvm'

  # ...

  whiptail --title "✅ nvm ✅" --msgbox "Installation completed" 9 60
}
```
