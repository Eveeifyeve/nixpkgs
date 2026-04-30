{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  protobuf,
  bzip2,
  fontconfig,
  freetype,
  libgit2,
  libxkbcommon,
  oniguruma,
  openssl,
  rust-jemalloc-sys,
  sqlite,
  vulkan-loader,
  xz,
  zlib,
  zstd,
  stdenv,
  alsa-lib,
  wayland,
  apple-sdk,
  xcbuild,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "warp-terminal";
  version = "0.2026.04.29.08.56.stable_00";

  src = fetchFromGitHub {
    owner = "warpdotdev";
    repo = "warp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ChtFrQGd4ha2DFb/gv8lIy0tyygoo3eoaY2hjL6dBIo=";
  };

  cargoBuildFlags = [ "--package=warp" ];
  cargoTestFlags = finalAttrs.cargoBuildFlags;

  cargoHash = "sha256-Pqxzek7hAuj/mlhiaipq+TsufWOsfuabj8T4O70oluw=";

  nativeBuildInputs = [
    pkg-config
    protobuf
    xcbuild
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    bzip2
    fontconfig
    freetype
    libgit2
    libxkbcommon
    oniguruma
    openssl
    rust-jemalloc-sys
    sqlite
    vulkan-loader
    xz
    zlib
    zstd
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
    wayland
  ];

  env = {
    LIBGIT2_NO_VENDOR = true;
    RUSTONIG_SYSTEM_LIBONIG = true;
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Warp is an agentic development environment, born out of the terminal";
    homepage = "https://github.com/warpdotdev/warp";
    license = with lib.licenses; [
      agpl3Only
      mit
    ];
    maintainers = with lib.maintainers; [
      imadnyc
      FlameFlag
      johnrtitor
      logger
    ];
    platforms = lib.platforms.darwin ++ [
      "x86_64-linux"
      "aarch64-linux"
    ];

    mainProgram = "warp-terminal";
  };
})
