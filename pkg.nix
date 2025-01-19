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

  app-src = pkgs.stdenv.mkDerivation {
    pname = "Strichliste-${version}-source";
    name = "Strichliste-source";
    src = builtins.fetchurl {
      url = "https://github.com/strichliste/strichliste/releases/download/v1.8.2/strichliste-v1.8.2.tar.gz";
      sha256 = "0p931wb5fvab1r8drd99cc1zl3gwaaxnic2brv13k64cxzxf85a6";
    };
    buildInputs = [ pkgs.coreutils ];

    unpackPhase = ''
      tar -xvf $src
    '';

    installPhase = if (cfg.frontEnd == null) then ''
      mkdir -p $out
      cp -r * $out/
      cp ${env-file} $out/.env
    '' else ''
      mkdir -p $out
      cp -r * $out/
      rm -fr $out/public/*
      cp -r ${cfg.frontEnd}/* $out/public/
      cp public/index.php $out/public/index.php
      cp ${env-file} $out/.env
    '';

    patches = [
      ./patches/makeBuildable.patch
      ./patches/fix-doctrine.patch
      writeableDirsPath
      yamlPatch
    ];
  };
in 
php.buildComposerProject {
  src = app-src;

  pname = "strichliste";
  version = version;
  vendorHash = "sha256-YzXIk+obsNrRF7Q4O8VXuKTBWkQT+DIk3WHT+bN+Wvc=";
}
