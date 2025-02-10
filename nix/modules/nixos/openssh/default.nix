{
    # Snowfall Lib provides a customized `lib` instance with access to your flake's library
    # as well as the libraries available from your flake's inputs.
    lib,
    # An instance of `pkgs` with your overlays and packages applied is also available.
    pkgs,
    # You also have access to your flake's inputs.
    inputs,

    # Additional metadata is provided by Snowfall Lib.
    namespace, # The namespace used for your flake, defaulting to "internal" if not set.
    system, # The system architecture for this host (eg. `x86_64-linux`).
    target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
    format, # A normalized name for the system target (eg. `iso`).
    virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
    systems, # An attribute map of your defined hosts.

    # All other arguments come from the module system.
    config,
    ...
}:
let 
cfg = config.courier.openssh;
in 
{
  options = {
      courier.openssh = {
        enable = lib.mkEnableOption;
        };
    };
    config = lib.mkIf cfg.enable {
    networking.firewall.extraCommands = mkIf cfg.listenIPv6Only (concatStringsSep "\n" [
      "ip6tables -A INPUT -s ::/0 -d ::/0 -p tcp --dport 22 -j ACCEPT"
    ]);
    services.openssh = {
      enable = true;
      settings = {
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];

        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group14-sha256"
        ];

        HostKeyAlgorithms = concatStringsSep "," [
          "ssh-ed25519"
          "rsa-sha2-512"
          "rsa-sha2-256"
        ];

        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
          "aes256-ctr"
          "aes192-ctr"
          "aes128-ctr"
        ];

        # Harden
        StreamLocalBindUnlink = "yes";
        PermitRootLogin = mkForce "prohibit-password";
        PasswordAuthentication = mkForce false;
        PubkeyAuthentication = true;
        ChallengeResponseAuthentication = false;
        KerberosAuthentication = false;
        GSSAPIAuthentication = false;
        KbdInteractiveAuthentication = mkForce false;

        Protocol = 2;

        UseDns = true;

        IgnoreRhosts = true;
        PermitEmptyPasswords = false;
        MaxAuthTries = 3;
        MaxSessions = 2;
        ClientAliveCountMax = 2;

        X11Forwarding = false;
        AllowTcpForwarding = mkDefault true;
        AllowAgentForwarding = mkDefault false;
        PermitTunnel = mkDefault false;

        AllowGroups = [
          "root"
          "wheel"
        ];
      };
    };

    programs.ssh = {
      macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];

      kexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group14-sha256"
      ];

      hostKeyAlgorithms = [
        "ssh-ed25519"
        "rsa-sha2-512"
        "rsa-sha2-256"
      ];

      ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-ctr"
      ];
      # Each hosts public key
      #      knownHosts =
      #        mapAttrs'
      #        (name: _:
      #          nameValuePair (FQDN name) {
      #            publicKeyFile = pubKey name;
      #            extraHostNames =
      #              lib.optional (name == hostName) "localhost";
      #          })
      #        hosts;
    };

    users.users =
      {
        root.openssh.authorizedKeys.keys = [(builtins.readFile (USER_SSHPUB_PATH "waffle"))];
#TODO make pub ssh key (easy, just whip up "ssh-keygen" it just does it there are a bounch of settings but don't bother it doesn't matter who even cares, just make sure it is an ed-25519, but actuallyjust google it you dumbass)

      }
      // userKeys;

    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = [
        "/etc/ssh/authorized_keys.d/%u"
      ];
    };
    security.sudo.wheelNeedsPassword = mkDefault false;
  };
};
