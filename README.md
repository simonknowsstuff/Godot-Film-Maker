# Godot Film Maker

This is a simple addon that lets you record videos from your Godot project. 

## Description

Godot Film Maker (GFM for short) is a plugin for Godot 3 that lets you record videos using ffmpeg from your Godot project. 
It can easily be configured from its script files and provides options for customisation. 
It is still in the prototype stage and more features are to be added.

## Getting Started

### Installing

#### To use the addon for your project:
* Download the repository as a zip file.
* Copy the folder "godot_film_maker" to your addons folder in your project. If you do not see an addons folder in your project, create one.
* In Godot, go to Project > Project Settings... > Plugins and enable Godot Film Maker in Status.

The repository as a whole is a Godot project. You can import it from the Project Manager if you wish to only test it.

## Using Godot Film Maker

### Basic info
* On startup, it will appear that your project is paused. Click the record button to start recording.
* You can setup other options for use in the settings button (the cog) located in the right most side of the control menu. 
* Once you have begun recording, you can use the square button to stop recording any time. A save file prompt will appear. 
 Note that "filename.extension" must be used to save the video file. 
* You can also add custom ffmpeg parametters while exporting through ffmpeg by locating the recorder.gd file found in addons > godot_film_maker. Scroll down to the line where "# Add in your custom ffmpeg commands here." is written and add in your parameters here.
* While recording, make sure the process mode is set to "Physics" under the Playback Options or set a simillar option to all nodes used for recording. This is a known issue as on process, when the capturing code slows down rendering, the process delta kept changing while testing (This is probably Godot adjusting the delta variable to compensate lag)

## Development

### Features to be added:
* Recording audio.
* Making the UI more user friendly.
* Adding in functions that can be used globally in external scripts.


## Socials

### Contributors:
* [Technohacker](https://github.com/Technohacker): Contributed to the main image capturing and combining code. 
* [AbhinavKDev](https://github.com/AbhinavKDev): Contributed to the backbone of the code and developed the prototype audio and video capturing functions.

### Donations:
You can donate to the project via [coindrop.](https://coindrop.to/simonknowsstuff)

