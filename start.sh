#!/bin/sh
RELEASE="21.11"
EDITION="plasma5"
ARCH="x86_64-linux"
VERSION="334534.2627c4b7951"
ISO_NAME="nixos-$EDITION-$RELEASE.$VERSION-$ARCH.iso"
ISO_URL="https://releases.nixos.org/nixos/$RELEASE/nixos-$RELEASE.$VERSION/$ISO_NAME"

DISK_NAME="nixos.img"
DISK_SIZE="120G"
MEMORY_MB="32768"
CPU_OPTIONS="+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check"
CPU_SOCKETS="1"
CPU_CORES="12"
CPU_THREADS="24"

# Download NixOS ISO if it does not exist
[ -f "$ISO_NAME" ] || wget "$ISO_URL"
# Create disk image if it does not exist
[ -f "$DISK_NAME" ] || qemu-img create -f qcow2 "$DISK_NAME" "$DISK_SIZE"

# First time setup/installation
if [ "$1" = "install" ]; then
    qemu-system-x86_64 -enable-kvm -m "$MEMORY_MB" -boot d -cdrom "$ISO_NAME" -hda "$DISK_NAME"
elif [ "$1" = "boot" ]; then
    qemu-system-x86_64 -enable-kvm -m "$MEMORY_MB" -boot a -hda "$DISK_NAME" \
        -bios /usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
        -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,"$CPU_OPTIONS" \
        -smp "$CPU_THREADS",cores="$CPU_CORES",sockets="$CPU_SOCKETS" \
        -chardev spicevmc,id=ch1,name=vdagent \
        -device virtio-serial-pci \
        -device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0 \
        -netdev user,id=net0,hostfwd=tcp::1022-:22 \
        -vga virtio
else
    echo "Usage: $0 <OPTION>"
    echo "  Valid options (OPTION):"
    echo "    install"
    echo "      Mount $ISO_NAME in order to install NixOS $RELEASE"
    echo "    boot"
    echo "      Regular boot from nixos.img (Note that you need to install NixOS before you can do this)"
    exit 1
fi



# args=(
#  -enable-kvm
#  -usb
#  -m "8096"
#  -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,"$MY_OPTIONS"
#  -machine q35
#  -smp "$CPU_THREADS",cores="$CPU_CORES",sockets="$CPU_SOCKETS"
#  -smbios type=2
#  -monitor stdio
#  -device usb-kbd
#  -device usb-tablet
#  -device usb-ehci,id=ehci
#  -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
#  -device ich9-intel-hda
#  -device hda-duplex
#  -device ich9-ahci,id=sata
#  -device VGA,vgamem_mb=128
#  -device ide-hd,bus=sata.2,drive=OpenCoreBoot
#  -device ide-hd,bus=sata.3,drive=InstallMedia
#  -device ide-hd,bus=sata.4,drive=MacHDD
#  -device vmxnet3,netdev=net0,id=net0,mac=52:54:00:c9:18:27
#  -netdev user,id=net0,hostfwd=tcp::3222-:22
#  -drive if=pflash,format=raw,readonly,file="./data/OVMF_CODE.fd"
#  -drive if=pflash,format=raw,file="./data/OVMF_VARS-1024x768.fd"
#  -drive id=OpenCoreBoot,if=none,snapshot=on,format=qcow2,file="./data/OpenCore.qcow2"
#  -drive id=InstallMedia,if=none,file="./data/BaseSystem.img",format=raw
#  -drive id=MacHDD,if=none,file="./data/mac_hdd_ng.img",format=qcow2
# )

# qemu-system-x86_64 "${args[@]}"