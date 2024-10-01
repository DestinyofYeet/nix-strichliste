{
  pkgs ? import <nixpkgs> {},
  cfg,
  ...
}:

let 
  version = "1.8.2";
  php = pkgs.php81;

  yamlPatch = pkgs.substituteAll {
    src = ./patches/strichlisteYaml.patch;

    strichliste = cfg.configFile;
  };

  writeableDirsPath = pkgs.substituteAll {
    src = ./patches/makeDirectoriesWriteable.patch;

    cacheDir = cfg.cacheDir;
    logDir = cfg.logDir;
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
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';

    patches = [
      ./patches/makeBuildable.patch
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
