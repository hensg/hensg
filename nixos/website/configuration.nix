{ modulesPath
, pkgs
, hugo-site
, system
, ...
}:
let
  keys = import ../keys;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk.nix
  ];

  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        enableCryptodisk = true;
        device = "/dev/sda";
      };
    };

    initrd = {
      availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
    };
  };

  services.resolved.enable = true;

  environment.systemPackages = with pkgs; [
    curl
    gitMinimal
    neovim
    hugo-site.packages.${system}.website
  ];

  users.users.root.openssh.authorizedKeys.keys = keys.authorizedKeys;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    allowSFTP = false;
  };

  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    enable = true;
  };


  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."hensg.dev" = {
      forceSSL = true;
      enableACME = true;

      sslCertificate = "/var/lib/acme/hensg.dev/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/hensg.dev/key.pem";

      root = "${hugo-site.packages.${system}.website}";
    };
  };

  security.acme = {
    acceptTerms = true;
    certs = {
      "hensg.dev".email = "henriquedsg89@gmail.com";
    };
  };

  system.stateVersion = " 24.05 ";
}
