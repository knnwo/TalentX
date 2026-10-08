# TalentX

A small World of Warcraft addon that adds a red X next to each talent loadout
in the loadout dropdown, so you can delete builds quickly, with an undo if you
change your mind.

## Features
- Red X on every loadout row (not on Starter Build, New Loadout, Import or Share)
- Alt + Left-click required to delete, so you don't remove a build by accident (optional)
- The currently selected loadout is protected and can't be deleted from the menu
- Hover tooltip showing which loadout you're about to delete (optional)
- Undo: every delete saves a backup, and you can restore the most recent ones
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
- You can't delete or restore loadouts while in combat.
- Backups are stored account-wide in the addon's saved variables and can only be
  restored on a character of the matching spec. The number kept can be changed
  on the options page.

## Installation
Copy the `TalentX` folder into `World of Warcraft/_retail_/Interface/AddOns/`.