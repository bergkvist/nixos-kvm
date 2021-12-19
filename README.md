# nixos-kvm
Install and run NixOS inside a virtual machine (QEMU x86-64)
## Starting the VM
```
nix-shell ./shell.nix
./start.sh boot
```

## Installation/setup
```sh
git clone https://github.com/bergkvist/nixos-kvm
cd nixos-kvm
nix-shell
./start.sh install
```

### Installing NixOS on your virtual disk
```
$ sudo -i
# setxkbmap no

# parted /dev/sda
(parted) mklabel gpt
(parted) mkpart primary 512MiB 100%
(parted) mkpart ESP fat32 1MiB 512MiB
(parted) set 2 esp on
(parted) quit
# mkfs.ext4 -L nixos /dev/sda1
# mkfs.fat -F 32 -n boot /dev/sda2

# mount /dev/disk/by-label/nixos /mnt
# mkdir -p /mnt/boot
# mount /dev/disk/by-label/boot /mnt/boot

# nixos-generate-config --root /mnt
# vim /mnt/etc/nixos/configuration.nix

# nixos-install
-- set password --

# shutdown now
```

```nix
{
  # ...
  boot.loader.systemd-boot.enable = true;
  # ...
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    firefox
    insomnia
    vscode
    gitkraken
    gcc
    gnumake
    cmake
    automake
    autoconf
    python3
    perl
  ];
  # ...
}
```
