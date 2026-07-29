# OpenAI Codex CLI from upstream's prebuilt release packages, pinned
# declaratively. Tracks GitHub releases directly, which lands new versions
# faster than nixpkgs (whose darwin builds regularly time out on Hydra).
# To bump, grab the latest rust-v<version> tag and the codex-package-*
# checksums (plain hex sha256, paste as-is):
#   curl -s https://api.github.com/repos/openai/codex/releases/latest | jq -r .tag_name
#   curl -sL https://github.com/openai/codex/releases/download/rust-v<version>/codex-package_SHA256SUMS
#
# The package tarball is a self-contained layout (bin/codex plus bundled rg
# and zsh that the binary locates relative to itself), so we install the
# whole tree. Linux builds are static musl binaries — no patching needed.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.146.0";

  # nix system -> (rust target triple, sha256 hex from codex-package_SHA256SUMS)
  platforms = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      sha256 = "cd961b480f6dfc4703bd244601f1927231fa31a587cb9046ccdffa6c4c29e7d5";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      sha256 = "f72f5ab71729e90b8e86343e9199c0f7a7eebbca5d6b1fc4cfcdaf35a3e5b641";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      sha256 = "c6eb28ec19bb5615b60e6787165ef28482481c2ce2617da565b83e591bc44c13";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      sha256 = "3c89125af1d7c98abec8beb551292ef99daca52e204e5852a9139feae2c467e5";
    };
  };

  plat =
    platforms.${stdenvNoCC.hostPlatform.system}
      or (throw "codex-native: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "codex-native";
  inherit version;

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-${plat.target}.tar.gz";
    inherit (plat) sha256;
  };

  # The tarball has multiple top-level entries (bin/, codex-path/,
  # codex-resources/), so extract straight into $out.
  dontUnpack = true;
  dontStrip = true; # preserve OpenAI's macOS code signature

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    tar -xzf $src -C $out
    runHook postInstall
  '';

  meta = {
    description = "OpenAI Codex CLI (native prebuilt package), version-pinned";
    homepage = "https://github.com/openai/codex";
    mainProgram = "codex";
    platforms = lib.attrNames platforms;
  };
}
