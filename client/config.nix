{ pkgs, config, sshkey, lib, ... }:

{
  # Required for the Wireless firmware
  hardware.enableRedistributableFirmware = lib.mkForce true;

  boot.initrd.supportedFilesystems = [ "nfs" "nfsv4" "overlay" ];
  boot.initrd.availableKernelModules = [ "nfs" "nfsv4" "overlay" "bcm_phy_lib" "broadcom" "genet" ];
  boot.initrd.kernelModules = [ "nfs" "nfsv4" "overlay" "bcm_phy_lib" "broadcom" "genet" ];
  fileSystems."/nix/.ro-store" = lib.mkImageMediaOverride
    {
      fsType = lib.mkForce "nfs4";
      device = lib.mkForce "192.168.1.1:/nix-store";
      options = lib.mkForce [ "ro" ];
      neededForBoot = lib.mkForce true;
    };
  fileSystems."/var/lib/containers" = lib.mkImageMediaOverride
    {
      fsType = lib.mkForce "nfs4";
      device = lib.mkForce "192.168.1.1:/podman";
      options = lib.mkForce [ "rw" ];
      neededForBoot = lib.mkForce true;
    };
  boot.initrd.network.enable = lib.mkForce true;
  boot.initrd.network.flushBeforeStage2 = lib.mkForce false;
  networking.useDHCP = lib.mkForce true;

  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      volumes = [ "home-assistant:/config" "/run/dbus:/run/dbus:ro" ];
      environment.TZ = "Europe/Berlin";
      image = "ghcr.io/home-assistant/home-assistant:stable"; # Warning: if the tag does not change, the image will not be updated
      extraOptions = [
        "--network=host"
      ];
    };
  };

  # For homeassistant
  hardware.bluetooth.enable = lib.mkForce true;
  services.dbus.implementation = "broker";

  # Hostname.
  networking = {
    hostName = "hassio";
  };

  # Allow SSH from authorized keys.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
    permitRootLogin = "yes";
  };

  users.users.root.openssh.authorizedKeys.keys = [ sshkey ];
  users.users.headb.openssh.authorizedKeys.keys = [ sshkey ];

  # Add the users.
  users.users.headb = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };


  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "end0" ];
    extraCommands = ''
      iptables -A nixos-fw -p tcp --source 192.168.1.0/24 --dport 0:25565 -j nixos-fw-accept
      iptables -A nixos-fw -p udp --source 192.168.1.0/24 --dport 0:25565 -j nixos-fw-accept
    '';
  };

  system.stateVersion = "23.05";
}
