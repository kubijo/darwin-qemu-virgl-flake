# darwin-qemu-virgl-flake

Reproducible Nix flake that builds [QEMU](https://www.qemu.org/) for **macOS Apple Silicon** with **virgl** GPU
acceleration backed by **ANGLE** (OpenGL ES on Metal).

Solves the long-standing problem that vanilla QEMU on macOS has no usable virgl support, so guest GL operations like
`glReadPixels` fail (`GL_OUT_OF_MEMORY`) and Wayland screen capture, GPU-accelerated rendering benchmarks, and similar
workloads don't work inside the guest.

## Why this exists

Upstream QEMU does not ship working macOS virgl support. The
[Akihiko Odaki patchset](https://gist.github.com/akihikodaki/87df4149e7ca87f18dc56807ec5a1bc5) that adds it has lived
out-of-tree for years. The Homebrew taps that package it
([startergo](https://github.com/startergo/homebrew-qemu-virgl-kosmickrisp),
[knazarov](https://github.com/knazarov/homebrew-qemu-virgl)) suffer from patches drifting against moving upstream
master, missing dependencies in pre-built bottles, manual codesigning + entitlement song-and-dance, and zero
reproducibility across machines.

This flake fixes all of that:

- **Pinned everything**: QEMU 10.0.0 release tarball, ANGLE/Chromium snapshot, libepoxy fork, virglrenderer fork — all
  locked at known-good revisions in `flake.lock`, no master tracking, no patch drift.
- **Reproducible**: same closure on every machine, no per-host brew state.
- **One command**: `nix run github:kubijo/darwin-qemu-virgl-flake -- -display cocoa,gl=es ...`
- **Composable**: individual `angle`, `libepoxy`, `virglrenderer` packages are also exposed if you want to build
  something else against them.

## Usage

### As a flake input

```nix
{
  inputs.darwin-qemu-virgl.url = "github:kubijo/darwin-qemu-virgl-flake";

  outputs = { self, nixpkgs, darwin-qemu-virgl, ... }: {
    # Use the QEMU binary in your script/derivation:
    # ${darwin-qemu-virgl.packages.aarch64-darwin.default}/bin/qemu-system-aarch64
  };
}
```

### Direct invocation

```sh
# Build the QEMU binary locally
nix build github:kubijo/darwin-qemu-virgl-flake

# Or run it directly
nix run github:kubijo/darwin-qemu-virgl-flake -- \
  -accel hvf \
  -machine virt \
  -cpu max -smp 4 -m 4G \
  -device virtio-gpu-gl-pci,xres=1280,yres=720 \
  -display cocoa,gl=es \
  ...
```

### Available outputs

```
packages.aarch64-darwin.qemu-virgl   # The full QEMU build (default)
packages.aarch64-darwin.angle        # ANGLE dylibs + headers
packages.aarch64-darwin.libepoxy     # libepoxy patched for ANGLE-EGL on darwin
packages.aarch64-darwin.virglrenderer # virglrenderer (akihikodaki/macos branch)
apps.aarch64-darwin.default          # qemu-system-aarch64 entrypoint
```

## Display backends

On macOS, the working virgl display is **`cocoa,gl=es`** — opens a small native QEMU window where virgl gets its
Metal-backed GL context via ANGLE.

`egl-headless` may appear in `qemu-system-aarch64 -display help` but fails at runtime with *"egl: not available on this
platform"* — macOS has no native EGL.

## Updating pins

```sh
# Update everything to the latest revisions
nix flake update

# Or update one input at a time
nix flake lock --update-input qemu-src
```

If the QEMU pin is bumped, the Akihiko texture-borrowing patch in `patches/qemu-akihikodaki-10.0.0.patch` may need
re-rolling against the new revision — the patch is authored specifically against QEMU 10.0.0.

## Credits

This flake is **derived from the prior art assembled in [mrkuz/macos-config](https://github.com/mrkuz/macos-config)** —
specifically the `pkgs/darwin/{applications,development}` derivations and the patch files. mrkuz did the hard work of
figuring out which combination of patches, source pins, and configure flags actually produces a working stack. This
flake repackages the same building blocks as a standalone, idiomatic Nix flake.

The underlying technical work belongs to:

- **[Akihiko Odaki](https://github.com/akihikodaki)** — author of the QEMU and virglrenderer macOS patches, and the
  [overview gist](https://gist.github.com/akihikodaki/87df4149e7ca87f18dc56807ec5a1bc5) that documents the architecture
- **[The ANGLE project](https://chromium.googlesource.com/angle/angle/)** — Google's OpenGL ES → Metal translation layer
- **[QEMU](https://www.qemu.org/)**, **[virglrenderer](https://gitlab.freedesktop.org/virgl/virglrenderer)**,
  **[libepoxy](https://github.com/anholt/libepoxy)** — the upstream projects

## License

GPL-2.0-or-later, matching QEMU. See [LICENSE](LICENSE).

The bundled patches retain their original authors' rights. ANGLE itself is BSD-3, libepoxy is MIT, virglrenderer is MIT
— all GPL-2.0 compatible.
