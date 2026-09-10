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
  version = "2.1.267";

  # nix system -> (release platform key, sha256 hex from manifest.json)
  platforms = {
    aarch64-darwin = {
      key = "darwin-arm64";
      sha256 = "a681f3008f0050029aeebcab3af51bb6a55ddeb625a3af3141a4416d43cd2558";
    };
    x86_64-darwin = {
      key = "darwin-x64";
      sha256 = "071988cb2e5a4378d8543d78e0ff5f8ed1ecc5e113271774a0582ee74fb0ef79";
    };
    aarch64-linux = {
      key = "linux-arm64";
      sha256 = "226a4e009574044a18bf5495f127806b2a1bfcbf25b3c01608705fafee95fefb";
    };
    x86_64-linux = {
      key = "linux-x64";
      sha256 = "0399c793ff571d5946ef923d80b4f330d05ac4b6842a6b0775468f5d389403c0";
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

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.isLinux [ stdenv.cc.cc.lib ];

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
