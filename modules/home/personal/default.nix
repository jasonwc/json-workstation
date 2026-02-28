{ ... }:

{
  imports = [
    ./packages.nix
  ];

  programs.git = {
    settings.user = {
      name = "Jason Carter";
      email = "jasonwccodes@gmail.com";
    };
  };
}
