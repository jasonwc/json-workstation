# pi (earendil-works/pi) from upstream's prebuilt release packages, pinned
# declaratively. Tracks GitHub releases directly, which lands new versions
# faster than nixpkgs. Bump with `scripts/bump-agents.sh pi`, or by hand from
# the release's SHA256SUMS:
#   gh release view -R earendil-works/pi --json tagName -q .tagName
#   curl -sL https://github.com/earendil-works/pi/releases/download/v<version>/SHA256SUMS
#
# The tarball is a self-contained tree (the bun-compiled `pi` plus themes,
# wasm and native addons it loads from beside itself), so the whole tree goes
# into libexec and bin/pi is a symlink to it.
{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  stdenv,
  libxcb,
}:

let
  version = "1.1.0";

  # nix system -> (release platform key, sha256 hex from SHA256SUMS)
  platforms = {
    aarch64-darwin = {
      key = "darwin-arm64";
      sha256 = "3455b13de35c15a5893cdebc922678199e90a7ce99b06cbc23f37860e90d63c7";
    };
    x86_64-darwin = {
      key = "darwin-x64";
      sha256 = "8fdd9149ae27e7470a6a10ed8a7c0ed80738d55adec80a8d7764f6386d1e658b";
    };
    aarch64-linux = {
      key = "linux-arm64";
      sha256 = "f3b0cac459f9df5420e4e48b48e95d81bfab57b701dd3fe4b08fda7d11d27dab";
    };
    x86_64-linux = {
      key = "linux-x64";
      sha256 = "3faa94666cd3849d37af320ff749407d0271b07a9b94f420c87e30866e10e289";
    };
  };

  plat =
    platforms.${stdenvNoCC.hostPlatform.system}
      or (throw "pi-native: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "pi-native";
  inherit version;

  src = fetchurl {
    url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-${plat.key}.tar.gz";
    inherit (plat) sha256;
  };

  dontStrip = true; # preserve the macOS code signature and bun's payload

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  # libxcb: the X11 clipboard addon (linux-platform-x11.node) links it.
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    libxcb
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/libexec $out/bin
    cp -r . $out/libexec/pi
    ln -s $out/libexec/pi/pi $out/bin/pi
    runHook postInstall
  '';

  meta = {
    description = "pi coding agent (upstream prebuilt package), version-pinned";
    homepage = "https://pi.dev";
    mainProgram = "pi";
    platforms = lib.attrNames platforms;
  };
}
