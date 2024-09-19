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

  nginx-default-conf = pkgs.substituteAll {
    src = ./conf/default.conf;

    nginxPort = nginx-port;
    inherit appRoot;

    databaseUrl = cfgOci.environment.DATABASE_URL;

    fastcgiParams = "${pkgs.nginx}/conf/fastcgi_params";
  };

  nginx-nginx-conf = pkgs.substituteAll {
    src = ./conf/nginx.conf;

    mimetypes = "${pkgs.nginx}/conf/mime.types";
  };

  env-file = pkgs.substituteAll {
    src = ./conf/env.env;
    appEnv = cfgOci.environment.APP_ENV;
    databaseUrl = cfgOci.environment.DATABASE_URL;
  };

  start-script = pkgs.writeScriptBin "start-server" '' 
      #!${pkgs.runtimeShell}
      php bin/console doctrine:schema:create --no-interaction
      chown -R www-data:www-data ${appRoot}/var
      /source/entrypoint.sh nginx -c /etc/nginx/nginx.conf && php-fpm -y /etc/php81/php-fpm.conf
  '';

in pkgs.dockerTools.buildImage {
  name = "strichliste";
  tag = "latest";

  created = "now";

  fromImage = pkgs.dockerTools.pullImage {
    imageName = "alpine";
    imageDigest = "sha256:3ddf7bf1d408188f9849efbf4f902720ae08f5131bb39013518b918aa056d0de";
    sha256 = "AnLSwi8iqaTRE2C8mcwwDK13Do962Zh/ej+bxbATxQ8=";
  };

  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [
      start-script
      pkgs.php81
      pkgs.nginx
      pkgs.fakeNss
      pkgs.bash
      pkgs.coreutils
      pkgs.busybox
      pkgs.strace
      pkgs.file
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

    cp ${./conf/entrypoint.sh} ${appRoot}/entrypoint.sh
    chmod +x ${appRoot}/entrypoint.sh

    mkdir -p /etc/php81/php-fpm.d
    mkdir -p /etc/php81/conf.d
    mkdir -p /etc/nginx/conf.d

    cp ${./conf/php-fpm.conf} /etc/php81/php-fpm.conf
    cp ${./conf/www.conf} /etc/php81/php-fpm.d/www.conf
    cp ${nginx-nginx-conf} /etc/nginx/nginx.conf
    cp ${nginx-default-conf} /etc/nginx/conf.d/default.conf

    cp ${./conf/doctrine.yaml} ${appRoot}/config/packages/doctrine.yaml
    cp ${./conf/services.yaml} ${appRoot}/config/services.yaml
    cp ${env-file} ${appRoot}/.env

    ${pkgs.dockerTools.shadowSetup}

    # raw-dogging usermod and groupadd
    echo "www-data:x:82:82:www-data:/var/empty:/bin/false" >> /etc/passwd
    echo "www-data:x:82:" >> /etc/group
    echo "www-data:1:1::::::" >> /etc/shadow

    echo "nobody:x:65534:65534:nogroup:/var/empty:/bin/false" >> /etc/passwd
    echo "nogroup:x:65534:" >> /etc/group
    echo "nobody:!:1::::::" >> /etc/shadow

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

    WorkDir = "${appRoot}/public";
  };
}
