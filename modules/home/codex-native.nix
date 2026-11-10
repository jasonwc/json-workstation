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
  version = "0.167.0";

  # nix system -> (rust target triple, sha256 hex from codex-package_SHA256SUMS)
  platforms = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      sha256 = "af45ed45d940d7998809622c1c0296d3098ed7d7fad695284422c228bd454517";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      sha256 = "3d7c4c83296db63b5108e13612c77f3e5020b6c5f2fc004bee413a5cc92de899";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      sha256 = "0de261ecf1e7f3028a7952f03fca2093f749277d38590b78bb32f8567756bbb7";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      sha256 = "3bbf75e83de6b58aed28f2cf6e33ad423ec31fd4700a1457b94be557ea5a7c6e";
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
