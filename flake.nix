{
  description = "Breezipe: A step-ingredient table XSL transform and XML format";

  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    jailed-agents.url = "github:jabarszcz/jailed-agents/my-extra-packages";
  };

  outputs = { self, nixpkgs, flake-utils, jailed-agents }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        jailLib = jailed-agents.lib.${system};
        devDeps = with pkgs; [
          gnumake
          libxml2
          libxslt
          validator-nu
        ];
        jailOpts =
          jailLib.commonJailOptions ++ [
            (jailLib.internals.jail.combinators.set-env
              # For claude code, because otherwise it thinks for too long.
              "MAX_THINKING_TOKENS" "8000"
            )
          ];
        agentOpts = {
          extraPkgs = devDeps;
          baseJailOptions = jailOpts;
        };
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "breezipe";
          src = self;
          dontBuild = true;
          installPhase = ''
            mkdir -p $out/share/breezipe
            install -m 644 *.xsl *.xsd *.css *.js $out/share/breezipe/
          '';
        };

        packages.site = pkgs.stdenv.mkDerivation {
          name = "breezipe-site";
          src = self;
          nativeBuildInputs = with pkgs; [ gnumake libxslt pandoc ];
          buildPhase = ''
            make transform
            pandoc README.org -f org -t html5 --standalone \
              --metadata title="Breezipe - Easy recipe markup with step-dependency tables" \
              -o index.html
          '';
          installPhase = ''
            mkdir -p $out/examples $out/pngs
            cp *.xsl *.xsd *.css *.js index.html $out/
            cp examples/*.xml examples/*.xhtml $out/examples/
            cp pngs/* $out/pngs/
          '';
        };

        apps.serve = {
          type = "app";
          program = "${pkgs.writeShellScript "serve-breezipe" ''
            exec ${pkgs.darkhttpd}/bin/darkhttpd \
              ${self.packages.${system}.site} \
              --port "''${1:-8080}"
          ''}";
        };

        checks.transform-examples = pkgs.stdenv.mkDerivation {
          name = "breezipe-check-transform-examples";
          src = self;
          nativeBuildInputs = with pkgs; [ gnumake libxslt validator-nu ];
          buildPhase = "make transform validate-transform";
          installPhase = "touch $out";
        };

        devShells.default = pkgs.mkShell {
          packages = devDeps ++ [
            (jailLib.makeJailedOpencode agentOpts)
            (jailLib.makeJailedClaudeCode agentOpts)
          ];

          # Change the prompt to show that you are in a devShell
          shellHook = "export PS1='dev:\\w > '";
        };

      });
}
