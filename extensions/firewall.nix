{ config, lib, ... }:
let
  cfg = config.networking.firewall;

  # tail returns last element of the list
  tail = list: builtins.elemAt list (builtins.length list - 1);

  # parsePort parses single port string: (port || range)[/proto]
  parsePort = str:
    let
      parts = lib.splitString "/" str;
      range = lib.splitString "-" (builtins.head parts);
      isRange = builtins.length range == 2;

      start = lib.toInt (builtins.head range);
      end = if isRange then lib.toInt (tail range) else null;
      protocol = if (builtins.length parts > 1) then tail parts else null;
    in
    {
      port = { from = start; to = end; };
      isRange = isRange;
      isTCP = protocol == "tcp" || protocol == null;
      isUDP = protocol == "udp" || protocol == null;
    };

  # splitPorts returns lists: {tcp, udp, tcpRanges, udpRanges}
  splitPorts = list:
    builtins.foldl'
      (acc: p:
        if p.isRange then
          {
            tcp = acc.tcp;
            udp = acc.udp;
            tcpRanges = if p.isTCP then acc.tcpRanges ++ [ p.port ] else acc.tcpRanges;
            udpRanges = if p.isUDP then acc.udpRanges ++ [ p.port ] else acc.udpRanges;
          }
        else
          {
            tcp = if p.isTCP then acc.tcp ++ [ p.port.from ] else acc.tcp;
            udp = if p.isUDP then acc.udp ++ [ p.port.from ] else acc.udp;
            tcpRanges = acc.tcpRanges;
            udpRanges = acc.udpRanges;
          }
      )
      # Initial
      {
        tcp = [ ];
        udp = [ ];
        tcpRanges = [ ];
        udpRanges = [ ];
      }
      # List to categorise
      list;

in
{
  options.networking.firewall = {
    ports = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "24800" # TCP/UDP
        "51820/udp" # UDP
        "1714-1764" # TCP/UDP range
        "2000-2100/tcp" # TCP range
      ];
      description = "List of ports to be allowed in firewall";
    };
  };

  config = lib.mkIf (cfg.enable && builtins.length cfg.ports > 0) {
    networking.firewall =
      let
        result = splitPorts (map parsePort cfg.ports);
      in
      {
        allowedTCPPorts = result.tcp;
        allowedUDPPorts = result.udp;
        allowedTCPPortRanges = result.tcpRanges;
        allowedUDPPortRanges = result.udpRanges;
      };
  };
}
