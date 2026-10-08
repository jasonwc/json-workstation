{ pkgs, lib, ... }:

# DeepSeek's agent harness, `dsh` (github.com/deepseek-ai/deepseek-harness).
# It's a developer preview that ships only on npm, so this is a pinned npx
# wrapper rather than a Nix build. `scripts/bump-agents.sh dsh` moves
# `version` to npm's `latest` tag.
#
# Everything that would send session data to DeepSeek is off: OTel feedback
# telemetry (via the wrapper's environment, so it holds from any launcher) and
# the session-log upload that rides along on DeepSeek requests (a home-level
# patch). Hosted DeepSeek still works once a key is entered on the Models page;
# the key stays in ~/.dsh/.credentials.yaml, never in Nix.
let
  version = "0.2.0-rc.2";
  inference = import ./json-lab-models.nix;

  # dsh 0.2.x boots profiles through node-addon-require-builtin, which finds a
  # V8 getter by pattern-matching the running node binary's machine code. It
  # recognises nodejs.org's builds but not nixpkgs' nodejs_24 ("Unsupported/
  # no-getter"), so the wrapper runs on the official binary. This pin needn't
  # track latest; bump it when dsh asks for a newer Node. Hashes are from
  # https://nodejs.org/dist/v<version>/SHASUMS256.txt.
  node = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "nodejs-official";
    version = "24.21.0";

    src =
      let
        platforms = {
          aarch64-darwin = {
            key = "darwin-arm64";
            sha256 = "6239d4cf92d864487ec8cd3615038f7b67e7f58b77b21cd2f09ea9fbd68065fe";
          };
          x86_64-linux = {
            key = "linux-x64";
            sha256 = "fd8e59d5a511510f6a298afb548f18c7d2b1be404d8b4a27d94fbe49f56cb2d6";
          };
          aarch64-linux = {
            key = "linux-arm64";
            sha256 = "6ad1325edbdb5649c379b75a237147a666c95d4f9ae8d340fef2d1575d289ad2";
          };
        };
        plat =
          platforms.${pkgs.stdenv.hostPlatform.system}
            or (throw "dsh: no official Node pin for ${pkgs.stdenv.hostPlatform.system}");
      in
      pkgs.fetchurl {
        url = "https://nodejs.org/dist/v${finalAttrs.version}/node-v${finalAttrs.version}-${plat.key}.tar.xz";
        inherit (plat) sha256;
      };

    dontStrip = true;
    nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
    buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.stdenv.cc.cc.lib ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r bin include lib share $out/
      runHook postInstall
    '';
  });

  dsh = pkgs.writeShellApplication {
    name = "dsh";
    runtimeInputs = [ node ];
    text = ''
      export DSH_TELEMETRY_DISABLED=1
      export DSH_TELEMETRY_MODE=DISABLED
      exec npx --yes --package "@deepseek-ai/dsh@${version}" -- dsh "$@"
    '';
  };

  yaml = pkgs.formats.yaml { };

  # The home-level patch outranks every profile's own patch and replaces a
  # row's whole config, so it only holds rows the Models page never edits.
  homePatch = yaml.generate "cordis.patch.yml" [
    {
      id = "session-log-deepseek";
      config.enabled = false;
    }
  ];

  # Provider routes, merged into each profile's own patch — the user layer the
  # Models page edits (0.2.x imports the old ~/.dsh/settings.yaml into it) —
  # since a home-patch llm-pi-ai row would shadow providers added there.
  # json-lab is rewritten on every switch so it can't drift from
  # ./json-lab-models.nix.
  providers = pkgs.writeText "dsh-providers.json" (
    builtins.toJSON {
      # ChatGPT subscription: pi-ai's installed catalog, no key. Sign in once
      # with "Sign in with ChatGPT" on the Models page.
      openai-codex = { };

      # The Sparks.
      json-lab = {
        api = "openai-completions";
        baseURL = inference.baseURL;
        # vLLM runs without auth, but pi-ai's OpenAI-compatible client
        # requires a credential.
        headers.Authorization = "Bearer unused";
        compat = {
          supportsDeveloperRole = false;
          maxTokensField = "max_tokens";
        };
        models = map (
          m:
          {
            inherit (m) id name contextWindow;
            maxTokens = inference.maxTokens;
          }
          // lib.optionalAttrs (m.deepseekThinking or false) {
            compat.thinkingFormat = "deepseek";
          }
        ) inference.models;
      };
    }
  );
in
{
  home.packages = [ dsh ];

  home.file.".dsh/cordis.patch.yml".source = homePatch;

  home.activation.dshProviders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for profile in web headless; do
      patch="$HOME/.dsh/profiles/$profile/cordis.patch.yml"
      run mkdir -p "$(dirname "$patch")"
      [ -s "$patch" ] || run install -m 0644 ${pkgs.writeText "empty.patch.yml" "[]\n"} "$patch"
      # Add the llm-pi-ai row if missing, replace json-lab, and add
      # openai-codex unless the Models page already holds one. Other rows
      # and providers are left alone.
      run ${pkgs.yq-go}/bin/yq -i '
        (select((map(select(.id == "llm-pi-ai")) | length) == 0) | . += [{"id": "llm-pi-ai"}]) // . |
        with(.[] | select(.id == "llm-pi-ai");
          .config.providers.json-lab = (load("${providers}").json-lab | .. style="") |
          .config.providers.openai-codex |= (. // {}))
      ' "$patch"
    done
  '';
}
