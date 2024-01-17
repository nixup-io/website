{
  description = "Nix flake for the Nixup marketing website using Jekyll";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    devshell = {
      url = "github:numtide/devshell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, devshell }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ devshell.overlays.default ];
        };
        gems = pkgs.bundlerEnv rec {
          name = "nixup-marketing-website-gems";
          ruby = pkgs.ruby_3_2;
          gemdir = ./.;
        };
      in
      {
        devShells = rec {
          default = nixup-marketing-website;
          nixup-marketing-website = pkgs.devshell.mkShell {
            name = "nixup-marketing-website";
            packages = [
              gems
              (pkgs.lowPrio gems.wrappedRuby)
              pkgs.nodePackages.prettier
              pkgs.rsync
            ];
            env = [
              {
                name = "BUNDLE_FORCE_RUBY_PLATFORM";
                eval = "1";
              }
            ];
            commands = [
              {
                name = "update:gems";
                category = "Dependencies";
                help = "Update `Gemfile.lock` and `gemset.nix`";
                command = ''
                  ${pkgs.ruby_3_2}/bin/bundle lock
                  ${pkgs.bundix}/bin/bundix
                '';
              }
              {
                name = "upgrade:gems";
                category = "Dependencies";
                help = "Update `Gemfile.lock` and `gemset.nix`";
                command = ''
                  ${pkgs.ruby_3_2}/bin/bundle lock --update
                  ${pkgs.bundix}/bin/bundix
                '';
              }
              {
                name = "lint:check";
                category = "Linting";
                help = "Check for linting errors";
                command = ''
                  set +e
                  rubocop
                '';
              }
              {
                name = "lint:fix";
                category = "Linting";
                help = "Fix linting errors";
                command = ''
                  set +e
                  rubocop -A
                '';
              }
              {
                name = "site:deploy";
                help = "Deploy the website";
                command = ''
                  jekyll build && rsync -v -rz --checksum --delete ./_site/ app-1:/var/www/marketing
                '';
              }
            ];
          };
        };
      }
    );
}
