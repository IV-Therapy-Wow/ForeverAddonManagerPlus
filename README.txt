ForeverAddonManagerPlus
Version 1.0.9
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
settings from" menu. The manager asks before copying, and the copied settings
go into the current tab as an unsaved draft. Review them and click Save Page
when you want to keep them. The "Synchronize from Blizzard Settings" button
works the same way for the current tab; its Save Page button is enabled after
the sync. The all-tabs option asks for a second confirmation and saves the
active profile on all nine tabs in the current profile set. Other named profile
copies and other class/role sets are left alone.

Addon settings are tied to the addon's folder name. The saved registry keeps
profile choices for addons that are temporarily uninstalled, so those choices
are still there when the addon is installed again. Missing addons are hidden
from the list by default; turn on "Show missing addons" when you want to see
them. Refreshing the installed-addon list does not erase their saved settings.

MINIMAP BUTTON AND STATUS TOOLTIP

The movable minimap button can be shown or hidden from the Settings page. It
can be dragged around the minimap and adjusts to different minimap shapes. It
fades when it is not being used. Its tooltip can show your class icon and name
on one line, your selected role and role icon on the next, your current location
type and location name, and an optional list of installed addons. Addon names
keep their own colours; a small green or red dot appears before each name to
show whether it is running. You can choose whether the class and role
information and addon list appear in the tooltip.

MANAGER WINDOW

The manager uses an expanded, resizable-to-screen layout that leaves some of
the game visible around it. The tab you're viewing has a green outline and
bright white text, so it's always clear which page is selected. When that tab
matches the area you're actually in, a round green marker and the words "THIS
RULESET IS ACTIVE" identify the active ruleset. The original nebula background
stays as it was.

The addon list scrolls smoothly with the mouse wheel and has a scrollbar with
up and down buttons. The selected tab's copy and sync controls are in the same
window. Copying from another tab asks first and still requires Save Page.
Toggle Addons warns before leaving if you have unsaved edits, and lets you
cancel, discard, or save before opening Blizzard's AddOns window. The Command
List button opens the slash-command reference; click a command to select it
for copying. The footer stays blank until you make a change, then shows whether
it has been saved.

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

Version 1.0.9
CITY PROFILE DETECTION

The City profile is limited to the major auction-house hubs listed by the addon. Inns and resting areas in smaller towns, such as Gadgetzan, do not switch you to the City profile.
