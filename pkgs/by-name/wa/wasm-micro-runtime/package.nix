{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  simde,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "wasm-micro-runtime";
  version = "2.4.4";

  src = fetchFromGitHub {
    owner = "bytecodealliance";
    repo = "wasm-micro-runtime";
    tag = "WAMR-${finalAttrs.version}";
    hash = "sha256-pNudBKnhdR/Ye0m2tVZB/wSfJZYK8+gdCpCp0rDp0o4=";
  };

  patches = [ ];

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    simde
  ];

  meta = {
    description = "WebAssembly Micro Runtime (WAMR";
    homepage = "https://github.com/bytecodealliance/wasm-micro-runtime";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ eveeifyeve ];
    mainProgram = "wasm-micro-runtime";
    platforms = lib.platforms.all;
  };
})
