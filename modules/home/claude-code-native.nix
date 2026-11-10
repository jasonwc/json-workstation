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
  version = "2.1.322";

  # nix system -> (release platform key, sha256 hex from manifest.json)
  platforms = {
    aarch64-darwin = {
      key = "darwin-arm64";
      sha256 = "a9d237949db816a0b7afd88a9a8e1df36b3a597a30f5a41d1c0539eb180a3450";
    };
    x86_64-darwin = {
      key = "darwin-x64";
      sha256 = "b513d15117cbf1bb05095dab41963fd394ff40de1fa99dcc6d7d1033bf292e9b";
    };
    aarch64-linux = {
      key = "linux-arm64";
      sha256 = "f220ca50ea4f3222043ff83cc224a1262e0196e9897acc0871efa94235b0c1fd";
    };
    x86_64-linux = {
      key = "linux-x64";
      sha256 = "bfb3703ad5380242328459bc62ada4bde8ae7ba57c6e1eeadb9c00e08874c478";
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
