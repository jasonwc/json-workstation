{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      controlPath = "none";
    };
    # Pin JSON-MACBOOK16 to its Ethernet IP: the `.lan` name registers stale
    # Firewalla DNS records (multiple A records, some landing on the wrong host),
    # so rely on the reserved IP instead. Update if the DHCP reservation changes.
    matchBlocks."json-macbook16 json-macbook16.lan" = {
      hostname = "192.168.124.141";
      user = "jasonwc";
    };
  };
}
