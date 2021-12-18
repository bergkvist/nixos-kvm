let
    pkgs = import <nixpkgs> {};
in pkgs.mkShell {
    buildInputs = [
        pkgs.qemu
        pkgs.python3
        pkgs.iproute2
    ];
}