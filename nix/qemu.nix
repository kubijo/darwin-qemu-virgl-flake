{
  stdenv,
  lib,
  pkg-config,
  ninja,
  python3,
  python313Packages,
  dtc,
  glib,
  libslirp,
  pixman,
  darwin,
  qemu-src,
  angle,
  libepoxy,
  virglrenderer,
  targetList ? "aarch64-softmmu",
}:

# QEMU 10.0.0 with the macOS texture-borrowing patch from
# https://gist.github.com/akihikodaki/87df4149e7ca87f18dc56807ec5a1bc5
# applied, configured for HVF + cocoa display + virgl over ANGLE.
#
# Key configure flags:
#  --enable-cocoa  : QEMU's native macOS UI backend (provides the GL context
#                    that virgl renders into; egl-headless is not available
#                    on macOS because there's no native EGL).
#  --enable-hvf    : Apple Silicon hypervisor (Hypervisor.framework).
#                    Requires com.apple.security.hypervisor entitlement on the
#                    output binary — handled by darwin.sigtool.
#  --enable-vmnet  : macOS-native NAT/host networking via vmnet framework
#                    (alternative to slirp; needs com.apple.vm.networking
#                    entitlement to run unprivileged).
#  --enable-pvg    : Paravirtualized graphics for Apple GPU (Apple's own
#                    virtio-gpu equivalent).
#  --enable-slirp  : User-mode networking. Required by `-netdev user` for
#                    port-forwarding-style host networking without entitlements.
#  --enable-opengl + --enable-virglrenderer : the actual virgl path.

stdenv.mkDerivation {
  pname = "qemu-virgl";
  version = "10.0.0";
  src = qemu-src;

  nativeBuildInputs = [
    pkg-config
    ninja
    python3
    python313Packages.distlib
  ];
  buildInputs = [
    dtc
    glib
    libslirp
    pixman
    darwin.sigtool
    angle
    libepoxy
    virglrenderer
  ];

  dontUseMesonConfigure = true;
  dontStrip = true;
  # `qemu-src` is a flake input — Nix auto-unpacks the tarball to a directory,
  # so stdenv's default unpackPhase (cp -r) handles it. No manual tar needed.

  patches = [
    ../patches/qemu-akihikodaki-10.0.0.patch
    ../patches/qemu-skip-macos-icon.patch
  ];

  configureFlags = [
    "--disable-strip"
    "--target-list=${targetList}"
    "--disable-dbus-display"
    "--disable-plugins"
    "--enable-slirp"
    "--enable-tcg"
    "--enable-virtfs"
    # macOS
    "--enable-cocoa"
    "--enable-hvf"
    "--enable-vmnet"
    "--enable-pvg"
    # OpenGL
    "--enable-opengl"
    "--enable-virglrenderer"
  ];

  preBuild = "cd build";

  env.NIX_CFLAGS_COMPILE = "-Wno-error=implicit-function-declaration";

  meta = {
    description = "QEMU 10.0.0 patched for macOS Apple Silicon with virgl-over-ANGLE GPU acceleration";
    homepage = "https://www.qemu.org/";
    license = lib.licenses.gpl2Plus;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "qemu-system-aarch64";
  };
}
