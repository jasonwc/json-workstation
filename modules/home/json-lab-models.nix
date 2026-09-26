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
      id = "qwen3.8-27b-nvfp4";
      name = "Qwen3.8-27B NVFP4 (1 Spark)";
      contextWindow = 262144;
    }
    {
      id = "MiMo-v2.6-Flash";
      name = "MiMo-V2.6-Flash (EAGLE or DFlash)";
      contextWindow = 1048576;
    }
    {
      id = "deepseek-v4-flash-vision-exp";
      name = "DeepSeek-V4-Flash DSpark";
      contextWindow = 1048576;
      deepseekThinking = true;
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
