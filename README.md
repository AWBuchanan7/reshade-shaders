ReShade FX shaders
==================

This repository aims to collect post-processing shaders written in the ReShade FX shader language.

In particular this repository is focused on reworking those shaders to include the depth linearization technique from [BlueSkyDefender/Depth3D](https://github.com/BlueSkyDefender/Depth3D)!

Installation
------------

1. [Download](https://github.com/crosire/reshade-shaders/archive/master.zip) this repository
2. Extract the downloaded archive file somewhere
3. Start your game, open the ReShade in-game menu and switch to the "Settings" tab
4. Add the path to the extracted [Shaders](/Shaders) folder to "Effect Search Paths"
5. Add the path to the extracted [Textures](/Textures) folder to "Texture Search Paths"
6. Switch back to the "Home" tab and click on "Reload" to load the shaders

Contributing
------------

Check out [the language reference document](REFERENCE.md) to get started on how to write your own!
