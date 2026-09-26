{ pkgs, lib, ... }:

# DeepSeek's agent harness, `dsh` (github.com/deepseek-ai/deepseek-harness).
# It's a developer preview that ships only on npm, so this is a pinned npx
# wrapper rather than a Nix build. Bump with `npm view @deepseek-ai/dsh
# dist-tags` and set `version` to the `latest` tag.
#
# Everything that would send session data to DeepSeek is off: OTel feedback
# telemetry (via the wrapper's environment, so it holds from any launcher) and
# the session-log upload that rides along on DeepSeek requests (a home-level
# patch). Hosted DeepSeek still works once a key is entered on the Models page;
# the key stays in ~/.dsh/.credentials.yaml, never in Nix.
let
  version = "0.1.5-rc.3";
  inference = import ./json-lab-models.nix;

  dsh = pkgs.writeShellApplication {
    name = "dsh";
    runtimeInputs = [ pkgs.nodejs_24 ];
    text = ''
      export DSH_TELEMETRY_DISABLED=1
      export DSH_TELEMETRY_MODE=DISABLED
      exec npx --yes "@deepseek-ai/dsh@${version}" "$@"
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

  # The Sparks as a provider. Seeded into the web and headless profiles' own
  # patches (the file the Models page edits) only if they don't exist yet, so
  # providers added in the UI aren't shadowed by a fixed layer. Pick a Spark
  # model in the web UI, or for headless add an agent-default-model row with
  # provider json-lab.
  jsonLabProvider = yaml.generate "json-lab.cordis.patch.yml" [
    {
      id = "llm-pi-ai";
      config.providers.json-lab = {
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
            inherit (m) id;
          }
          // lib.optionalAttrs (m.deepseekThinking or false) {
            compat.thinkingFormat = "deepseek";
          }
        ) inference.models;
      };
    }
  ];
in
{
  home.packages = [ dsh ];

  home.file.".dsh/cordis.patch.yml".source = homePatch;

  home.activation.dshJsonLabProvider = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for profile in web headless; do
      patch="$HOME/.dsh/profiles/$profile/cordis.patch.yml"
      # Absent, or still dsh's own starter (comments and an empty `[]`).
      if [ ! -e "$patch" ] || ! grep -qvE '^[[:space:]]*(#.*|\[\][[:space:]]*)?$' "$patch"; then
        run mkdir -p "$(dirname "$patch")"
        run install -m 0644 ${jsonLabProvider} "$patch"
      fi
    done
  '';
}
