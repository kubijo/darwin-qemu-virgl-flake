{
  stdenv,
  lib,
  meson,
  ninja,
  python3,
  pkg-config,
  libepoxy-src,
  angle,
}:

# libepoxy patched to dispatch to ANGLE's libEGL on darwin.
#
# Two patches:
#  - libgl-path.patch: nixpkgs patch that lets us inject the libGL search path
#    via -DLIBGL_PATH compile flag. We point it at ANGLE's lib directory so
#    libepoxy dlopens ANGLE's libEGL.dylib at runtime.
#  - akihikodaki.patch: from
#    https://gist.github.com/akihikodaki/87df4149e7ca87f18dc56807ec5a1bc5
#    teaches libepoxy how to talk to ANGLE-EGL on darwin.

stdenv.mkDerivation {
  pname = "libepoxy";
  version = "darwin-angle";
  src = libepoxy-src;

  nativeBuildInputs = [
    meson
    ninja
    python3
    pkg-config
  ];
  buildInputs = [ angle ];

  patches = [
    ../patches/libepoxy-libgl-path.patch
    ../patches/libepoxy-akihikodaki.patch
  ];

  postPatch = ''
    patchShebangs src/*.py
  '';

  mesonFlags = [
    "-Degl=yes"
  ];

  env.NIX_CFLAGS_COMPILE = ''-DLIBGL_PATH="${lib.getLib angle}/lib"'';

  meta = {
    description = "libepoxy patched for ANGLE-EGL on darwin";
    homepage = "https://github.com/anholt/libepoxy";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
}
