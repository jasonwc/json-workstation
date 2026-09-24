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
  version = "0.156.1";

  # nix system -> (rust target triple, sha256 hex from codex-package_SHA256SUMS)
  platforms = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      sha256 = "fea42f9625091f011e38f059da974d52e57ba31831648bb1c7f0b1a385fde547";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      sha256 = "618dbcd55419fa041871f777a14b107ceb3fe2d339ef81e21e6ab5374420dc71";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      sha256 = "fdd47ed6aade0360796fd3f6f95a45096f327c15e19e8c7339f9dc5633041786";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      sha256 = "8b711520beddf385467b8da4d2c93736637c6ba1e46811cf0d8606b7c490b6f6";
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
