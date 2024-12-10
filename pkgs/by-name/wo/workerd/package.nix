{lib, buildBazelPackage, fetchFromGitHub, bazel_7, nix-update-script}:
buildBazelPackage rec {
  name = "workerd";
  version = "1.20241205.0";

  fetchFromGitHub = {
    owner = "cloudflare";
    repo = "workerd";
    rev = "v${version}";
    hash = lib.fakeHash;
  };

  bazel = bazel_7;

  bazelTargets = [ "//src/workerd/server:workerd" ];
  bazelBuildFlags = [ "--disk_cache=~/bazel-disk-cache" "--strip=always" ];

  fetchAttrs = {
    hash = null;
  };

  buildAttrs = {};

  passthru.update-script = nix-update-script { };

  meta = with lib; {
    description = "JavaScript/Wasm runtime that powers Cloudflare Workers";
    homepage = "https://github.com/cloudflare/workerd";
    license = licenses.asl20;
    platforms = ["x86_64-linux"];
    maintainers = with maintainers; [ eveeifyeve ];
  };
}
