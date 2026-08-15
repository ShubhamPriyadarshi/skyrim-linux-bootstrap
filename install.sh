#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
install_root="${XDG_DATA_HOME:-$HOME/.local/share}/skyrim-linux-bootstrap"
bin_dir="${HOME}/.local/bin"
applications_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

install -d "$install_root" "$bin_dir" "$applications_dir"
cp -R "$project_dir/bin" "$project_dir/lib" "$project_dir/share" "$project_dir/VERSION" "$install_root/"
chmod 0755 "$install_root/bin/skyrim-linux-bootstrap"
chmod 0755 "$install_root/lib/patch_ini.py"
ln -sfn "$install_root/bin/skyrim-linux-bootstrap" "$bin_dir/skyrim-linux-bootstrap"

desktop_file="$applications_dir/skyrim-linux-bootstrap.desktop"
sed "s|@EXEC@|$bin_dir/skyrim-linux-bootstrap|g" \
  "$project_dir/share/applications/skyrim-linux-bootstrap.desktop.in" >"$desktop_file"
chmod 0644 "$desktop_file"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
fi

printf 'Installed Skyrim Linux Bootstrap %s\n' "$(<"$project_dir/VERSION")"
printf 'Run: %s doctor\n' "$bin_dir/skyrim-linux-bootstrap"
printf 'Desktop entry: %s\n' "$desktop_file"
