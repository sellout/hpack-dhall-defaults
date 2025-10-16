{
  description = "hpack-dhall configuration shared across all of my projects";

  nixConfig = {
    ## NB: This is a consequence of using `self.pkgsLib.runEmptyCommand`, which
    ##     allows us to sandbox derivations that otherwise can’t be.
    allow-import-from-derivation = true;
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = [
      "https://cache.dhall-lang.org"
      "https://cache.garnix.io"
      "https://dhall.cachix.org"
      "https://sellout.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.dhall-lang.org:I9/H18WHd60olG5GsIjolp7CtepSgJmM2CsO813VTmM="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "dhall.cachix.org-1:8laGciue2JBwD49ICFtg+cIF8ddDaW7OFBjDb/dHEAo="
      "sellout.cachix.org-1:v37cTpWBEycnYxSPAgSQ57Wiqd3wjljni2aC0Xry1DE="
    ];
    ## Isolate the build.
    sandbox = "relaxed";
    use-registries = false;
  };

  outputs = {
    flake-utils,
    flaky,
    hall,
    nixpkgs,
    self,
    systems,
  }: let
    pname = "hpack-dhall-defaults";

    supportedSystems = import systems;
  in
    {
      schemas = {
        inherit
          (flaky.schemas)
          overlays
          homeConfigurations
          packages
          devShells
          projectConfigurations
          checks
          formatter
          ;
      };

      overlays = {
        default = final: prev: {
          dhallPackages = prev.dhallPackages.override (old: {
            overrides =
              final.lib.composeExtensions
              (old.overrides or (_: _: {}))
              (self.overlays.dhall final prev);
          });
        };

        dhall = final: prev: dfinal: dprev: {
          ${pname} = self.packages.${final.system}.${pname};
        };
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example self
            ## TODO: Is there something more like `dhallWithPackages`?
            [({pkgs, ...}: {home.packages = [pkgs.dhallPackages.${pname}];})])
          supportedSystems);
    }
    // flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
        flaky.overlays.default
        hall.overlays.default
      ];

      src = pkgs.lib.cleanSource ./.;
    in {
      packages = {
        default = self.packages.${system}.${pname};

        "${pname}" = pkgs.checkedDrv (pkgs.dhallPackages.buildDhallDirectoryPackage {
          src = "${src}/dhall";
          name = pname;
          dependencies = [pkgs.dhallPackages.hall];
          document = true;
        });
      };

      projectConfigurations = flaky.lib.projectConfigurations.dhall {
        inherit pkgs self supportedSystems;
      };

      devShells =
        self.projectConfigurations.${system}.devShells
        // {default = flaky.lib.devShells.default system self [] "";};
      checks = self.projectConfigurations.${system}.checks;
      formatter = self.projectConfigurations.${system}.formatter;
    });

  inputs = {
    ## Flaky should generally be the source of truth for its inputs.
    flaky.url = "github:sellout/flaky";

    flake-utils.follows = "flaky/flake-utils";
    nixpkgs.follows = "flaky/nixpkgs";

    hall = {
      inputs.flaky.follows = "flaky";
      url = "github:sellout/hall";
    };

    ## Unlike `flaky/systems`, this one doesn’t have i686-linux, which isn’t
    ## supported by Dhall.
    systems.url = "github:nix-systems/default";
  };
}
