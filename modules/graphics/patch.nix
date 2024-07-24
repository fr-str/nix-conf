{ lib, pkgs, attrs }:
let
  patcher = script:
    lib.importJSON (pkgs.runCommandLocal "patch" { nativeBuildInputs = [ pkgs.jq ]; } ''
      bash ${attrs.nvidia-patch}/${script} -j > $out
    '');

  patch = patcher "patch.sh";
  patch-fbc = patcher "patch-fbc.sh";

  driverMod = patch: target: driver:
    driver.overrideAttrs ({ version, preFixup ? "", ... }:
      {
        preFixup = preFixup + ''
          sed -i '${patch.${version}}' $out/lib/${target}.${version}
        '';
      });
in
{
  nvenc = driverMod patch "libnvidia-encode.so";
  nvfbc = driverMod patch-fbc "libnvidia-fbc.so";
}
