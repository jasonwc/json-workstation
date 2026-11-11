# herdr-core (`hc`), the runtime under the Herdr desktop app and the Herdr
# mobile apps, from upstream's prebuilt releases, pinned declaratively.
# nixpkgs has only the herdr TUI (`pkgs.herdr`), a separate server whose
# terminals the apps can't see.
#
# Replaces upstream's `curl -fsSL https://releases.herdr.dev/core/install.sh | sh`,
# which installs into ~/.local/bin. Don't use `hc update` or `hc machine update`
# on these hosts: both swap the binary outside Nix. To bump, run
# `scripts/bump-agents.sh herdr-core`, which reads the version and per-target
# sha256 (plain hex) from https://releases.herdr.dev/core/latest.json.
#
# Linux builds are static-pie binaries, so no patching is needed. The macOS
# tarball also ships a signed `Herdr Core.app` (identifier dev.herdr.core),
# which is what upstream's installer puts in place on Macs. We keep that bundle
# and point bin/herdr-core at its executable, so macOS privacy grants follow the
# signature rather than a store path that changes with every bump.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.1.20";

  # nix system -> (release target, sha256 hex from the release manifest)
  platforms = {
    aarch64-darwin = {
      target = "macos-aarch64";
      sha256 = "e58985d3fef6e909f33d3c5a4426e4898c81564a557d4636591cec9e3a06af26";
    };
    x86_64-darwin = {
      target = "macos-x86_64";
      sha256 = "36c0331c3ffea0ffaada195b89a3c7496f7f3fc5bf35e4605c19c84e5c205a56";
    };
    aarch64-linux = {
      target = "linux-aarch64";
      sha256 = "5f3037379d15cc76cfc72d2fd1a4262ea1c5b24df278bf7cfd8adcff7b914862";
    };
    x86_64-linux = {
      target = "linux-x86_64";
      sha256 = "ac6b86890c451a37584620aaa438b71bc0d0bd430a2e7c1d7e095f052c414e74";
    };
  };

  plat =
    platforms.${stdenvNoCC.hostPlatform.system}
      or (throw "herdr-core-native: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "herdr-core-native";
  inherit version;

  src = fetchurl {
    url = "https://releases.herdr.dev/core/${version}/herdr-core-${plat.target}.tar.gz";
    inherit (plat) sha256;
  };

  # The tarball's entries sit at its top level (no wrapping directory).
  sourceRoot = ".";

  dontStrip = true; # keep the macOS code signature intact
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/licenses/herdr-core
    if [ -d "Herdr Core.app" ]; then
      mkdir -p $out/Applications
      cp -R "Herdr Core.app" $out/Applications/
      ln -s "$out/Applications/Herdr Core.app/Contents/MacOS/herdr-core" $out/bin/herdr-core
    else
      install -m755 herdr-core $out/bin/herdr-core
    fi
    ln -s herdr-core $out/bin/hc
    cp LICENSE THIRD-PARTY-NOTICES $out/share/licenses/herdr-core/
    runHook postInstall
  '';

  meta = {
    description = "herdr-core (hc): terminals for coding agents, the runtime the Herdr apps talk to";
    homepage = "https://herdr.dev/core/";
    license = lib.licenses.asl20;
    mainProgram = "hc";
    platforms = lib.attrNames platforms;
  };
}
