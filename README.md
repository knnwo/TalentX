# TalentX

A small World of Warcraft (Midnight) addon for talent loadouts. It adds a red X
for deleting loadouts, with undo, and a clickable on-screen bar for switching
between them.

## Features
- **Loadout bar**: a small on-screen bar showing your active loadout. Click it to
  open a menu of your loadouts and switch with one click, including the Starter Build
- **Delete with a red X**: every loadout in the bar's menu and in the talents window's
  own dropdown gets a red X (not the active loadout, not the Starter Build)
- Alt + Left-click required to delete, so you don't remove a build by accident (optional)
- The currently selected loadout is protected and can't be deleted from the menu
- Hover tooltip showing which loadout you're about to delete (optional)
- **Undo**: every delete saves a backup, and you can restore the most recent ones
- The bar warns in red when no loadout is selected and shows the Starter Build in blue
- The bar can be moved, resized, locked, hidden, and its background opacity changed
- Menu text size and colours are adjustable
- Options page in the game's AddOns settings
- Alerts you on screen when a loadout switch is refused, for example when a talent is on cooldown

## Usage
Click the bar to open the loadout menu, then click a loadout to switch to it.
To delete a loadout, Alt + Left-click the red X next to it. The X also appears in
the talents window's loadout dropdown. To bring a deleted loadout back, use
`/talentx undo` or the restore button on the options page. Drag the bar to move
it and use the grip in its bottom-right corner to resize it. Import and Share
stay in the talents window's own dropdown.

## Commands
- `/talentx options` opens the options page
- `/talentx undo` restores the most recently deleted loadout
- `/talentx alt` toggles the Alt requirement on or off
- `/talentx debug` prints debug info about the talents window menu rows

## Notes
- Switching, deleting and restoring loadouts isn't possible in combat.
- Restoring needs a free loadout slot, a loadout from your current spec, and the
  talents window loaded (press N once if it tells you to).
- Backups are kept per character in the addon's saved variables. The number kept
  can be changed on the options page. When you log in fresh, older backups are
  cleared and only the newest one is kept.
- A locked bar can't be moved or resized, but it stays clickable.

## Installation
Copy the `TalentX` folder into `World of Warcraft/_retail_/Interface/AddOns/`.