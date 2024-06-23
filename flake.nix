{
  description = "A flake that generates a TFTP folder to serve Raspberry Pi clients with a NixOS image";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs, ... }@ inputs:
    let
      inherit (self) outputs;
      sshkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICvr2FrC9i1bjoVzg+mdytOJ1P0KRtah/HeiMBuKD3DX";
    in
    rec{
      nixosConfigurations.client = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs sshkey nixpkgs;
          systemname = "nixos";
          systemserial = "default"; # systemserial can also be set to "default" to boot any system that requests a netboot.
        };
        system = "x86_64-linux";
        modules = [
          {
            nixpkgs.config.allowUnsupportedSystem = true;
            nixpkgs.crossSystem.system = "aarch64-linux"; # Target system
          }

          ./genTFTP.nix # This file sets system.build.rpiTFTP to the derivation that generates the TFTP folder.

          ./client/config.nix
          ./client/hardware.nix # Shared hardware configuration for Raspberry Pis
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix" # Base system - various utilities.
        ];
      };
      nixosModules.default = { config }: { imports = [ "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix" ./genTFTP.nix ]; };
      TFTPFolder = nixosConfigurations.client.config.system.build.rpiTFTP;
      NFSFolder = nixosConfigurations.client.config.system.build.sdImage;
    };
}

