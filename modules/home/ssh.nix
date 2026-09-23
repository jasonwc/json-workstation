{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # Blocks use upstream ssh_config directive names; attribute names become
    # `Host` patterns.
    settings = {
      # Pin JSON-MACBOOK16 to its Ethernet IP: the `.lan` name registers stale
      # Firewalla DNS records (multiple A records, some landing on the wrong host),
      # so rely on the reserved IP instead. Update if the DHCP reservation changes.
      "json-macbook16 json-macbook16.lan" = {
        HostName = "192.168.124.141";
        User = "jasonwc";
      };

      "*".ControlPath = "none";
    };
  };
}
