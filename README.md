# Skyrim Linux Bootstrap

An unofficial, distribution-agnostic compatibility installer for running
Vortex and Keizaal Online with Skyrim Special Edition through Steam Proton.

The project automates the Linux integration around official installers. It does
not redistribute Skyrim, Vortex, Keizaal, Nexus Mods files, collections, account
credentials, access tokens, or proprietary artwork.

## What works in v0.1

- Finds Steam libraries on internal, removable, `/nvme`, Flatpak Steam, and Snap
  Steam installations.
- Finds Skyrim Special Edition and its Steam app `489830` Proton prefix.
- Launches official Vortex and Keizaal Windows installers in the Skyrim prefix.
- Installs and verifies Microsoft's Windows x64 .NET 9 Desktop Runtime before
  Vortex, avoiding Vortex's unreliable in-app repair process under Proton.
- Creates native desktop launchers for both applications.
- Registers `nxm://` links with Vortex and `skyrim-rp://` callbacks with Keizaal.
- Applies Vortex's Linux HiDPI scale without changing the system-wide scale.
- Pins an explicit SSE Display Tweaks render size to prevent alt-tab upscaling.
- Detects the Easy Effects routing conflict that can silence Keizaal voice.
- Backs up every game configuration before changing it.
- Never reads, logs, copies, or prints authentication tokens.

## Supported systems

The core only requires Bash 4+, Python 3, XDG utilities, Steam, and
Protontricks. Dependency adapters are included for:

- Arch Linux, CachyOS, EndeavourOS and Manjaro (`pacman`)
- Debian, Ubuntu, Linux Mint and Pop!_OS (`apt`)
- Fedora, Nobara and Bazzite (`dnf`)
- openSUSE (`zypper`)
- Alpine (`apk`, using Flatpak Protontricks)
- Other and immutable distributions through Flatpak Protontricks

SteamOS and other immutable systems should use Flatpak Protontricks. Package
installation is the only distribution-specific layer; discovery and patching
are shared. The installer detects OSTree and SteamOS images automatically. Set
`SLB_PROTONTRICKS_MODE=flatpak` to force the portable dependency path on any
distribution. External Steam libraries are granted only to Protontricks through
per-library Flatpak filesystem overrides.

## Install

```bash
git clone https://github.com/ShubhamPriyadarshi/skyrim-linux-bootstrap.git
cd skyrim-linux-bootstrap
./install.sh
```

Then open **Skyrim Linux Bootstrap** from the application menu or run:

```bash
skyrim-linux-bootstrap doctor
skyrim-linux-bootstrap install-deps
```

For the guided path, download both official Windows installers and run:

```bash
skyrim-linux-bootstrap setup ~/Downloads/Vortex-Setup.exe \
  ~/Downloads/KeizaalLauncherSetup.exe 1440 900
```

The same guided setup is the first item in the desktop menu.

The desktop launcher uses KDialog on KDE, Zenity on GNOME and compatible
desktops, and a terminal menu everywhere else.

## Typical workflow

1. Install and launch Skyrim Special Edition once through Steam.
2. Run `skyrim-linux-bootstrap install-deps`.
3. Download the official Vortex Windows installer and run
   `skyrim-linux-bootstrap install-vortex ~/Downloads/Vortex-Setup.exe`.
4. Run `skyrim-linux-bootstrap patch-vortex`.
5. Install the Keizaal collection normally in Vortex. Nexus login, download
   confirmation, and account limits remain under the user's control.
6. Download the official Keizaal launcher and run
   `skyrim-linux-bootstrap install-keizaal ~/Downloads/KeizaalLauncherSetup.exe`.
7. Run `skyrim-linux-bootstrap patch-keizaal`.
8. Run `skyrim-linux-bootstrap doctor` before starting the game.

If Vortex reports that .NET Desktop Runtime 9 is required, close Vortex and run:

```bash
skyrim-linux-bootstrap repair-vortex-runtime
```

This downloads Microsoft's official Windows x64 runtime, repairs it inside the
Skyrim Proton prefix, and runs Vortex's own bundled runtime probe. An offline
installer can instead be supplied as the command's first argument. All generated
launchers remove Linux `DOTNET_ROOT` variables from the Proton child process so
Vortex resolves `C:\Program Files\dotnet`; the host shell remains unchanged.

For a HiDPI base resolution such as 1440×900:

```bash
skyrim-linux-bootstrap fix-display 1440 900
```

If Keizaal voice is silent and Easy Effects is installed:

```bash
skyrim-linux-bootstrap fix-audio --uninstall-easyeffects
```

That action asks for confirmation, preserves the user's Easy Effects presets,
and requires a Skyrim restart. It never changes microphone or speaker volume;
existing levels such as a 33% microphone setting remain untouched.

## Safety model

- Commands are idempotent where practical.
- Game configuration files are copied to
  `~/.local/state/skyrim-linux-bootstrap/backups/` before modification.
- `--dry-run` prints changes without applying them.
- Destructive package removal requires a dedicated flag and confirmation.
- Downloads use HTTPS and official project release sources.
- Diagnostic output deliberately excludes configuration contents that can hold
  login tokens.

Run `skyrim-linux-bootstrap --help` for all commands.

## Project status

This is an early community release derived from a verified CachyOS installation.
The CachyOS path is tested first, but distribution-specific assumptions are not
allowed in the shared patching core. Reports and tested distro adapters are very
welcome.

## Legal

This project is GPL-3.0 licensed and unofficial. See [NOTICE](NOTICE). Vortex is
itself distributed under GPL-3.0, but this project currently wraps official
Vortex releases rather than redistributing or modifying Vortex binaries.
