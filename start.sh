#!/bin/sh
main() {
    release="21.11"
    edition="plasma5"
    arch="x86_64-linux"
    version="334534.2627c4b7951"
    iso_name="nixos-$edition-$release.$version-$arch.iso"
    iso_url="https://releases.nixos.org/nixos/$release/nixos-$release.$version/$iso_name"

    disk_name="nixos.img"
    disk_size="120G"
    memory_size="32G"
    cpu_options="+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check"
    cpu_sockets="1"
    cpu_cores="12"
    cpu_threads="24"

    boot_mode="$1"
    host_os="$(uname)"
    host_ovmf_code="/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"

    case "$boot_mode" in
        install);;
        boot);;
        *)
        echo "Usage: $0 <OPTION>"
        echo "  Valid options (OPTION):"
        echo "    install"
        echo "      Mount $iso_name in order to install NixOS $release"
        echo "    boot"
        echo "      Regular boot from nixos.img (Note that you need to install NixOS before you can do this)"
        exit 1
        ;;
    esac
    [ -f "$iso_name" ] || {
        echo "Downloading NixOS ISO $iso_name..."
        wget "$iso_url"
    }
    [ -f "$disk_name" ] || {
        echo "Creating disk image $disk_name ($disk_size)..."
        qemu-img create -f qcow2 "$disk_name" "$disk_size"
    }

    eval "set -- \
        $(boot_args "$boot_mode" "$disk_name" "$iso_name" "$host_ovmf_code") \
        $(cpu_args "$host_os" "$cpu_sockets" "$cpu_cores" "$cpu_threads" "$cpu_options") \
        $(shared_folder_args "host0" "$PWD/shared")
    "

    qemu-system-x86_64 -m "$memory_size" "$@" \
        -chardev spicevmc,id=ch1,name=vdagent \
        -device virtio-serial-pci \
        -device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0 \
        -vga virtio
}

boot_args() {
    mode="$1"
    disk_name="$2"
    iso_name="$3"
    ovmf_code="$4"
    case "$mode" in
        install) save -boot d -cdrom "$iso_name" -hda "$disk_name";;
        boot) save -boot a -hda "$disk_name" -bios "$ovmf_code";;
        *) die "Invalid boot mode: $mode";;
    esac
}

cpu_args() {
    host_os="$1"
    sockets="$2"
    cores="$3"
    threads="$4"
    cpu_options="$5"
    case "$host_os" in
        Linux) save \
            -enable-kvm \
            -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,"$cpu_options" \
            -smp "$threads,cores=$cores,sockets=$sockets"
        ;;
        Darwin) save \
            -accel hvf \
            -cpu Penryn,vendor=GenuineIntel,vmware-cpuid-freq=on,"$cpu_options" \
            -smp "$threads,cores=$cores,sockets=$sockets";;
        *) die "Unsupported OS: $host_os";;
    esac
}

shared_folder_args() {
    # To mount manually in guest: 
    # mkdir -p /mnt/shared && mount -t 9p -o trans=virtio,version=9p2000.L <name> /mnt/shared
    # fstab entry
    # host0   /mnt/shared    9p      trans=virtio,version=9p2000.L   0 0
    name="$1"
    shared_folder="$2"
    save -virtfs "local,path=$shared_folder,mount_tag=$name,security_model=passthrough,id=$name"
}

named_usb_args() {
    [ -z "$1" ] && die "Usage: qemu_usb <SEARCH_TERM>"
    usb=$(lsusb | grep "$1")
    [ -z "$usb" ] && die "Did not find USB with name \"$1\". Please make sure the device is connected."
    bus=$(echo "$usb" | sed 's/.*Bus \([^ ]*\) Device.*/\1/' | sed 's/^0*//')
    device=$(echo "$usb" | sed 's/.*Device \([^ ]*\): ID.*/\1/' | sed 's/^0*//')
    port=$(lsusb -t | awk "/Bus $(printf '%02d' "$bus")/{seen=1};seen{print}" \
                    | grep "Dev $((device))" | head -n1 | sed 's/.*Port \([^ ]*\): Dev.*/\1/')
    save -device usb-host,hostbus=$((bus)),hostport=$((port))
}

save() {
    for i do printf %s\\n "$i" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' \\\\/" ; done
    echo " "
}

die() { echo "$@" 1>&2; exit 1; }

main "$@"