{
  lib,
  rustPlatform,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "piping-server-rust";
  version = "0.18.0";

  src = fetchFromGitHub {
    owner = "nwtgck";
    repo = "piping-server-rust";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-8kYaANVWmBOncTdhtjjbaYnEFQeuWjemdz/kTjwj2fw=";
  };

  cargoHash = "sha256-m6bYkewBE0ZloDVUhUslS+dgPyoK+eay7rrP3+c00mo=";

  nativeBuildInputs = [ versionCheckHook ];
  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Infinitely transfer between every device over pure HTTP with pipes or browsers";
    homepage = "https://github.com/nwtgck/piping-server-rust";
    changelog = "https://github.com/nwtgck/piping-server-rust/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ eveeifyeve ];
    mainProgram = "piping-server";
  };
})
