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
  version = "2.1.170";

  # nix system -> (release platform key, sha256 hex from manifest.json)
  platforms = {
    aarch64-darwin = {
      key = "darwin-arm64";
      sha256 = "e903646d8b7a31882a80ecd27569a27d8ac57b3708745f349709632c84117fdf";
    };
    x86_64-darwin = {
      key = "darwin-x64";
      sha256 = "914f23a70bbed5d9ae567e3e04b86206ed9971b371bc9baca3f79c8885bfddb4";
    };
    aarch64-linux = {
      key = "linux-arm64";
      sha256 = "1bb9d032440a75532f7dd4cafbc687f220aaf16c63eba17e192dfbec2f04bd25";
    };
    x86_64-linux = {
      key = "linux-x64";
      sha256 = "849e007277a0442ab27570d3e3d6d43787507946590e8dd1947e5a39b7081f9e";
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
