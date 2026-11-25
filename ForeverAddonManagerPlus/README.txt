ForeverAddonManagerPlus
Version 1.0.6
A full-feature addon manager for World of Warcraft: Forever.

WHAT IT DOES

ForeverAddonManagerPlus keeps your addon setup organized around where you are
playing and what role you have selected. It manages addon enable/disable
profiles for these location types:

- World
- City
- Instance (dungeons)
- Raid
- Battleground
- Arena
- Deeprun Tram
- Scenario
- Other instance types

The active location profile is selected automatically as you move between
these areas. The manager checks which addons actually need to change, and only
stages those changes. A UI reload is required before enabled or disabled addons
take effect. When a location profile changes addon states, the manager asks
whether to reload now or later. When you change roles, you can apply the new
role profile immediately or have it applied when you close the manager.

CLASS AND ROLE PROFILES

You can keep separate profiles for each character class and select a role:

- DPS
- Healer
- Tank
- Support

Each class and role has its own set of location profiles. This lets you use a
different addon setup for the same raid, dungeon, city, or battleground when
you change between roles. Role selection is manual; the manager does not try
to guess your role from the area you enter, and it does not change your talents
or your actual group role.

CUSTOM PROFILES

Each location can have additional named profiles. You can make a copy of the
current profile, edit it for a different activity or play style, and choose
which profile is active for that location. Profiles are kept separately for
each class and role.

ADDON LIST AND SAVED ADDON SETTINGS

The checkbox shows the setting saved in the selected profile. The colored dot
shows the live state: green means loaded, red means not currently loaded, and
grey means the addon is missing. An addon that has been disabled can remain
loaded until the next reload. You can refresh the installed-addon inventory
and open Blizzard's standard AddOns window from the manager. The manager
protects itself and Blizzard UI addons from profile-based disabling. On a new
installation, the default location profiles start with the enabled/disabled
settings shown in Blizzard's AddOns window. Later scans leave saved choices
alone and only fill in settings for newly discovered addons.

You can copy the active profile from another location tab with the "Copy
settings from" menu. The "Synchronize from Blizzard Settings" button copies
the current Blizzard addon settings into the selected tab, or into the active
profile on every location tab in the current profile set after a second
confirmation. The current tab's copy must be saved with Save Page; the all-tabs
option saves its changes immediately. Other named profile copies and other
class/role sets are left alone.

Addon settings are tied to the addon's folder name. The saved registry keeps
profile choices for addons that are temporarily uninstalled, so those choices
are still there when the addon is installed again. You can also manually track
an addon by its folder name before installing it. Refreshing the installed
addon list does not remove missing addons or erase their saved settings.

MINIMAP BUTTON AND STATUS TOOLTIP

The movable minimap button can be shown or hidden from the Settings page. It
can be dragged around the minimap and adjusts to different minimap shapes. It
fades when it is not being used. Its tooltip can show your selected class and
role with the matching in-game role icon, your current location type, and a
color-coded list of installed addons (green for loaded and red for not currently loaded).
You can choose whether the role information and addon list appear in the
tooltip.

MANAGER WINDOW

The manager uses an expanded, resizable-to-screen layout that leaves some of
the game visible around it. When you open the tab for the location you're in,
a small green marker and the words "THIS RULESET IS ACTIVE" identify it. The
other tabs keep their normal grey appearance, and the nebula background stays
as it was. Its class/role selector,
profile controls, addon list, copy/synchronization controls, and Settings page
are all available from the same window. The footer stays blank until you make
a change; it then shows whether the change has been saved.

GETTING STARTED

1. Place the ForeverAddonManagerPlus folder in Interface/AddOns.
2. Enable ForeverAddonManagerPlus in the AddOns list at character select.
3. Log in and type /famp, or use the minimap button.
4. The first-use reminder explains the initial setup. The default profiles
   are already filled from Blizzard's current AddOns settings.
5. Select a location page, review its addon selections, and use Save Page to
   finish the setup. You can then adjust profiles for your other locations.

SLASH COMMANDS

- /famp or /foreveraddonsplus: open or close the manager.
- /famp scan or /famp refresh: refresh the installed-addon list.
- /famp minimap: show or hide the minimap button.
- /famp location: report the detected location type.
- /famp reload: reload when addon changes are waiting.
- /famp status: show whether the manager window and minimap button initialized.
- /famp help: display the command list.

Created by IV Therapy
Waffle House Guild — PVP Ruleset
November 24, 2026

OPEN-SOURCE LICENSE AND PERMISSIONS

ForeverAddonManagerPlus is an independent community addon for World of
Warcraft: Forever. It is released under the MIT License. Copyright (c) 2026
IV Therapy.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and its associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, inspect, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following conditions: the above
copyright notice and this permission notice must be included in all copies or
substantial portions of the Software.

This permission is worldwide, perpetual, non-exclusive, and royalty-free,
subject to the terms of the MIT License. No separate consent
from IV Therapy is required to use, inspect, fork, modify, keep an independent
version, or redistribute the Software. The Software is provided "AS IS",
without warranty of any kind, express or implied. The full license terms are
included in LICENSE.txt.

This addon was created by IV Therapy of Waffle House Guild on the PVP Ruleset.
It is an independent community project and is not affiliated with, sponsored
by, or endorsed by Blizzard Entertainment or the operators of WoW Forever.
World of Warcraft names, trademarks, game content, and third-party assets
remain the property of their respective owners. This license does not grant
rights to those materials.

COMMUNITY PRINCIPLE

I believe making people pay for addons should be against the core values of
any real gamer. Games are about enjoying the experience in the way each player
chooses, and customization tools and quality-of-life features should be
available to everyone. Keeping those tools away from other players only limits
how they can enjoy the game and hurts the community as a whole. I make the
original project available without a purchase requirement.

The MIT License does not add a non-commercial restriction and allows copies or
modified versions to be redistributed, including for a fee, as long as its
terms are followed. The community principle above explains my view; it does
not add restrictions to the MIT License.

Version 1.0.6