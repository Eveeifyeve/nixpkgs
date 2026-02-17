{
  stdenvNoCC,
  lib,
  fetchzip,
  makeWrapper,
}:
let
  clientVersionUpload = "4a858a3a05c64f79";
  hashes = {
    aarch64-darwin = "sha256-s/HLY/uDeJFudamYr5DofoBpNE+vl3OcSQUpOMysLnE=";
    x86_64-darwin = "sha256-B7Kzkjk8yA4AhYWQku1gc1eiMjFH6ySyxYcTSySoAV4=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "roblox";
  version = "0.720.0.7201160";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchzip {
    url = "https://setup.rbxcdn.com/mac${lib.optionalString stdenvNoCC.hostPlatform.isAarch64 "/arm64"}/version-${clientVersionUpload}-RobloxPlayer.zip";
    stripRoot = false;
    hash =
      hashes.${stdenvNoCC.hostPlatform.system}
        or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -r $src/*.app $out/Applications

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Multiplayer game platform designed for playing games";
    homepage = "https://www.roblox.com";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ eveeifyeve ];
    mainProgram = "RobloxPlayer.app";
    platforms = lib.platforms.darwin;
  };
}
