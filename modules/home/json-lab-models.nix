# Models served by the DGX Sparks through json-lab's inference.json.lab, for
# the harness configs in ./json-lab-inference.nix and ./deepseek-harness.nix.
# Ids are the served names from json-inference (github.com/jasonwc/json-inference,
# models/*.toml); only one runs at a time, and GET /v1/models says which.
{
  baseURL = "http://inference.json.lab/v1";

  models = [
    {
      id = "gpt-oss-120b";
      name = "gpt-oss-120b (1 Spark)";
      contextWindow = 131072;
    }
    {
      id = "gpt-oss-120b-tp2";
      name = "gpt-oss-120b (2 Sparks)";
      contextWindow = 131072;
    }
    {
      id = "qwen3.8-flash-next";
      name = "Qwen3.8-Flash-Next NVFP4";
      contextWindow = 262144;
    }
    {
      id = "GLM-5.3-Flash-EXL3";
      name = "GLM-5.3-Flash EXL3";
      contextWindow = 850000;
    }
    {
      id = "DeepSeek-v4.1-Flash-EXL3";
      name = "DeepSeek-V4.1-Flash EXL3";
      contextWindow = 600000;
      # Thinks unless told not to; dsh needs this to turn thinking off.
      deepseekThinking = true;
    }
  ];

  maxTokens = 32768;
}
