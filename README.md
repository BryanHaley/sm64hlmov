# sm64hlmov
## Super Mario 64 with Half-Life/Quake Movement Speedrun Modpack

### Credits
- mquake - 0x2480 aka Vincenza https://mods.sm64coopdx.com/mods/mquake.234/
- Half-Life HUD - birdekek https://mods.sm64coopdx.com/mods/hl1-hl2-hud-mod-pack.224/
- IL Helper, MariomodXT, InputViewer - Mr. Mary
- Crowbar, Half-Life Music, some modifications to mQuake - Aeomech (myself)

### HOW TO DOWNLOAD
- Click the green "CODE" button
- Click "Download as Zip"

### HOW TO RUN
- Download and install sm64coopdx
  - https://sm64coopdx.com/
  - https://github.com/coop-deluxe/sm64coopdx/releases/download/v1.0.4/sm64coopdx_v1.0.4_Windows_x86_64_OpenGL.zip
- Obtain a Super Mario 64 z64 ROM
  - WE CANNOT DISTRIBUTE THIS ROM FILE
  - The only legal way to do this is to back it up from your actual SM64 cart OR extract it from a legally purchased copy of SM64 on the Wii, Wii U, or Switch eShops.
- Extract the zip of this repository into your sm64coopdx/mods/ folder
  - You should see sm64coopdx/mods/mQuake, sm64coopdx/mods/crowbar, etc.
- Start sm64coopdx
  - Drag your sm64 z64 ROM file into the window
  - Click Host
  - Click Settings
  - **Check "Skip Intro Cutscene" (this fixes a bug that prevents you from moving!)**
  - Set "On Star Collection" to "Stay in Level"
  - Leave all other settings at default
  - Click Back
  - Click "Mods and Gamemodes"
  - Enable mQuake [sm64hlmov custom] and MariomodXT (for full runs) OR IL Run Helper (for single level runs)
  - Optionally enable Better FPS Skybox, mQuake Input Viewer, HL1 HUD, Half-Life Crowbar, and Half-Life Music
  - Disable all other mods
  - Click Back
  - Click Host, then click Host again. The game should start.
  - The settings should persist, so after this you just need to erase your save and click Host -> Host for new runs.
  - With MariomodXT enabled, press DPAD Up to start a run.
  - You will likely also want to set up your key binds to be more like Half-Life. This can be done under Options -> N64 Binds.

### Misc Notes
- If you have a non-sm64hlmov custom copy of mQuake, you will need to delete it entirely when installing this version of mQuake; this is because sm64coopdx will preferentially use the compiled luac files over the lua source files distributed with this version.
- Try messing with deceleration under camera settings. It may make the mouse "feel" better.
- No scripts or autohotkeys are allowed in the run. Auto hopping is allowed and enabled by default in mQuake.
- Use `/mq_server DeleteConfig default` to restore the default run-legal configuration.
- Edge friction is by default set at 1.3x. Any multiplier between 1.0 (disabled) and 2.0 (double friction near edges) should be fine and can be set like so: `/mq_server EdgeFrictionMultiplier 1.0`
- Dpad Down is a brake/walk button similar to holding 'E' in Half-Life.
- The Discord authorize thing is annoying and there's no launch flag (yet) to turn it off. However, the perms it asks for are relatively innocuous, and it'll stop asking after you authorize it.
  - https://github.com/coop-deluxe/sm64coopdx/issues/514
- Shout out to Jeepy (twitch.tv/jeepy) who found mQuake and silently routed it for months to turn it into a real speedrun!