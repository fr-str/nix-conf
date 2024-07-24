{ lib, ... }:
{
  options = {
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "System username";
      };

      description = lib.mkOption {
        type = lib.types.str;
        description = "System user description ie. First and last name";
      };
    };
  };
}
