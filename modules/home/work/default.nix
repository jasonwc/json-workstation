{ ... }:

{
  imports = [
    ./packages.nix
  ];

  programs.git = {
    userName = "Jason Carter";
    userEmail = "jason@mechanical-orchard.com";
    extraConfig = {
      co-authors = {
        at  = "Anna Thornton <anna@mechanical-orchard.com>";
        sw  = "Scott Windsor <scott.windsor@mechanical-orchard.com>";
        cw  = "Caleb Washburn <caleb.washburn@mechanical-orchard.com>";
        dl  = "David Laing <david@mechanical-orchard.com>";
        gds = "Gareth Smith <gareth.smith@mechanical-orchard.com>";
        sm  = "Scott Muc <scott.muc@mechanical-orchard.com>";
        pj  = "Porter Joens <porter@mechanical-orchard.com>";
      };
    };
  };
}
