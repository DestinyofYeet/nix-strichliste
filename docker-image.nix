{
  pkgs ? import <nixpkgs> {},
  config
}:

let 
  app = (pkgs.callPackage ./pkg.nix { });
  appRoot = "${app}/share/php/strichliste";

  cfg = config.services.strichliste;

  nginx-port = "80";

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

        include       ${./conf/mime.types};
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
          root /source/strichliste/public;

          location / {
              # try to serve file directly, fallback to index.php
              try_files $uri /index.php$is_args$args;
          }

          location ~ ^/index\.php(/|$) {
              fastcgi_pass 127.0.0.1:9000;
              fastcgi_split_path_info ^(.+\.php)(/.*)$;
              include ${./conf/fastcgi.conf};

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

  start-script = pkgs.writeScriptBin "start-server" '' 
      #!${pkgs.runtimeShell}
      cd /source/strichliste
      bin/console doctrine:schema:create --no-interaction
      chown -R www-data:www-data /source/strichliste/var
      nginx -c ${nginx-conf} && php-fpm --fpm-config ${./conf/php-fpm.conf}
  '';

in pkgs.dockerTools.buildImage {
  name = "strichliste";
  tag = "latest";

  created = "now";

  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [
      app
      start-script
      pkgs.php
      pkgs.nginx
      pkgs.fakeNss
      pkgs.bash
      pkgs.coreutils
      pkgs.busybox
      cfg.configFile
    ];
    pathsToLink = [ "/bin" ];
  };
  
  runAsRoot = ''
    mkdir -p /source
    mkdir -p /var/log/nginx
    mkdir -p /var/lib/nginx
    mkdir -p /var/cache/nginx
    mkdir -p /var/log/php
    mkdir -p /var/log/php-fpm
    mkdir -p /tmp
    chmod 1777 /tmp

    cp -r ${appRoot} /source
    cp -r ${cfg.configFile}/strichliste.yaml /source/strichliste.yaml

    ${pkgs.dockerTools.shadowSetup}

    # raw-dogging usermod and groupadd
    echo "www-data:x:12345:12345:www-data:/var/empty:/bin/false" > /etc/passwd
    echo "www-data:x:12345:" > /etc/group
    echo "www-data:1:1::::::" > /etc/shadow

    chown -R www-data:www-data /var/log/nginx
    chown -R www-data:www-data /var/lib/nginx
    chown -R www-data:www-data /var/cache/nginx
    chown -R www-data:www-data /var/log/php
    chown -R www-data:www-data /var/log/php-fpm
    chown -R www-data:www-data /source

    chmod -R u+w /source
    chmod -R g+w /source
  '';

  config = {
    Cmd = [ "start-server" ];
    ExposedPorts = {
      "${nginx-port}/tcp" = {};
    };

    WorkDir = "/source";
  };
}
