self: {
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.services.strichliste;
  inherit (lib)
    mkEnableOption
    types
    mkOption
    mkIf
    ;

  mkSubmoduleOption =
    sub-cfg:
    mkOption {
      default = { };
      type = types.submodule {
        options = sub-cfg;
      };
    };
in
{
  options = {
    services.strichliste = {
      enable = mkEnableOption "the strichliste";

      settings = mkSubmoduleOption {
        article = mkSubmoduleOption {
          enabled = mkOption {
            type = types.bool;
            default = true;
          };
          autoOpen = mkOption {
            type = types.bool;
            default = false;
          };
        };

        common = mkSubmoduleOption {
          idleTimeout = mkOption {
            type = types.ints.u32;
            description = "Timeout in milliseconds to return to the main screen";
            default = 30000;
          };
        };

        paypal = mkSubmoduleOption {
          enabled = mkEnableOption "paypal payment feature";
          recipient = mkOption {
            type = types.nullOr types.str;
            description = "Recipient mail Address (paypal account)";
            default = null;
          };
          fee = mkOption {
            type = types.ints.u8;
            description = "Fee in percent (is added to the users balance)";
            default = 0;
          };
        };

        user = mkSubmoduleOption {
          stalePeriod = mkOption {
            type = types.str;
            description = "Determines, when a user is considered 'inactive'";
            default = "10 day";
          };
        };

        i18n = mkSubmoduleOption {
          dateFormat = mkOption {
            type = types.str;
            description = "Date format";
            default = "YYYY-MM-DD";
          };

          timezone = mkOption {
            type = types.str;
            description = "Timezone";
            default = "auto";
          };

          language = mkOption {
            type = types.str;
            description = "Language";
            default = "en";
          };

          currency = mkSubmoduleOption {
            name = mkOption {
              type = types.str;
              description = "Currency";
              default = "Euro";
            };

            symbol = mkOption {
              type = types.str;
              description = "Currency Symbol";
              default = "€";
            };

            alpha3 = mkOption {
              type = types.str;
              description = "Alpha3 format for currency";
              default = "EUR";
            };
          };
        };

        account = mkSubmoduleOption {
          boundary = mkSubmoduleOption {
            upper = mkOption {
              type = types.int;
              description = "Upper account limit";
              default = 200000;
            };

            lower = mkOption {
              type = types.int;
              description = "Lower account limit";
              default = -20000;
            };
          };
        };

        payment = mkSubmoduleOption {
          undo = mkSubmoduleOption {
            enabled = mkOption {
              type = types.bool;
              description = "Enable / Disable the undo feature";
              default = true;
            };
            delete = mkOption {
              type = types.bool;
              description = "Delete or mark transaction as deleted on undo";
              default = false;
            };

            timeout = mkOption {
              type = types.str;
              description = "Period how long you're able to undo the transaction";
              default = "5 minute";
            };
          };

          boundary = mkSubmoduleOption {
            upper = mkOption {
              type = types.int;
              description = "Upper transaction limit";
              default = 15000;
            };

            lower = mkOption {
              type = types.int;
              description = "Lower transaction limit";
              default = -2000;
            };
          };

          transactions = mkSubmoduleOption {
            enabled = mkOption {
              type = types.bool;
              description = "Enable / Disable sending money";
              default = true;
            };
          };

          splitInvoice = mkSubmoduleOption {
            enabled = mkOption {
              type = types.bool;
              description = "Enable / Disable the ability to split invoices";
              default = true;
            };
          };

          deposit = mkSubmoduleOption {
            enabled = mkOption {
              type = types.bool;
              description = "Enable / Disable quick money pay in";
              default = true;
            };

            custom = mkOption {
              type = types.bool;
              description = "Enable / Disable the ability to deposit custom amounts";
              default = true;
            };

            steps = mkOption {
              type = types.listOf types.ints.unsigned;
              description = "Available payment steps";
              default = [
                500
                1000
                1500
                2000
                2500
                5000
                10000
              ];
            };
          };

          dispense = mkSubmoduleOption {
            enabled = mkOption {
              type = types.bool;
              description = "Enable / Disable quick expenditure";
              default = true;
            };

            custom = mkOption {
              type = types.bool;
              description = "Enable / Disable the ability to expend custom amounts";
              default = true;
            };

            steps = mkOption {
              type = types.listOf types.ints.unsigned;
              description = "Available expenditure steps";
              default = [
                500
                1000
                1500
                2000
                2500
                5000
                10000
              ];
            };
          };
        };
      };

      configFile = mkOption {
        type = types.package;
        default = (pkgs.formats.yaml { }).generate "strichliste.yaml" {
          parameters.strichliste = cfg.settings;
        };
      };

      databaseDir = mkOption {
        type = types.str;
        description = "The directory to store the database in";
      };

      port = mkOption {
        type = types.port;
        description = "The port to expose the strichliste on";
        default = 8080;
      };
    };
  };

  config =
    let
      database-url = "mysql://root:root@strichliste-db/strichliste";
      default-conf = pkgs.substituteAll {
        src = ./conf/default.conf;

        databaseUrl = database-url;
      };

      oci-backend = config.virtualisation.oci-containers.backend;
    in
    mkIf cfg.enable {

      # Containers
      virtualisation.oci-containers.containers."strichliste" = {
        image = "strichliste:nix-v1";
        imageFile = (import ./docker-image.nix { inherit pkgs config; });
        environment = {
          "APP_ENV" = "prod";
          "DATABASE_URL" = database-url;
          "DB_HOST" = "strichliste-db";
        };
        volumes = [
          # "${./conf/doctrine.yaml}:/source/config/packages/doctrine.yaml:rw"
          # "${./conf/services.yaml}:/source/config/services.yaml:rw"
          "${cfg.configFile}:/source/config/strichliste.yaml:rw"
          # "${default-conf}:/etc/nginx/conf.d/default.conf"
        ];
        ports = [ "${toString cfg.port}:8080/tcp" ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=strichliste"
          "--network=strichliste_default"
        ];
      };
      systemd.services."${oci-backend}-strichliste" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "no";
        };
        after = [ "${oci-backend}-network-strichliste_default.service" ];
        requires = [ "${oci-backend}-network-strichliste_default.service" ];
        partOf = [ "${oci-backend}-compose-strichliste-root.target" ];
        wantedBy = [ "${oci-backend}-compose-strichliste-root.target" ];
      };
      virtualisation.oci-containers.containers."strichliste-db" = {
        image = "mariadb:10.11.5";
        environment = {
          "MYSQL_DATABASE" = "strichliste";
          # "MYSQL_PASSWORD" = "strichliste";
          "MYSQL_ROOT_PASSWORD" = "root";
          # "MYSQL_ALLOW_EMPTY_PASSWORD" = "yes";
          # "MYSQL_USER" = "strichliste";
          "MARIADB_AUTO_UPGRADE" = "true";
        };
        volumes = [ "${cfg.databaseDir}:/var/lib/mysql:rw" ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=strichliste-db"
          "--network=strichliste_default"
        ];
      };
      systemd.services."${oci-backend}-strichliste-db" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };
        after = [ "${oci-backend}-network-strichliste_default.service" ];
        requires = [ "${oci-backend}-network-strichliste_default.service" ];
        partOf = [ "${oci-backend}-compose-strichliste-root.target" ];
        wantedBy = [ "${oci-backend}-compose-strichliste-root.target" ];
      };

      # Networks
      systemd.services."${oci-backend}-network-strichliste_default" = {
        path = [
          pkgs.${oci-backend}
          pkgs.git
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${oci-backend} network rm -f strichliste_default";
        };
        script = ''
          ${oci-backend} network inspect strichliste_default || ${oci-backend} network create strichliste_default
        '';
        partOf = [ "${oci-backend}-compose-strichliste-root.target" ];
        wantedBy = [ "${oci-backend}-compose-strichliste-root.target" ];
      };

      # Root service
      # When started, this will automatically create all resources and start
      # the containers. When stopped, this will teardown all resources.
      systemd.targets."${oci-backend}-compose-strichliste-root" = {
        unitConfig = {
          Description = "Root target generated by compose2nix.";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
