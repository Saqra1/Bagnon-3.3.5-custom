# Bagnon for WoW 3.3.5a

My installed Bagnon setup for ChromieCraft's original WoW 3.3.5a client.

The repository tracks these six addon folders:

- `Bagnon`
- `Bagnon_Config`
- `Bagnon_Currencies`
- `Bagnon_Forever`
- `Bagnon_GuildBank`
- `Bagnon_Tooltips`

Other addons in the same directory are ignored by Git.

## Sources

The Bagnon 2.13.3 addons are based on
[RichSteini/Bagnon-3.3.5](https://github.com/RichSteini/Bagnon-3.3.5),
originally by Tuller. The repository preserves that project's Git history up to
commit `27a08f89819311d772e7ec7a71a41eafb813f122`.

Bagnon Currencies 2.2.0 is a separate addon by Spillmaker:
[source](https://github.com/Spillmaker/Bagnon_Currencies) and
[CurseForge](https://www.curseforge.com/wow/addons/bagnon-currencies).
Its GPLv3 license is included in `Bagnon_Currencies/LICENSE.txt`.
Existing library notices remain with their files.

## Local changes

This snapshot matches the installed addon files. Compared with the Bagnon source,
it leaves out the sorting feature, supporting assets, and Void Storage addon.
It uses the original client character icon paths and the installed broker font
and guild bank defaults.

The Currencies tooltip has compatibility fixes for 3.3.5a:

- Create a normal frame with its built-in backdrop methods.
- Read the legacy currency API return values and supply Honor and Arena icons.
- Keep header names and temporary values local, and use `GetWidth()` for sizing.

The currency fixes passed Lua 5.1 syntax checks and an offline smoke check for
startup, tooltip hover, currency updates, watched currencies, and click behavior.

## Install and update

Copy the six addon folders into the client's `Interface/AddOns` directory, then
reload the UI. Keep personal settings in the client's `WTF` directory.

In the working copy on this computer, Git tracks the live Bagnon folders, so
changes to those files can be committed directly. Personal settings and other
addons are outside the tracked folders.
