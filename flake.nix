{
  description = "ZFS Replicate Utility";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-utils.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          defaultPackage = import ./nix/default.nix { inherit pkgs; };
        }
      )
    // {
      nixosModule = { config, pkgs, lib, ... }:
        with lib;
        let
          cfg = config.services.zfs.autoReplication;
          recursive = optionalString cfg.recursive " --recursive";
          followDelete = optionalString cfg.followDelete " --follow-delete";
          sshPath = optionalString (cfg.sshPath != null) " --ssh-path ${escapeShellArg cfg.sshPath}";
          zfs-replicate-bin = "${self.defaultPackage.${pkgs.system}}/bin/zfs-replicate";
        in
        {
          options = {
            services.zfs.autoReplication = {
              enable = mkEnableOption "ZFS snapshot replication.";

              followDelete = mkOption {
                description = "Remove remote snapshots that don't have a local correspondant.";
                default = true;
                type = types.bool;
              };

              host = mkOption {
                description = "Remote host where snapshots should be sent. <literal>lz4</literal> is expected to be installed on this host.";
                example = "example.com";
                type = types.str;
              };

              identityFilePath = mkOption {
                description = "Path to SSH key used to login to host.";
                example = "/home/username/.ssh/id_rsa";
                type = types.path;
              };

              sshPath = mkOption {
                description = "Path to SSH executable to use.";
                example = "\${pkgs.openssh}/bin/ssh";
                type = types.path;
              };

              execStartPre = mkOption {
                description = "Command to run as ExecStartPre";
                example = "\${pkgs.openssh}/bin/ssh host nixos-rebuild switch";
                type = types.str;
              };

              timeout = mkOption {
                description = "Timeout in seconds for the service";
                example = "180";
                type = types.int;
              };

              localFilesystem = mkOption {
                description = "Local ZFS fileystem from which snapshots should be sent.  Defaults to the attribute name.";
                example = "pool/file/path";
                type = types.str;
              };

              remoteFilesystem = mkOption {
                description = "Remote ZFS filesystem where snapshots should be sent.";
                example = "pool/file/path";
                type = types.str;
              };

              recursive = mkOption {
                description = "Recursively discover snapshots to send.";
                default = true;
                type = types.bool;
              };

              username = mkOption {
                description = "Username used by SSH to login to remote host.";
                example = "username";
                type = types.str;
              };
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [
              pkgs.lz4
            ];

            systemd.services.zfs-replication = {
              after = [
                "zfs-snapshot-daily.service"
                "zfs-snapshot-frequent.service"
                "zfs-snapshot-hourly.service"
                "zfs-snapshot-monthly.service"
                "zfs-snapshot-weekly.service"
              ];
              description = "ZFS Snapshot Replication";
              documentation = [
                "https://github.com/alunduil/zfs-replicate"
              ];
              restartIfChanged = false;
              serviceConfig.ExecStartPre = toString cfg.execStartPre;
              serviceConfig.ExecStart = "${zfs-replicate-bin}${recursive} -l ${escapeShellArg cfg.username} -i ${escapeShellArg cfg.identityFilePath}${followDelete}${sshPath} ${escapeShellArg cfg.host} ${escapeShellArg cfg.remoteFilesystem} ${escapeShellArg cfg.localFilesystem}";
              serviceConfig.TimeoutSec = toString cfg.timeout;
              wantedBy = [
                "zfs-snapshot-daily.service"
                "zfs-snapshot-frequent.service"
                "zfs-snapshot-hourly.service"
                "zfs-snapshot-monthly.service"
                "zfs-snapshot-weekly.service"
              ];
            };
          };

          meta = {
            maintainers = with lib.maintainers; [ alunduil ];
          };
        };
    };
}
