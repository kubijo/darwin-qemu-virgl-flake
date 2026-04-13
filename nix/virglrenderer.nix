{
  stdenv,
  lib,
  meson,
  ninja,
  python3,
  pkg-config,
  virglrenderer-src,
  angle,
  libepoxy,
}:

# virglrenderer from akihikodaki's macOS branch — translates guest GL/GLES
# calls to host GL via ANGLE (which in turn translates to Metal).

stdenv.mkDerivation {
  pname = "virglrenderer";
  version = "akihikodaki-darwin";
  src = virglrenderer-src;

  nativeBuildInputs = [
    meson
    ninja
    python3
    pkg-config
  ];
  buildInputs = [
    angle
    libepoxy
  ];

  meta = {
    description = "virglrenderer (akihikodaki/macos branch) — VirGL backed by ANGLE→Metal on darwin";
    homepage = "https://gitlab.freedesktop.org/virgl/virglrenderer";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
}
