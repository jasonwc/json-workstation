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

      # Pin the json-lab k3s nodes to their static IPs: they don't take DHCP leases,
      # so Firewalla's `.lan` records are incomplete (json-lab-2 missing) and answer
      # AAAA with `::`, which ssh tries first and which lands on the local machine.
      "json-lab-1 json-lab-1.lan" = {
        HostName = "192.168.124.10";
        User = "jasonwc";
      };
      "json-lab-2 json-lab-2.lan" = {
        HostName = "192.168.124.11";
        User = "jasonwc";
      };
      "json-lab-3 json-lab-3.lan" = {
        HostName = "192.168.124.12";
        User = "jasonwc";
      };

      "*".ControlPath = "none";
    };
  };
}
