{
  pkgs ? import <nixpkgs> {},
  ...
}:

let 
  version = "1.8.2";
  php = pkgs.php81;
in 
php.buildComposerProject {
  src = ./src/strichliste-v1.8.2;
  pname = "strichliste";
  version = version;
  vendorHash = "sha256-YzXIk+obsNrRF7Q4O8VXuKTBWkQT+DIk3WHT+bN+Wvc=";
}
