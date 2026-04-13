# Aggregates every flake check into a flat attrset.
# flake.nix calls this once and assigns the result to `checks.<system>`.
{
  pkgs,
  lib,
  qemu-src,
  libepoxy-src,
  treefmtEval,
  self,
}:

let
  patchesApply = import ./patches-apply.nix {
    inherit (pkgs) runCommand gnupatch;
    inherit qemu-src libepoxy-src;
  };

  # Prefix each patches-apply check with `patches-apply-` so they namespace
  # cleanly in `nix flake check` output.
  patchesApplyChecks = lib.mapAttrs' (name: drv: {
    name = "patches-apply-${name}";
    value = drv;
  }) patchesApply;
in

patchesApplyChecks
// {
  formatting = treefmtEval.config.build.check self;
}
