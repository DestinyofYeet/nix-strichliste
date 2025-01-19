{
  pkgs ? import <nixpkgs> {},
  cfg,
  ...
}:

let 
  version = "1.8.2";
  php = pkgs.php81;

  env-file = pkgs.writeText ".env" ''
    APP_ENV=prod
    DATABASE_URL="${cfg.databaseUrl}"
  '';

  yamlPatch = pkgs.substituteAll {
    src = ./patches/strichlisteYaml.patch;

    strichliste = cfg.configFile;
  };

  writeableDirsPath = pkgs.substituteAll {
    src = ./patches/makeDirectoriesWriteable.patch;

    cacheDir = cfg.dataDir + "/cache";
    logDir = cfg.dataDir + "/log";
  };

  app-src = let
     customFrontend = builtins.fetchTarball {
      url = "https://git.ole.blue/ole/strichliste-frontend/raw/commit/6e5f68c0f5f28ff9024ff3af5ef0e64a96b2c948/build.tar";
      sha256 = "1527pdg2y1saj2n13zlnjl8sqcnh3lr702v6x761nag11nagdgqz";
    };
    
  in pkgs.stdenv.mkDerivation {
    pname = "Strichliste-${version}-source";
    name = "Strichliste-source";
    # src = ./src/strichliste-v1.8.2-custom;
    src = builtins.fetchurl {
      url = "https://github.com/strichliste/strichliste/releases/download/v1.8.2/strichliste-v1.8.2.tar.gz";
      sha256 = "0p931wb5fvab1r8drd99cc1zl3gwaaxnic2brv13k64cxzxf85a6";
    };
    buildInputs = [ pkgs.coreutils ];

    unpackPhase = ''
      tar -xvf $src
    '';

    installPhase = ''
      mkdir -p $out
      cp -r * $out/
      rm -fr $out/public/*
      cp -r ${customFrontend}/* $out/public/
      cp public/index.php $out/public/index.php
      cp ${env-file} $out/.env
    '';

    patches = [
      ./patches/makeBuildable.patch
      ./patches/fix-doctrine.patch
      # ./patches/js-fix.patch
      writeableDirsPath
      yamlPatch
    ];
  };
in 
php.buildComposerProject {
  # src = ./src/strichliste-v1.8.2;
  src = app-src;

  pname = "strichliste";
  version = version;
  vendorHash = "sha256-YzXIk+obsNrRF7Q4O8VXuKTBWkQT+DIk3WHT+bN+Wvc=";
}
