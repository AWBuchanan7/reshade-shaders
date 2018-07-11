reshade-shaders-retooled
==================

This repository aims to collect post-processing shaders written in the ReShade FX shader language and rework those shaders to include the depth linearization technique from [BlueSkyDefender/Depth3D](https://github.com/BlueSkyDefender/Depth3D), as such much credit is due to the work done by Jose Negrete (AKA BlueSkyDefender).

Why?
------------

These shaders, as a result of the depth modifications included, feature much higher compatibility with the depth maps provided in the Project64 emulator when using the [gonetz/GLideN64](https://github.com/gonetz/GLideN64) or [ata4/angrylion-rdp-plus](https://github.com/ata4/angrylion-rdp-plus) graphics plugins.

Installation
------------

1. Download this repository
2. Extract the downloaded archive file somewhere
3. Start your game, open the ReShade in-game menu and switch to the "Settings" tab
4. Add the path to the extracted [Shaders](/Shaders) folder to "Effect Search Paths"
5. Add the path to the extracted [Textures](/Textures) folder to "Texture Search Paths"
6. Switch back to the "Home" tab and click on "Reload" to load the shaders
