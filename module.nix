self: { lib, config, pkgs, ... }:

with lib;

let
  cfg = config.services.strichliste;

  putInDir = src: outname: pkgs.stdenv.mkDerivation {
    name = "Put in dir";

    src = src;

    unpackPhase = ":";

    installPhase = ''
      mkdir -p $out
      cp ${src} $out/${outname}
    '';
  };
in {
  options = {
    services.strichliste = {
      enable = mkEnableOption "enable the strichliste";

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
              upper = 300;
              lower = -100;
            };

            payment = {
              undo = {
                enable = true;
                delete = false;
                timeout = "5 minute";
              };

              boundary = {
                upper = 300;
                lower = -200;
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

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      "strichliste" = {
        imageFile = (import ./docker-image.nix { inherit pkgs config; });
    
        image = "strichliste:latest";

        dependsOn = [ "strichliste-db" ];

        environment = {
          APP_ENV = "prod";
          DATABASE_URL = "mysql://strichliste:strichliste@127.0.0.1/strichliste";
        };

        volumes = 
          let
            src = builtins.fetchGit {
              url = "https://github.com/strichliste/strichliste-docker";
              rev = "abd94fcaf14cc13c08307f16b97cb2255a4ade50";
            };
          in 
          [
            "/mnt/data/configs/strichliste/var:/source/var"
          ];


        extraOptions = [ "--network=container:strichliste-db" ];
      };

      "strichliste-db" = {
        image = "mariadb:10.11.5";

        environment = {
          MARIADB_USER = "strichliste";
          MARIADB_PASSWORD = "strichliste";
          MARIADB_DATABASE = "strichliste";
          MARIADB_ROOT_PASSWORD = "root";
          MARIADB_AUTO_UPGRADE = "true";
        };

        volumes = [
          "/mnt/data/configs/strichliste/db:/var/lib/mysql"
        ];

        ports = [
          "8123:8080"
        ];
      };
    };
  };

  # config.systemd.services.docker-strichliste.postStart = ''
    # docker exec -it strichliste bash -c './../bin/console doctrine:schema:create'
  # '';
}
