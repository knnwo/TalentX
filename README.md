# TalentX

A small World of Warcraft addon for talent loadouts. It adds a red X next to each
loadout in the loadout dropdown so you can delete builds quickly, with an undo if
you change your mind, and an on-screen bar that shows which loadout is active.

## Features
- Red X on every loadout row (not on Starter Build, New Loadout, Import or Share)
- Alt + Left-click required to delete, so you don't remove a build by accident (optional)
- The currently selected loadout is protected and can't be deleted from the menu
- Hover tooltip showing which loadout you're about to delete (optional)
- Undo: every delete saves a backup, and you can restore it
- Backups expire on your next fresh login, and the newest backup is always kept as a safety net
- Loadout tracker bar: a small on-screen bar showing the active loadout. Drag it to move,
  drag the corner grip to resize. Position and size are remembered
- The tracker bar turns red and warns you when no loadout is selected (the game sometimes drops the selection between sessions)
- Options page in the game's AddOns settings

## Usage
Open the talents window, open the loadout dropdown, and Alt + Left-click the X
next to a loadout. To bring a deleted loadout back, use `/talentx undo` or the
restore button on the options page.

## Commands
- `/talentx options` opens the options page
- `/talentx undo` restores the most recently deleted loadout
- `/talentx alt` toggles the Alt requirement on or off
- `/talentx debug` prints debug info about the menu rows

## Notes
- Restoring needs a free loadout slot, a loadout from your current spec, and the
  talents window loaded (press N once if it tells you to).
- You can't delete or restore loadouts in combat.
- Backups are stored account-wide in the addon's saved variables and can only be
  restored on a character of the matching spec. Backups from earlier sessions are
  removed when you log in again (not on /reload), except the newest one.

## Installation
Copy the `TalentX` folder into `World of Warcraft/_retail_/Interface/AddOns/`.