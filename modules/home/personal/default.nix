{ ... }:

{
  imports = [
    ./packages.nix
  ];

  programs.git = {
    userName = "Jason Carter";
    userEmail = "jasonwccodes@gmail.com";
  };
}
