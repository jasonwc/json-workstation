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
  version = "0.162.0";

  # nix system -> (rust target triple, sha256 hex from codex-package_SHA256SUMS)
  platforms = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      sha256 = "5809ee90a9c3b59d438bb2663aefa0b43d86f825438b65d4504b31f82343628b";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      sha256 = "928b421103f339683d0d9f8a648f7b591ae4be907cbd8a5418dda319ff2bbd3c";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      sha256 = "d47a5fa21e037a1b85729b88c238ff3da8a956fc9fb5ad3976714428e7fb2bda";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      sha256 = "4f573944c1d2059109d75a2f4d0cc9c03697288224a5e407717a9de98fc010c5";
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
