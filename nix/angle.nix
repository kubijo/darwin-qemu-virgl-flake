{
  stdenv,
  lib,
  unzip,
  fetchurl,
  angle-src,
}:

# ANGLE provides OpenGL ES on macOS by translating to Metal.
#
# Building ANGLE from source requires Chromium's depot_tools/gn/autoninja
# stack — gnarly to package. We instead extract the prebuilt dylibs from a
# pinned Chromium snapshot (which Google ships with ANGLE built-in) and pair
# them with the headers from the upstream ANGLE source tree.

let
  # Fetched here (not as a flake input) because Nix's flake input URL parser
  # decodes the `%2F` path separators in Google's storage API URLs, breaking
  # re-fetches with a 404. `fetchurl` preserves the URL exactly.
  chromiumSnapshot = fetchurl {
    name = "chromium-aarch64-darwin-1379013.zip";
    url = "https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Mac_Arm%2F1379013%2Fchrome-mac.zip?alt=media";
    hash = "sha256-7/NUL7BgG9O+gu6WxCFROvi+CWImCjpQG7g5nM2PWeo=";
  };
in

stdenv.mkDerivation {
  pname = "angle";
  version = "chromium-snapshot";
  src = angle-src;

  nativeBuildInputs = [ unzip ];

  buildPhase = ''
    runHook preBuild
    unzip ${chromiumSnapshot}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp 'chrome-mac/Chromium.app/Contents/Frameworks/Chromium Framework.framework/Libraries/libEGL.dylib' $out/lib/
    cp 'chrome-mac/Chromium.app/Contents/Frameworks/Chromium Framework.framework/Libraries/libGLESv2.dylib' $out/lib/
    cp -r include $out
    runHook postInstall
  '';

  meta = {
    description = "ANGLE: OpenGL ES on top of Metal (prebuilt dylibs from Chromium snapshot, headers from upstream)";
    homepage = "https://chromium.googlesource.com/angle/angle/";
    license = lib.licenses.bsd3;
    platforms = [ "aarch64-darwin" ];
  };
}
