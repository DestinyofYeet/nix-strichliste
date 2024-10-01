self: { lib, config, pkgs, ... }:

with lib;

let
  cfg = config.services.strichliste;

  env-file = pkgs.substituteAll {
    src = ./conf/env.env;

    databaseUrl = cfg.databaseUrl;
  };

  moveFilesDerivation = pkgs.stdenv.mkDerivation {
    name = "wrap-env-file";

    src = pkgs.callPackage ./pkg.nix {
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
      cp -r ${cfg.configFile} $out
    '';
  };
in {
  options = {
    services.strichliste = {
      enable = mkEnableOption "enable the strichliste";

      package = mkOption {
        type = types.package;
        default = patchDerivation;
      };

      databaseUrl = mkOption {
        type = types.str;
      };

      cacheDir = mkOption {
        type = types.str;
        description = "Needs to be writable by ${cfg.phpfpmSettings.user}";
        default = "/var/lib/strichliste/cache";
      };

      logDir = mkOption {
        type = types.str;
        description = "Needs to be writable by ${cfg.phpfpmSettings.user}";
        default = "/var/lib/strichliste/log";
      };

      nginxSettings = {
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
          default = [ "0.0.0.0" ];
        };
      };

      phpfpmSettings = {
        configure = mkOption {
          type = types.bool;
          default = true;
        };

        user = mkOption {
          type = types.str;
          default = "nginx";
        };
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

    services.nginx.virtualHosts = mkIf cfg.nginxSettings.configure {
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
      phpEnv."PATH" = lib.makeBinPath [ pkgs.php81 ];
    };
  };
}
