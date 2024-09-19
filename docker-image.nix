{
  pkgs ? import <nixpkgs> {},
  config
}:

let 
  # app = (pkgs.callPackage ./pkg.nix { });
  # pkgRoot = "${app}/share/php/strichliste";

  pkgRoot = pkgs.stdenv.mkDerivation {
    name = "strichliste-source";
    # srcs = builtins.fetchurl {
      # url = "https://github.com/strichliste/strichliste/releases/download/v1.8.2/strichliste-v1.8.2.tar.gz";
      # sha256 = "0p931wb5fvab1r8drd99cc1zl3gwaaxnic2brv13k64cxzxf85a6";
    # };

    # sourceRoot = ".";
    src = ./tar-src;

    # setSourceRoot = "sourceRoot=.";

    installPhase = ''
      mkdir -p $out

      cp -r $src/* $out
    '';
  };

  appRoot = "/source";

  cfg = config.services.strichliste;
  cfgOci = config.virtualisation.oci-containers.containers.strichliste;

  nginx-port = "8080";

  nginx-conf = pkgs.writeText "nginx.conf" ''
    worker_processes  4;

    user www-data;

    error_log  /var/log/nginx/error.log warn;
    pid        /var/lib/nginx/nginx.pid;

    events {
        worker_connections  1024;
    }


    http {
        log_format scripts '$document_root$fastcgi_script_name > $request';

        include       ${pkgs.nginx}/conf/mime.types;
        default_type  application/octet-stream;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;
        #tcp_nopush     on;

        keepalive_timeout  65;

        gzip  on;

        server {
          listen       ${nginx-port};
          server_name  localhost;
          access_log /var/log/nginx/scripts.log scripts;
          root ${appRoot}/public;

          location / {
              # try to serve file directly, fallback to index.php
              try_files $uri /index.php$is_args$args;
          }

          location ~ ^/index\.php(/|$) {
              fastcgi_pass 127.0.0.1:9000;
              fastcgi_split_path_info ^(.+\.php)(/.*)$;
              include ${pkgs.nginx}/conf/fastcgi_params;

              # When you are using symlinks to link the document root to the
              # current version of your application, you should pass the real
              # application path instead of the path to the symlink to PHP
              # FPM.
              # Otherwise, PHP's OPcache may not properly detect changes to
              # your PHP files (see https://github.com/zendtech/ZendOptimizerPlus/issues/126
              # for more information).
              fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
              fastcgi_param DOCUMENT_ROOT $realpath_root;
              # Prevents URIs that include the front controller. This will 404:
              # http://domain.tld/index.php/some-path
              # Remove the internal directive to allow URIs like this
              internal;

              # set DATABASE_URL env Variable

              fastcgi_param DATABASE_URL "${config.virtualisation.oci-containers.containers.strichliste.environment.DATABASE_URL}";
          }

          # return 404 for all other php files not matching the front controller
          # this prevents access to other php files you don't want to be accessible.
          location ~ \.php$ {
              return 404;
          }
      }
    }
  '';

  env-file = pkgs.writeText ".env" ''
    
    # This file is a "template" of which env vars need to be defined for your application
    # Copy this file to .env file for development, create environment variables when deploying to production
    # https://symfony.com/doc/current/best_practices/configuration.html#infrastructure-related-configuration

    ###> symfony/framework-bundle ###
    APP_ENV=${cfgOci.environment.APP_ENV}
    APP_SECRET=afcb8ed6bf80cf0d8d9196390e06a408
    #TRUSTED_PROXIES=127.0.0.1,127.0.0.2
    #TRUSTED_HOSTS=localhost,example.com
    ###< symfony/framework-bundle ###

    ###> doctrine/doctrine-bundle ###
    # Format described at http://docs.doctrine-project.org/projects/doctrine-dbal/en/latest/reference/configuration.html#connecting-using-a-url
    # For an SQLite database, use: "sqlite:///%kernel.project_dir%/var/data.db"
    # Configure your db driver and server_version in config/packages/doctrine.yaml
    DATABASE_URL="${cfgOci.environment.DATABASE_URL}"
    ###< doctrine/doctrine-bundle ###

    ###> nelmio/cors-bundle ###
    CORS_ALLOW_ORIGIN=^https?://localhost(:[0-9]+)?$
    ###< nelmio/cors-bundle ###  '';

  start-script = pkgs.writeScriptBin "start-server" '' 
      #!${pkgs.runtimeShell}
      cd ${appRoot}
      php bin/console doctrine:schema:create --no-interaction
      chown -R www-data:www-data ${appRoot}/var
      nginx -c ${nginx-conf} && php-fpm --fpm-config ${./conf/php-fpm.conf}
  '';

in pkgs.dockerTools.buildImage {
  name = "strichliste";
  tag = "latest";

  created = "now";

  # fromImage = pkgs.dockerTools.pullImage {
    # imageName = "alpine";
    # imageDigest = "sha256:3ddf7bf1d408188f9849efbf4f902720ae08f5131bb39013518b918aa056d0de";
    # sha256 = "AnLSwi8iqaTRE2C8mcwwDK13Do962Zh/ej+bxbATxQ8=";
  # };

  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [
      start-script
      cfg.configFile
      pkgs.php81
      pkgs.nginx
      pkgs.fakeNss
      pkgs.bash
      pkgs.coreutils
      pkgs.busybox
      pkgs.strace
    ];
    pathsToLink = [ "/bin" ];
  };

  # use 
  # cp -r ${pkgRoot}/* ${appRoot}
  # instead of 
  # curl -Lo ...
  # to use the built package instead
  
  runAsRoot = ''
    mkdir -p ${appRoot}
    mkdir -p /var/log/nginx
    mkdir -p /var/lib/nginx
    mkdir -p /var/cache/nginx
    mkdir -p /var/log/php
    mkdir -p /var/log/php-fpm
    mkdir -p /tmp
    chmod 1777 /tmp

    cp -r ${pkgRoot}/* ${appRoot}
    
    cp -r ${cfg.configFile}/strichliste.yaml ${appRoot}/config/strichliste.yaml
    # cp -r ${./conf/strichliste.yaml} ${appRoot}/config/strichliste.yaml

    cp ${./conf/doctrine.yaml} ${appRoot}/config/packages/doctrine.yaml
    cp ${./conf/services.yaml} ${appRoot}/config/services.yaml
    cp ${env-file} ${appRoot}/.env

    ${pkgs.dockerTools.shadowSetup}

    # raw-dogging usermod and groupadd
    echo "www-data:x:82:82:www-data:/var/empty:/bin/false" > /etc/passwd
    echo "www-data:x:82:" > /etc/group
    echo "www-data:1:1::::::" > /etc/shadow

    chown -R www-data:www-data /var/log/nginx
    chown -R www-data:www-data /var/lib/nginx
    chown -R www-data:www-data /var/cache/nginx
    chown -R www-data:www-data /var/log/php
    chown -R www-data:www-data /var/log/php-fpm
    chown -R www-data:www-data ${appRoot}

    chmod -R u+w ${appRoot}
    chmod -R g+w ${appRoot}
  '';

  config = {
    Cmd = [ "start-server" ];
    ExposedPorts = {
      "${nginx-port}/tcp" = {};
    };

    WorkDir = "${appRoot}";
  };
}
