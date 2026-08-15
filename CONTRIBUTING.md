# Contributing

Thank you for helping make Skyrim modding less fragile on Linux.

## Principles

1. Keep the patching core distribution agnostic.
2. Put package names and privileged operations behind a package-manager adapter.
3. Never commit or print access tokens, cookies, API keys, Steam IDs, Discord IDs,
   IP addresses, or private launcher logs.
4. Do not redistribute game files, mods, collections, or third-party installers.
5. Back up user files before changing them and provide a dry-run path.
6. Prefer semantic configuration changes over UI-coordinate automation.

## Testing

Run:

```bash
bash -n bin/skyrim-linux-bootstrap install.sh tests/test.sh
python3 -m py_compile lib/patch_ini.py
bash tests/test.sh
```

Pull requests that add a distribution should include the distro/version, Steam
packaging method, Protontricks packaging method, and a sanitized `doctor` result.

