{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }:
    let
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      forAllSystems =
        nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
    in {
      packages = forAllSystems (system: rec {
        default = firmware;

        firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
          name = "firmware";

          nativeBuildInputs = with pkgs; [
            protobuf
            python3Packages.grpcio-tools
          ];

          src = nixpkgs.lib.sourceFilesBySuffices self [
            ".board"
            ".cmake"
            ".conf"
            ".defconfig"
            ".dts"
            ".dtsi"
            ".json"
            ".keymap"
            ".overlay"
            ".shield"
            ".yml"
            "_defconfig"
          ];

          board = "nice_nano@2.0.0";
          shield = "sweep_%PART%";

          enableZmkStudio = true;

          zephyrDepsHash =
            "sha256-sEC1BhOdN00NxEWdyugxdQcuqzM5aY6W0EE5kA0orA4=";

          meta = {
            description = "ZMK firmware";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        };

        flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
        update = zmk-nix.packages.${system}.update;
      });

      devShells = forAllSystems
        (system: { default = zmk-nix.devShells.${system}.default; });
    };
}
