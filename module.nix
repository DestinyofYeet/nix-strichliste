self: {
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  recursiveMerge = listOfAttrsets:
    lib.fold (attrset: acc: lib.recursiveUpdate attrset acc) {} listOfAttrsets;

  cfg = config.services.strichliste;

  env-file = pkgs.substituteAll {
    src = ./conf/env.env;

    databaseUrl = cfg.databaseUrl;
  };

  moveFilesDerivation = pkgs.stdenv.mkDerivation {
    name = "wrap-env-file";

    src = pkgs.callPackage ./pkgs/backend.nix {
      inherit pkgs cfg;
    };

    installPhase = ''
      mkdir -p $out
      cp -r $src/share/php/strichliste/* $out
    '';
  };

  patchDerivation = pkgs.stdenv.mkDerivation {
    name = "patchsource";

    src = moveFilesDerivation;

    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out
      cp -r ${env-file} $out/.env
    '';
  };

  mkSubmoduleOption = sub-cfg:
    mkOption {
      default = {};
      type = types.submodule {
        options = sub-cfg;
      };
    };

  mkSoundOption = desc:
    mkOption {
      default = [];
      type = types.listOf types.path;
      description = desc;
    };
in {
  options = {
    services.strichliste = {
      enable = mkEnableOption "enable the strichliste";

      package = mkOption {
        type = types.package;
        default = patchDerivation;
      };

      customSounds = mkSubmoduleOption {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Wether to enable custom sounds";
        };
        depositSounds = mkSoundOption "Sounds to be played when users deposit money";
        failedSounds = mkSoundOption "Sounds to be played when a transaction fails";
        withdrawSounds = mkSoundOption "Sounds to be played when a user withdraws money without buying anything";
        baselineSounds = mkSoundOption "Sounds to be played when an item is bought and has noting else set";
        specificSounds = mkOption {
          default = [];
          type = types.listOf (lib.types.submodule {
            options = {
              id = mkOption {
                type = types.int;
                description = "The id of the article to set the sound to";
              };

              sounds = mkSoundOption "Sounds to be played for that custom article";
            };
          });
        };
      };

      database = mkSubmoduleOption {
        configure = mkOption {
          type = types.bool;
          description = "Configure the database for you";
          default = true;
        };

        url = mkOption {
          type = types.nullOr types.str;
          default =
            if (cfg.database.configure)
            then "mysql://strichliste@localhost/strichliste"
            else null;
        };
      };

      databaseUrl = mkOption {
        type = types.nullOr types.str;
        default = "mysql://strichliste@localhost/strichliste";
      };

      dataDir = mkOption {
        type = types.str;
        description = "Data directory";
        default = "/var/lib/strichliste";
      };

      nginxSettings = mkSubmoduleOption {
        configure = mkOption {
          type = types.bool;
          default = true;
        };

        domain = mkOption {
          type = types.str;
          description = "The domain that nginx should listen on";
        };

        listenAddress = mkOption {
          type = types.listOf types.str;
          description = "The address nginx should listen on";
          default = ["0.0.0.0"];
        };
      };

      phpfpmSettings = mkSubmoduleOption {
        configure = mkOption {
          type = types.bool;
          default = true;
        };

        user = mkOption {
          type = types.str;
          default = "strichliste";
        };
      };

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
        default = (pkgs.formats.yaml {}).generate "strichliste.yaml" {
          parameters.strichliste = cfg.settings;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.mysql = lib.mkIf (cfg.database.configure) {
      enable = true;

      package = lib.mkDefault pkgs.mariadb;

      ensureUsers = [
        {
          name = "strichliste";
          ensurePermissions = {
            "strichliste.*" = "ALL PRIVILEGES";
          };
        }
      ];

      ensureDatabases = [
        "strichliste"
      ];

      initialDatabases = [
        {
          name = "strichliste";
          schema = ./schema.sql;
        }
      ];
    };

    users = lib.mkIf (cfg.phpfpmSettings.user == "strichliste") {
      users.strichliste = {
        isSystemUser = true;
        createHome = true;
        home = "/var/lib/strichliste";

        group = "strichliste";
      };

      groups.strichliste = {};
    };

    services.nginx = mkIf cfg.nginxSettings.configure {
      enable = true;
      virtualHosts = {
        ${cfg.nginxSettings.domain} = {
          listenAddresses = cfg.nginxSettings.listenAddress;
          root = "${cfg.package}/public";
          locations = {
            "/" = {
              tryFiles = "$uri /index.php$is_args$args";
            };

            "~ ^/index\.php(/|$)" = {
              fastcgiParams = {
                SCRIPT_FILENAME = "$document_root$fastcgi_script_name";
                PATH_INFO = "$fastcgi_path_info";

                DATABASE_URL = cfg.databaseUrl;

                modHeadersAvailable = "true";
                front_controller_active = "true";
              };
              extraConfig = ''
                fastcgi_split_path_info ^(.+\.php)(/.*)$;

                # fastcgi_pass unix:${config.services.phpfpm.pools.strichliste.socket};
                fastcgi_pass 127.0.0.1:9000;
                fastcgi_intercept_errors on;
                fastcgi_request_buffering off;

                include ${pkgs.nginx}/conf/fastcgi.conf;

                internal;
              '';
            };

            # "~ \\.php$" = {
            #   return = 404;
            # };
          };

          extraConfig = ''
            location ~ \.php$ {
              return 404;
            }
          '';
        };
      };
    };

    services.phpfpm.pools.strichliste = mkIf cfg.phpfpmSettings.configure {
      user = cfg.phpfpmSettings.user;

      settings = {
        "listen" = "127.0.0.1:9000";
        "listen.owner" = config.services.nginx.user;
        "listen.mode" = "0600";
        "pm" = "dynamic";
        "pm.max_children" = 32;
        "pm.max_requests" = 500;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 2;
        "pm.max_spare_servers" = 5;
        "php_admin_value[error_log]" = "stderr";
        "php_admin_flag[log_errors]" = true;
        "catch_workers_output" = true;
      };

      # maybe make this php automatically take the version defined in pkg.nix or vice-versa
      phpEnv."PATH" = lib.makeBinPath [pkgs.php81];
    };

    systemd.services."phpfpm-strichliste".serviceConfig.ExecStartPre = "${pkgs.bash}/bin/bash -c 'rm -fr ${cfg.dataDir}/cache'";
  };
}
