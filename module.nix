self: { lib, config, pkgs, ... }:

with lib;

let
  cfg = config.services.strichliste;
in {
  options = {
    services.strichliste = {
      enable = mkEnableOption "enable the strichliste";

      databaseUrl = mkOption {
        type = types.str;
      };

      configuration = mkOption {
        type = types.attrs;
        description = "See 'https://github.com/strichliste/strichliste-backend/blob/master/docs/Config.md' for details";
        default = {
          parameters.strichliste = {
            article = {
              enable = true;
              autoOpen = false;
            };

            common.idleTimeout = 30000;

            paypal = {
              enable = false;
              recipient = "foo@bar.de";
              fee = 0;
            };

            user.stalePeriod = "240 day";

            i18n = {
              dateFormat = "DD-MM-YYYY HH:mm:ss";
              timezone = "Europe/Berlin";
              language = "de";

              currency = {
                name = "Euro";
                symbol = "€";
                alpha3 = "EUR";
              };
            };

            account.boundary = {
              upper = 30000;
              lower = -10000;
            };

            payment = {
              undo = {
                enable = true;
                delete = false;
                timeout = "5 minute";
              };

              boundary = {
                upper = 30000;
                lower = -20000;
              };

              transaction.enabled = true;
              
              splitInvoice.enabled = true;

              deposit = {
                enabled = true;
                custom = true;
                steps = [
                  5
                  10
                  15
                  20
                  25
                  50
                  100
                ];
              };

              dispense = {
                enable = true;
                custom = true;
                steps = [
                  5
                  10
                  15
                  20
                  25
                  50
                  100
                ];
              };
            };
          };  
        };
      };

      configFile = mkOption {
        type = types.package;
        default = ( pkgs.formats.yaml {} ).generate "strichliste.yaml" cfg.configuration;
      };
    };
  };

  config = mkIf cfg.enable {

    virtualisation.oci-containers.backend = "podman";

    # Containers
    virtualisation.oci-containers.containers."strichliste" = {
      image = "fsim/strichliste-docker:latest";
      environment = {
        "APP_ENV" = "prod";
        "DATABASE_URL" = "mysql://strichliste:strichliste@strichliste-db/strichliste";
        "DB_HOST" = "strichliste-db";
      };
      volumes = [
        "${./conf/doctrine.yaml}:/source/config/packages/doctrine.yaml:rw"
        "${./conf/services.yaml}:/source/config/services.yaml:rw"
        "${cfg.configFile}:/source/config/strichliste.yaml:rw"
      ];
      ports = [
        "8080:8080/tcp"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=strichliste"
        "--network=strichliste_default"
      ];
    };
    systemd.services."podman-strichliste" = {
      serviceConfig = {
        Restart = lib.mkOverride 500 "no";
      };
      after = [
        "podman-network-strichliste_default.service"
      ];
      requires = [
        "podman-network-strichliste_default.service"
      ];
      partOf = [
        "podman-compose-strichliste-root.target"
      ];
      wantedBy = [
        "podman-compose-strichliste-root.target"
      ];
    };
    virtualisation.oci-containers.containers."strichliste-db" = {
      image = "mariadb:10.11.5";
      environment = {
        "MYSQL_DATABASE" = "strichliste";
        "MYSQL_PASSWORD" = "strichliste";
        "MYSQL_ROOT_PASSWORD" = "root";
        "MYSQL_USER" = "strichliste";
      };
      volumes = [
        "/home/ole/github/strichliste-docker/data/mysql:/var/lib/mysql:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=strichliste-db"
        "--network=strichliste_default"
      ];
    };
    systemd.services."podman-strichliste-db" = {
      serviceConfig = {
        Restart = lib.mkOverride 500 "always";
      };
      after = [
        "podman-network-strichliste_default.service"
      ];
      requires = [
        "podman-network-strichliste_default.service"
      ];
      partOf = [
        "podman-compose-strichliste-root.target"
      ];
      wantedBy = [
        "podman-compose-strichliste-root.target"
      ];
    };

    # Networks
    systemd.services."podman-network-strichliste_default" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f strichliste_default";
      };
      script = ''
        podman network inspect strichliste_default || podman network create strichliste_default
      '';
      partOf = [ "podman-compose-strichliste-root.target" ];
      wantedBy = [ "podman-compose-strichliste-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-strichliste-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
