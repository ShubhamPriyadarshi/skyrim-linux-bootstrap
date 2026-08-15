#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cli="$project_dir/bin/skyrim-linux-bootstrap"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

fake_home="$fixture/home"
steam_root="$fixture/SteamLibrary"
skyrim="$steam_root/steamapps/common/Skyrim Special Edition"
prefix="$steam_root/steamapps/compatdata/489830/pfx"
mkdir -p "$fake_home" "$skyrim/Data/SKSE/Plugins" "$prefix/drive_c"
touch "$skyrim/SkyrimSE.exe"
mkdir -p "$prefix/drive_c/Program Files/dotnet/shared/Microsoft.WindowsDesktop.App/9.0.99"

cat >"$skyrim/Data/SKSE/Plugins/SSEDisplayTweaks.ini" <<'EOF'
[Main]
LogLevel=debug

[Render]
Fullscreen=true
Borderless=false
#Resolution=1920x1080
EOF

export HOME="$fake_home"
export XDG_DATA_HOME="$fake_home/.local/share"
export XDG_CONFIG_HOME="$fake_home/.config"
export XDG_STATE_HOME="$fake_home/.local/state"
export SLB_STEAM_ROOTS="$steam_root"
export SLB_TEST_KERNEL=Linux

assert_contains() {
  local haystack="$1" needle="$2"
  [[ "$haystack" == *"$needle"* ]] || {
    printf 'Expected output to contain: %s\nOutput:\n%s\n' "$needle" "$haystack" >&2
    exit 1
  }
}

output="$(bash "$cli" doctor)"
assert_contains "$output" "$skyrim"
assert_contains "$output" "$prefix"
assert_contains "$output" "9.0.99 (Windows x64)"

[[ "$(bash "$cli" version)" == "0.1.4" ]]

bash "$cli" fix-display 1440 900
grep -q '^Fullscreen=false$' "$skyrim/Data/SKSE/Plugins/SSEDisplayTweaks.ini"
grep -q '^Borderless=true$' "$skyrim/Data/SKSE/Plugins/SSEDisplayTweaks.ini"
grep -q '^Resolution=1440x900$' "$skyrim/Data/SKSE/Plugins/SSEDisplayTweaks.ini"
grep -q '^DisableBufferResizing=true$' "$skyrim/Data/SKSE/Plugins/SSEDisplayTweaks.ini"
find "$XDG_STATE_HOME/skyrim-linux-bootstrap/backups" -type f -name SSEDisplayTweaks.ini | grep -q .

dry_output="$(bash "$cli" --dry-run patch-keizaal 2>&1 || true)"
if [[ "$dry_output" != *"Would create"* && "$dry_output" != *"Protontricks"* ]]; then
  printf 'Unexpected Keizaal dry-run output:\n%s\n' "$dry_output" >&2
  exit 1
fi

fake_bin="$fixture/bin"
runtime_installer="$fixture/windowsdesktop-runtime-win-x64.exe"
mkdir -p "$fake_bin"
touch "$runtime_installer"
cat >"$fake_bin/protontricks-launch" <<'EOF'
#!/usr/bin/env bash
[[ -z "${DOTNET_ROOT+x}" ]]
[[ -z "${DOTNET_ROOT_X64+x}" ]]
printf 'launched\n' >"$SLB_TEST_LAUNCH_LOG"
exit 0
EOF
chmod 0755 "$fake_bin/protontricks-launch"
runtime_output="$(PATH="$fake_bin:$PATH" bash "$cli" --dry-run repair-vortex-runtime "$runtime_installer")"
assert_contains "$runtime_output" "/repair"
assert_contains "$runtime_output" "/quiet"
probe="$prefix/drive_c/Program Files/Vortex/resources/app.asar.unpacked/assets/dotnetprobe.exe"
mkdir -p "$(dirname -- "$probe")"
touch "$probe"
export SLB_TEST_LAUNCH_LOG="$fixture/launch.log"
DOTNET_ROOT=/home/test/.dotnet DOTNET_ROOT_X64=/home/test/.dotnet \
  PATH="$fake_bin:$PATH" bash "$cli" verify-vortex-runtime >/dev/null
grep -q '^launched$' "$SLB_TEST_LAUNCH_LOG"

install_home="$fixture/install-home"
HOME="$install_home" XDG_DATA_HOME="$install_home/.local/share" bash "$project_dir/install.sh" >/dev/null
[[ -x "$install_home/.local/share/skyrim-linux-bootstrap/bin/skyrim-linux-bootstrap" ]]
[[ -L "$install_home/.local/bin/skyrim-linux-bootstrap" ]]
[[ -f "$install_home/.local/share/applications/skyrim-linux-bootstrap.desktop" ]]
installed_version="$(HOME="$install_home" "$install_home/.local/bin/skyrim-linux-bootstrap" version 2>"$fixture/version.err")"
[[ "$installed_version" == "0.1.4" ]]
[[ ! -s "$fixture/version.err" ]]

printf 'All tests passed.\n'
