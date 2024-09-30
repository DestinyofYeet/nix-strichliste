self: { lib, config, pkgs, ... }:

with lib;

let
  cfg = config.services.strichliste;

  putInDir = src: outname: pkgs.stdenv.mkDerivation {
    name = "Put in dir";

    src = src;

    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out
      cp ${src} $out/${outname}
    '';
  };
in {
  options = {
    services.strichliste = {
      enable = mkEnableOption "enable the strichliste";

      package = mkOption {
        type = types.package;
        default = self.packages.x86_64-linux.strichliste;
      };

      databaseUrl = mkOption {
        type = types.str;
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
        default = putInDir (( pkgs.formats.yaml {} ).generate "strichliste.yaml" cfg.configuration) "strichliste.yaml";        
      };
    };
  };

  config = let 
    strichliste-root = "${cfg.package}/share/php/strichliste";
  in mkIf cfg.enable {

    services.nginx.virtualHosts = mkIf cfg.nginxSettings.configure {
      ${cfg.nginxSettings.domain} = {
        root = "${strichliste-root}/public";
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

              fastcgi_pass unix:${config.services.phpfpm.pools.strichliste.socket};
              fastcgi_intercept_errors on;
              fastcgi_request_buffering off;

              include ${pkgs.nginx}/conf/fastcgi.conf;

              internal;
            '';
          };

          "~ \\.php$" = {
            return = 404;
          };
        };
      };      
    };

    services.phpfpm.pools.strichliste = mkIf cfg.phpfpmSettings.configure {
      user = cfg.phpfpmSettings.user;

      settings = {
        "listen.owner" = config.services.nginx.user;
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
