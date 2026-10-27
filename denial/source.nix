# The Denial revision this port uses: its source (packaging files, NixOS
# module) and, built from the same revision by `./build.sh denial` in the
# meta repo, the ARM64 binaries.
rec {
  rev = "c96375a190a200b6343868afc42d4492b6badb9d";
  src = builtins.fetchTarball {
    url = "https://github.com/denialwm/denial/archive/${rev}.tar.gz";
    sha256 = "1vn1s8v7h457nbnd33rhjw3bmbbb94iqw7bprhp54vsyvna9fahs";
  };
}
