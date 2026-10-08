{ pkgs, lib, ... }:

# opencode and pi pointed at the DGX Sparks (inference.json.lab), alongside
# the ChatGPT subscription (sign in once: opencode `/connect` → OpenAI →
# ChatGPT Pro/Plus, pi `/login` → ChatGPT). Both pickers are narrowed to those
# two so swapping is quick. The model list lives in ./json-lab-models.nix.
# vLLM needs no key, but both clients insist on one, hence the placeholders.
# It also rejects the `developer` role these clients use for reasoning models,
# so the system prompt goes as `system` (supportsDeveloperRole = false).
let
  inference = import ./json-lab-models.nix;
in
{
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    # `/models` (or F2 through recents) then only offers ChatGPT and the Sparks.
    enabled_providers = [
      "openai"
      "json-lab"
    ];
    provider.json-lab = {
      npm = "@ai-sdk/openai-compatible";
      name = "json-lab (DGX Sparks)";
      options = {
        baseURL = inference.baseURL;
        apiKey = "unused";
      };
      models = builtins.listToAttrs (
        map (m: {
          name = m.id;
          value = {
            inherit (m) name;
            limit = {
              context = m.contextWindow;
              output = inference.maxTokens;
            };
          };
        }) inference.models
      );
    };
  };

  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers.json-lab = {
      baseUrl = inference.baseURL;
      api = "openai-completions";
      apiKey = "unused";
      compat.supportsDeveloperRole = false;
      models = map (
        m:
        {
          inherit (m) id name contextWindow;
          inherit (inference) maxTokens;
          reasoning = true;
          input = [ "text" ];
        }
        # The DeepSeek recipe rejects pi's default reasoning_effort ("medium";
        # it takes low/high/xhigh/max), so leave the effort to the server.
        // (if m.deepseekThinking or false then { compat.supportsReasoningEffort = false; } else { })
      ) inference.models;
    };
  };

  # Ctrl+P in pi cycles ChatGPT and the Sparks only (`/model` still lists
  # everything signed in). pi writes settings.json itself — default model,
  # theme, changelog version — so merge this one key rather than own the file.
  home.activation.piEnabledModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.pi/agent/settings.json"
    run mkdir -p "$(dirname "$settings")"
    [ -s "$settings" ] || run install -m 0644 ${pkgs.writeText "pi-settings.json" "{}\n"} "$settings"
    tmp=$(mktemp)
    ${pkgs.jq}/bin/jq '.enabledModels = ["openai-codex/*", "json-lab/*"]' "$settings" > "$tmp"
    if cmp -s "$tmp" "$settings"; then rm -f "$tmp"; else run mv "$tmp" "$settings"; fi
  '';
}
