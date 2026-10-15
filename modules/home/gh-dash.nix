{ lib, pkgs, ... }:

let
  # Every member of the paper forest (~/workspace/paper-forest/forester.toml).
  # Keep in sync when members are added or removed there.
  forestRepos = [
    # OS
    "papercomputeco/stereOS"
    "papercomputeco/agentd"
    "papercomputeco/stereosd"
    "papercomputeco/speaker-wire"
    "papercomputeco/masterblaster"
    "pcc-labs/capstan"
    # Platform
    "papercomputeco/cloud"
    "papercomputeco/tenant-api"
    "papercomputeco/paper"
    "papercomputeco/tko"
    "papercomputeco/console.papercompute.com"
    "papercomputeco/infra"
    "papercomputeco/dashboards"
    # Telemetry
    "papercomputeco/tapes"
    "papercomputeco/tapesctl"
    "papercomputeco/tapes-harnesses"
    "papercomputeco/pgtapes"
    "papercomputeco/search-cassette"
    "papercomputeco/skills-cassette"
    "papercomputeco/export-cassette"
    "papercomputeco/session-chat-cassette"
    "papercomputeco/labels-cassette"
    "papercomputeco/summary-cassette"
    # Monetization
    "papercomputeco/pdoubloons"
    "papercomputeco/warehouse"
    # Backoffice
    "papercomputeco/opencost-s3-exporter"
    "papercomputeco/email-templates"
    # Tooling
    "papercomputeco/daggerverse"
    "papercomputeco/paperadm"
    # Skills / ecosystem
    "papercomputeco/skills"
    "papercomputeco/flake-skills"
    # Sites
    "papercomputeco/stereos.ai"
    "papercomputeco/site"
    "papercomputeco/tapes.dev"
    "pcc-labs/wireframe"
    # Demos
    "papercomputeco/pokemon"
    "pcc-labs/pokemon-kafka"
    "pcc-labs/deepgram-demo"
    "pcc-labs/tapes-ai-sdk-example"
    "pcc-labs/agent-orchestrator-demo"
    "pcc-labs/overdub"
    "pcc-labs/moonlander"
    "pcc-labs/sweeper"
    "pcc-labs/openclaw-in-a-box"
    "pcc-labs/mb-tapes-mock"
    # Org
    "papercomputeco/.github"
  ];

  inForest = lib.concatMapStringsSep " " (r: "repo:${r}") forestRepos;

  # `gh greptile`: whether each of my open PRs is ready to merge (CI, Greptile
  # score, review), or the rendered Greptile summary for one PR. The gh module
  # names extensions by pname, which writeShellApplication doesn't set.
  gh-greptile =
    pkgs.writeShellApplication {
      name = "gh-greptile";
      runtimeInputs = [
        pkgs.gh
        pkgs.glow
        pkgs.less
        pkgs.ncurses
      ];
      # jq programs are single-quoted on purpose.
      excludeShellChecks = [ "SC2016" ];
      text = builtins.readFile ./gh-greptile.sh;
    }
    // {
      pname = "gh-greptile";
    };
in
{
  # Managing gh-dash makes home-manager own ~/.local/share/gh/extensions, so
  # every gh extension has to be declared here (gh-stack included).
  programs.gh.extensions = [
    pkgs.gh-stack
    gh-greptile
  ];

  programs.gh-dash = {
    enable = true;
    settings = {
      prSections = [
        {
          title = "Mine";
          filters = "is:open author:@me";
        }
        {
          title = "Review requested";
          filters = "is:open review-requested:@me";
        }
        {
          title = "Involved";
          filters = "is:open involves:@me -author:@me ${inForest}";
        }
        {
          title = "Forest";
          filters = "is:open ${inForest}";
        }
        {
          title = "Merged (mine)";
          filters = "is:merged author:@me ${inForest}";
          limit = 10;
        }
      ];
      issuesSections = [
        {
          title = "Assigned";
          filters = "is:open assignee:@me";
        }
        {
          title = "Created";
          filters = "is:open author:@me ${inForest}";
        }
      ];
      keybindings.prs = [
        {
          key = "ctrl+g";
          name = "greptile";
          command = "gh greptile {{.RepoName}} {{.PrNumber}}";
        }
      ];
      defaults = {
        view = "prs";
        preview = {
          open = true;
          width = 70;
        };
      };
    };
  };
}
