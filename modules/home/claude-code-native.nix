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
  version = "2.1.270";

  # nix system -> (release platform key, sha256 hex from manifest.json)
  platforms = {
    aarch64-darwin = {
      key = "darwin-arm64";
      sha256 = "a506b6d970a4cf44f6abdb53a81ddcd5d3b0ce042a95c502fe9d1f946bdb8807";
    };
    x86_64-darwin = {
      key = "darwin-x64";
      sha256 = "b3ee3237a019b8a5abb3008f1c7ddd46295a0e6e65ab94545a79c9b997dc8928";
    };
    aarch64-linux = {
      key = "linux-arm64";
      sha256 = "7bf9f33acc124df9abccf6f2366397a82a740378d535fa12d426fa77fdbc9946";
    };
    x86_64-linux = {
      key = "linux-x64";
      sha256 = "3a624a5a7cd79bbad4d32bd7db36f1197ecf458bc5bf1e2aed81834a01ad3ef0";
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
