{
  pkgs,
  cfg,
  ...
}: let
  lib = pkgs.lib;

  soundsToStrings = soundList:
    if ((lib.lists.length soundList) == 0)
    then "\"\""
    else builtins.concatStringsSep ", " (map (store: "\"${builtins.baseNameOf store}\"") soundList);

  mkSoundFiles = soundList:
    if ((lib.lists.length soundList) == 0)
    then "\"\""
    else builtins.concatStringsSep ", " (map (value: "[${toString value.id}, [${soundsToStrings value.sounds}]]") soundList);

  customSounds = cfg.customSounds;

  customSoundPatch = pkgs.substituteAll {
    src = ../patches/customSounds.patch;

    depositFiles = soundsToStrings customSounds.depositSounds;
    failedFiles = soundsToStrings customSounds.failedSounds;
    withdrawFiles = soundsToStrings customSounds.withdrawSounds;
    baseFiles = soundsToStrings customSounds.baselineSounds;
    soundFiles = mkSoundFiles customSounds.specificSounds;
  };

  buildCpCommand = soundList: (builtins.concatStringsSep "\n" (map (file: "cp -n ${file} public/sounds/${builtins.baseNameOf file}") soundList));
  buildSpecificCpCommands = soundList: (builtins.concatStringsSep "\n" (map (value: buildCpCommand value.sounds) soundList));
in
  pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "strichliste-frontend";
    version = "1.8.2";

    src = pkgs.fetchFromGitHub {
      owner = "strichliste";
      repo = "strichliste-web-frontend";
      rev = "0150aae0d5";
      hash = "sha256-r9R//4XE85dkChLSu+Sn8Yo72dNZY8Z3yDHOiYIYjwg=";
    };

    yarnOfflineCache = pkgs.fetchYarnDeps {
      yarnLock = finalAttrs.src + "/yarn.lock";
      hash = "sha256-NVQpXMiKVgFnAxLvl+BhFqXZU51D2CWfrVs5e/m4bMs=";
    };

    yarnKeepDevDeps = true;

    buildPhase = ''
      export NODE_OPTIONS="--openssl-legacy-provider"
      export HOME=$(mktemp -d)
      mkdir -p public/sounds/
      ${buildCpCommand customSounds.depositSounds}
      ${buildCpCommand customSounds.failedSounds}
      ${buildCpCommand customSounds.withdrawSounds}
      ${buildCpCommand customSounds.baselineSounds}
      ${buildSpecificCpCommands customSounds.specificSounds}
      yarn --offline build
    '';

    installPhase = ''
      mkdir -p $out
      cp -r build/* $out
    '';

    patches = pkgs.lib.optionals cfg.customSounds.enable [
      customSoundPatch
      ../patches/transactionPlayFix.patch
    ];

    nativeBuildInputs = with pkgs; [
      yarnConfigHook
      yarnBuildHook
      yarnInstallHook
      # Needed for executing package.json scripts
      nodejs
    ];
  })
