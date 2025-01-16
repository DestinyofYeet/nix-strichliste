{
  pkgs ? import <nixpkgs> {},
  config
}:

let
  appRoot = "/source";

  cfg = config.services.strichliste;

  src = ./tar-src;
  
  start-script = pkgs.writeScriptBin "start-server" '' 
      #!${pkgs.runtimeShell}
      # chown -R www-data:www-data ${appRoot}/var
      /source/entrypoint.sh nginx -c /etc/nginx/nginx.conf && php-fpm -y /etc/php81/php-fpm.conf
  '';

in pkgs.dockerTools.buildImage {
  name = "strichliste";
  tag = "nix-v1";

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
  
  runAsRoot = ''
    mkdir -p ${appRoot}
    mkdir -p ${appRoot}/var
    mkdir -p /var/{log,lib}/nginx
    mkdir -p /var/log/php81
    mkdir -p /tmp
    chmod 1777 /tmp

    cd ${appRoot}

    cp -r ${src}/* .

    cp ${./entrypoint.sh} entrypoint.sh

    chmod +x entrypoint.sh

    adduser -u 82 -D -S -G www-data www-data

    chown -R www-data:www-data /source
    chown -R www-data:www-data /var/lib/nginx
    chown -R www-data:www-data /var/log/nginx
    chown -R www-data:www-data /var/log/php81

    su www-data

    cp ./config/php-fpm.conf /etc/php81/php-fpm.conf
    cp ./config/www.conf /etc/php81/php-fpm.d/www.conf
    cp ./config/nginx.conf /etc/nginx/nginx.conf
    cp ./config/default.conf /etc/nginx/conf.d/default.conf

    mkdir /source/var

    cd /source/var
  '';

  config = {
    Cmd = [ "start-server" ];
    ExposedPorts = {
      "${toString cfg.port}/tcp" = {};
    };

    WorkDir = "${appRoot}/public";
  };
}
