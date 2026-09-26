{ ... }:

# opencode and pi pointed at the DGX Sparks (inference.json.lab), alongside
# their hosted providers. The model list lives in ./json-lab-models.nix.
# vLLM needs no key, but both clients insist on one, hence the placeholders.
# It also rejects the `developer` role these clients use for reasoning models,
# so the system prompt goes as `system` (supportsDeveloperRole = false).
let
  inference = import ./json-lab-models.nix;
in
{
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
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
}
