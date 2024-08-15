{ lib, ... }:
{
  imports = [
#    ./nvidia.nix
  ];

#  options.modules.graphics = {
   # nvidia = lib.mkEnableOption "Nvidia graphics module";
  #};
}
