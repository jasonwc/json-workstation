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
  version = "1.5.2";

  # nix system -> (release platform key, sha256 hex from SHA256SUMS)
  platforms = {
    aarch64-darwin = {
      key = "darwin-arm64";
      sha256 = "56b5e194d485ced555667b8ba3276157a8272e9ecde9e001e428af80985bdd9b";
    };
    x86_64-darwin = {
      key = "darwin-x64";
      sha256 = "f997a088613514ac97d913aeea7642094d84fe6d46854ff7e64e2c12e536dc50";
    };
    aarch64-linux = {
      key = "linux-arm64";
      sha256 = "42805cd5615952fcbbfc9c56b04f8feb84395134952e169a6cdc8d7676975666";
    };
    x86_64-linux = {
      key = "linux-x64";
      sha256 = "811c6f2c9e7aaee252b5404252e556fb713aa209c1f7f924226aa77d4ef70cb5";
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
