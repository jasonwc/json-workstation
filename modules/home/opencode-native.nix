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
  version = "1.18.35";

  # nix system -> (release asset, sha256 hex from the asset digest)
  platforms = {
    aarch64-darwin = {
      asset = "opencode-darwin-arm64.zip";
      sha256 = "80b05124357a77cd57945bfde36082a028e829c198d222d5e146617f49a2c4b7";
    };
    x86_64-darwin = {
      asset = "opencode-darwin-x64.zip";
      sha256 = "8127d69e8e94d7adc496e910435f2f73856d87d456e988d3a947f250c95c1be2";
    };
    aarch64-linux = {
      asset = "opencode-linux-arm64.tar.gz";
      sha256 = "f7f2ba59ee8aa94d388f9696575a32d20e71c2ee48def9f80fc693a60fec6c72";
    };
    x86_64-linux = {
      asset = "opencode-linux-x64.tar.gz";
      sha256 = "c8f888b451f5494a18f858fffb0e0b68f4e4baa9c241761c5f206884f0fa640d";
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
