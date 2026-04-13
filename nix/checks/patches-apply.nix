# Fast smoke check: verify each vendored patch still applies cleanly against
# its pinned source. Catches drift the moment we bump a `*-src` flake input
# without re-rolling the patch — without paying for a full QEMU build.
{
  runCommand,
  gnupatch,
  qemu-src,
  libepoxy-src,
}:

let
  patchesDir = ../../patches;

  # Apply a patch with --dry-run inside the source tree.
  # `*-src` flake inputs are auto-unpacked by Nix into directories, so we
  # just copy the directory in (read-only store paths can't be patched in
  # place). Fails the build with patch's stderr on failure.
  checkPatch =
    {
      name,
      src,
      patch,
    }:
    runCommand "patch-apply-${name}"
      {
        inherit src;
        nativeBuildInputs = [ gnupatch ];
      }
      ''
        mkdir work && cd work
        cp -r $src/. .
        chmod -R u+w .
        echo "==> Dry-run: ${name} <- ${baseNameOf (toString patch)}"
        patch -p1 --dry-run < ${patch}
        echo "OK" > $out
      '';

in
{
  qemu-akihikodaki = checkPatch {
    name = "qemu-akihikodaki";
    src = qemu-src;
    patch = "${patchesDir}/qemu-akihikodaki-10.0.0.patch";
  };

  qemu-skip-macos-icon = checkPatch {
    name = "qemu-skip-macos-icon";
    src = qemu-src;
    patch = "${patchesDir}/qemu-skip-macos-icon.patch";
  };

  libepoxy-libgl-path = checkPatch {
    name = "libepoxy-libgl-path";
    src = libepoxy-src;
    patch = "${patchesDir}/libepoxy-libgl-path.patch";
  };

  libepoxy-akihikodaki = checkPatch {
    name = "libepoxy-akihikodaki";
    src = libepoxy-src;
    patch = "${patchesDir}/libepoxy-akihikodaki.patch";
  };
}
