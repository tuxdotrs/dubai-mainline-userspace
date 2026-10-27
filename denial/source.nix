# The Denial revision this port uses: its source (packaging files, NixOS
# module) and the ARM64 binaries built from it by cross-build/ (`./build.sh
# denial` in the meta repo), published as a release of this repo (tag
# denial-<rev:8>). For a new revision: build, `gh release create
# denial-<rev:8> …`, update both.
rec {
  rev = "c96375a190a200b6343868afc42d4492b6badb9d";
  src = builtins.fetchTarball {
    url = "https://github.com/denialwm/denial/archive/${rev}.tar.gz";
    sha256 = "1vn1s8v7h457nbnd33rhjw3bmbbb94iqw7bprhp54vsyvna9fahs";
  };
  payload = {
    url = "https://github.com/tuxdotrs/dubai-mainline-userspace/releases/download/denial-${builtins.substring 0 8 rev}/denial-linux-arm64-${rev}.tar.gz";
    hash = "sha256-QWaWmbFruFiUde9LxgpTN28kV00gv5g4tJuHrDVqRMo=";
  };
}
