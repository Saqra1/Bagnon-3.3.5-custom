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

Bagnon Currencies is a local 3.3.5a adaptation of Spillmaker's version 2.2.0:
[source](https://github.com/Spillmaker/Bagnon_Currencies) and
[CurseForge](https://www.curseforge.com/wow/addons/bagnon-currencies).
Its GPLv3 license is included in `Bagnon_Currencies/LICENSE.txt`.
Existing library notices remain with their files.

## Local changes

Compared with the Bagnon source, this installation leaves out the sorting
feature, supporting assets, and Void Storage addon. It uses the original client
character icon paths and the installed broker font and guild bank defaults.

Currencies reports version `2.2.0-3.3.5a`. Both manifests declare Interface
`30300`, require Bagnon, and load only the legacy implementation. The upstream
Mainline source remains in the folder but is not loaded.

- Read the legacy currency tuples and use Arena and faction-specific Honor icons.
- Use the backpack API so watched totals survive collapsed currency categories.
- Refresh on entering the world, currency updates, and tracking changes.
- Reuse and reposition tooltip rows, hide removed rows, and size both columns.
- Keep helpers local and use native backdrop methods.
- Dismiss the previous broker tooltip when switching plugins or closing Bagnon.

The tooltip follows the native currency list's category expansion state. Watched
totals always describe the logged-in character, including when browsing cached
bags for another character.

## Validation

From the repository root with Lua 5.1:

```powershell
& 'C:\Program Files (x86)\Lua\5.1\lua.exe' 'Bagnon_Currencies\tests\smoke.lua'
@(git ls-files '*.lua'; git ls-files --others --exclude-standard '*.lua') |
    & 'C:\Program Files (x86)\Lua\5.1\lua.exe' 'Bagnon_Currencies\tests\smoke.lua' --syntax
```

The offline harness uses the installed LibDataBroker, Bagnon broker, and settings
code with mocked client frames and currency APIs. It checks startup, live
updates, collapsed categories, tooltip rows/sizing, tracking, clicks, plugin
switching, bag closure, and multiple windows. Syntax checks strip existing UTF-8
BOMs in memory for stock Lua 5.1.

API contracts were checked against the local *World of Warcraft Programming*
reference (book pp. 635-636, 660, 688-689, 918, 972) and Blizzard's archived
[3.3.5 Token UI](https://github.com/tekkub/wow-ui-source/blob/3.3.5/AddOns/Blizzard_TokenUI/Blizzard_TokenUI.lua).
The Honor currency texture also appears in
[3.3.5 ContainerFrame.lua](https://github.com/tekkub/wow-ui-source/blob/3.3.5/FrameXML/ContainerFrame.lua).

Live client rendering and server event timing still need an in-game check.

## Install and update

Copy the six addon folders into the client's `Interface/AddOns` directory, then
reload the UI. Keep personal settings in the client's `WTF` directory.

In the working copy on this computer, Git tracks the live Bagnon folders, so
changes to those files can be committed directly. Personal settings and other
addons are outside the tracked folders.
