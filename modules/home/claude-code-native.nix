# Claude Code's native standalone build, pinned declaratively. Tracks
# Anthropic's release channel directly, which lands new versions faster than
# nixpkgs. To bump, grab the latest version and its per-platform sha256 from
# the manifest (the checksum field is a plain hex sha256, paste it as-is):
#   curl -s https://downloads.claude.ai/claude-code-releases/latest
#   curl -s https://downloads.claude.ai/claude-code-releases/<version>/manifest.json
{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  stdenv,
}:

let
  version = "2.1.295";

  # nix system -> (release platform key, sha256 hex from manifest.json)
  platforms = {
    aarch64-darwin = {
      key = "darwin-arm64";
      sha256 = "0116ee2e0a513900b633d9951367f18747686478e2b462805b8c31609f047f70";
    };
    x86_64-darwin = {
      key = "darwin-x64";
      sha256 = "a6066492288585a1ef5e482cb28ad22714ab12cd48e367c0cee988b00cff724c";
    };
    aarch64-linux = {
      key = "linux-arm64";
      sha256 = "cfb9dc1332fb6f92a683f835823e91b3179a803398ca7852cd2381a3cb1dea3b";
    };
    x86_64-linux = {
      key = "linux-x64";
      sha256 = "4503bfe11a6c7fcc1e0b39b5e0d347c04248f750b03b0977b3ad6b531fe6f358";
    };
  };

  plat =
    platforms.${stdenvNoCC.hostPlatform.system}
      or (throw "claude-code-native: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "claude-code-native";
  inherit version;

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-code-releases/${version}/${plat.key}/claude";
    inherit (plat) sha256;
  };

  dontUnpack = true;
  dontStrip = true; # preserve Anthropic's macOS code signature

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/claude
    runHook postInstall
  '';

  meta = {
    description = "Claude Code (native standalone build), version-pinned";
    homepage = "https://code.claude.com";
    mainProgram = "claude";
    platforms = lib.attrNames platforms;
  };
}
