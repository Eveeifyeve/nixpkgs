{
  fetchFromGitHub,
  buildMozillaMach,
  fetchurl,
  patch,
  lib
}:
let
  version = "1.10.3b";
  zensource = fetchFromGitHub {
      owner = "zen-browser";
      repo = "desktop";
      rev = version;
      hash = "sha256-dEP2F/G+24Y7KI84roZdXGwklhTCXr2oulribl1y+Jo=";
      fetchSubmodules = true;
  };
in
(buildMozillaMach rec {
  pname = "zen-browser";
  packageVersion = version;
  applicationName = "Zen Browser";
  binaryName = "zen-browser";
  requireSigning = false;
  allowAddonSideload = true;
  version = "136.0.4";

  src = fetchurl {
    url = "mirror://mozilla/firefox/releases/${version}/source/firefox-${version}.source.tar.xz";
    hash = "sha256-Sii54cK48vHUNHReu4f8uorhFqICh48Pseg9pjz3wkI=";
  };


  unpackPhase = ''
    patch -p1 < ${zensource}/src/**/*.patch
  '';

  meta = {
    changelog = "https://zen-browser.app/release-notes/#${packageVersion}";
    description = "Firefox based browser with a focus on privacy and customization";
    homepage = "https://www.zen-browser.app/";
    maintainers = with lib.maintainers; [
      matthewpi
      titaniumtown
      eveeifyeve
    ];
    platforms = lib.platforms.unix;
    license = lib.licenses.mpl20;
    mainProgram = "zen";
  };
}).overrideAttrs (oldAttrs: {
  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ patch ];
})
