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
  version = "0.159.0";

  # nix system -> (rust target triple, sha256 hex from codex-package_SHA256SUMS)
  platforms = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      sha256 = "7748d07d7921a67b91d015e9d0f43177c675977e67f955b2f8fb96dc880dd5d7";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      sha256 = "ab64d30288454124c7c15abd81672a9dfda7e3e723d76c4cfa6c0aba4b439017";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      sha256 = "7399d2bf7618cc8d6845a8acdb2078106332861f7f30d36527e8f53208df89da";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      sha256 = "35da65d7e8644e28ea0a4d4e3d8c15b40c6b492356d4cf21986c7e341f83a24e";
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
