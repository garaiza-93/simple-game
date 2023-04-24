{
  description = "Basic Rust environment with toolchain and language server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) mkShell rust mesa libGL patchelf rustPlatform wayland xorg;
          inherit (xorg) libX11 libXcursor libXi libXxf86vm libXrandr;

          pname = "simple-game";
          version = "0.1.0";

          libpatch = ''
            patchelf --set-rpath ${libGL}/lib:${mesa}/lib:${wayland}/lib:${libX11}/lib:${libXi}/lib:${libXcursor}/lib:${libXxf86vm}/lib:${libXrandr}/lib \
            $out/bin/${pname}
          '';

          nvimrc = ''local servers = { "rust_analyzer" }
            local caps = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities());
            for _, lsp in ipairs(servers) do
              require("lspconfig")[lsp].setup {capabilities = caps}
            end

            vim.cmd("LspStart");'';
        in
        rec
        {
          # Executed by `nix build`
          packages.default = rustPlatform.buildRustPackage {
            inherit pname version;
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;

            buildInputs = [ patchelf ];

            fixupPhase = libpatch;
          };

          # Executed by `nix run`
          apps.default = flake-utils.lib.mkApp { drv = packages.default; };

          # Used by `nix develop`
          devShells.default = mkShell {

            buildInputs = with pkgs; [
              cargo
              rustc
              clippy
              rustfmt
              rust-analyzer
              pkg-config
            ];

            RUST_SRC_PATH = "${rust.packages.stable.rustPlatform.rustLibSrc}";

            shellHook = ''
              echo '${nvimrc}' > .nvimrc.lua
            '';
          };
        }
      );
}
