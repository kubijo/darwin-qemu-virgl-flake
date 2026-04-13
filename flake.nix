{
  description = "QEMU with virgl + ANGLE GPU acceleration for macOS Apple Silicon";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # QEMU 10.0.0 release tarball — Akihiko Odaki's macOS patch is authored
    # specifically against this version, so don't bump without re-validating
    # the patch.
    qemu-src = {
      url = "https://download.qemu.org/qemu-10.0.0.tar.xz";
      flake = false;
    };

    # Upstream ANGLE source — used only for the headers in include/.
    # Pinned to the same revision as Chromium snapshot 1379013 ships.
    angle-src = {
      url = "github:google/angle/1433dd4e8a59659f8e16a96f62c9ccedd3ce2e92";
      flake = false;
    };

    # libepoxy fork used as the ANGLE-EGL adapter — pinned to a stable revision
    # that the akihikodaki + libgl-path patches apply against cleanly.
    libepoxy-src = {
      url = "github:anholt/libepoxy/1b6d7db184bb1a0d9af0e200e06a0331028eaaae";
      flake = false;
    };

    # virglrenderer fork from akihikodaki/macos branch — contains the
    # ANGLE-compatible backend that lets virgl talk to ANGLE's EGL surface.
    virglrenderer-src = {
      url = "github:akihikodaki/virglrenderer/4a489584344787ea52226ac50dd9fa86a1f38f90";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      qemu-src,
      angle-src,
      libepoxy-src,
      virglrenderer-src,
    }:
    flake-utils.lib.eachSystem [ "aarch64-darwin" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        angle = pkgs.callPackage ./nix/angle.nix {
          inherit angle-src;
        };
        libepoxy = pkgs.callPackage ./nix/libepoxy.nix {
          inherit libepoxy-src angle;
        };
        virglrenderer = pkgs.callPackage ./nix/virglrenderer.nix {
          inherit virglrenderer-src angle libepoxy;
        };
        qemu-virgl = pkgs.callPackage ./nix/qemu.nix {
          inherit
            qemu-src
            angle
            libepoxy
            virglrenderer
            ;
        };

        treefmtEval = treefmt-nix.lib.evalModule pkgs ./nix/treefmt.nix;
      in
      {
        packages = {
          inherit
            angle
            libepoxy
            virglrenderer
            qemu-virgl
            ;
          default = qemu-virgl;
        };

        apps.default = {
          type = "app";
          program = "${qemu-virgl}/bin/qemu-system-aarch64";
        };

        formatter = treefmtEval.config.build.wrapper;

        # Plain `import`, not `callPackage` — checks is a flat attrset of
        # derivations, not a single derivation, so callPackage's `override`
        # wrappers would leak into the attrset and pollute `nix flake check`.
        checks = import ./nix/checks {
          inherit pkgs;
          inherit (pkgs) lib;
          inherit
            qemu-src
            libepoxy-src
            treefmtEval
            self
            ;
        };
      }
    );
}
