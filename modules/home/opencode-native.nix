# opencode from upstream's prebuilt release binaries, pinned declaratively.
# Tracks GitHub releases directly, which lands new versions faster than
# nixpkgs. Bump with `scripts/bump-agents.sh opencode`, or by hand from the
# release assets' sha256 digests:
#   gh release view -R sst/opencode --json tagName,assets \
#     -q '.tagName, (.assets[] | "\(.name) \(.digest)")'
#
# The binary is a single bun-compiled executable. Linux gets the glibc build,
# patched like ./claude-code-native.nix.
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  autoPatchelfHook,
  stdenv,
}:

let
  version = "1.19.5";

  # nix system -> (release asset, sha256 hex from the asset digest)
  platforms = {
    aarch64-darwin = {
      asset = "opencode-darwin-arm64.zip";
      sha256 = "c1c9e62521192192ef4c3ed1355ada2144055bddb61682217e997b03c55203c1";
    };
    x86_64-darwin = {
      asset = "opencode-darwin-x64.zip";
      sha256 = "b0212efa6db347187225a17fa3a31c6b261bf4c9f1589a290b0ca902d720d250";
    };
    aarch64-linux = {
      asset = "opencode-linux-arm64.tar.gz";
      sha256 = "fae5be262d693b7c5e562856cc473e59e741772936db0c0600ac0d5ed5bd088b";
    };
    x86_64-linux = {
      asset = "opencode-linux-x64.tar.gz";
      sha256 = "588310a336fa3b9df36b3f0225b26f679d453efaad0cf3d66c3651ef3ec1647a";
    };
  };

  plat =
    platforms.${stdenvNoCC.hostPlatform.system}
      or (throw "opencode-native: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "opencode-native";
  inherit version;

  src = fetchurl {
    url = "https://github.com/sst/opencode/releases/download/v${version}/${plat.asset}";
    inherit (plat) sha256;
  };

  sourceRoot = ".";
  dontStrip = true; # preserve the macOS code signature and bun's payload

  nativeBuildInputs = [ unzip ] ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 opencode $out/bin/opencode
    runHook postInstall
  '';

  meta = {
    description = "opencode (upstream prebuilt binary), version-pinned";
    homepage = "https://opencode.ai";
    mainProgram = "opencode";
    platforms = lib.attrNames platforms;
  };
}
