# WingFlight Lua Scripts

[Wingflight](https://github.com/WingFlight) is a flight control software suite designed for
fixed-wing aircraft. It consists of:

- Wingflight Flight Controller Firmware
- Wingflight Configurator, for flashing and configuring the flight controller
- Wingflight Blackbox Explorer, for analyzing blackbox flight logs
- Wingflight Lua Scripts, for configuring the flight controller using a transmitter running:
  - EdgeTX/OpenTX (this repository)
  - Ethos

For more information, see the [Wingflight GitHub organization](https://github.com/WingFlight).

## Lua Scripts Requirements

- EdgeTX 2.5.0 or OpenTX 2.3.12 or later transmitter firmware
- A receiver supporting remote configuration:
  - a FrSky Smartport or F.Port receiver, _or_
  - a Crossfire v2.11 or newer receiver, _or_
  - an ELRS 2.0.1 or newer receiver

> [!IMPORTANT]
> If you're using ELRS, make sure to set the baudrate to 1.87M or higher in the *Hardware* menu of your transmitter.

## Installation

Please download the latest version from [GitHub](https://github.com/WingFlight/wingflight-lua-edgetx/releases/) and copy the contents of the `SCRIPTS` folder to your transmitter. You will know that you've done it correctly when you find the `wf.lua` file located in the `/SCRIPTS/TOOLS` directory. Plus, you should now see *WingFlight* listed in the *Tools* menu of your transmitter. Also, you should be able to see the *WF Tool* and *WF Stats* widgets if you have a color radio.

### Copying the SCRIPTS folder

USB Method

1. Connect your transmitter to a computer with an USB cable
2. Open the new drive on your computer
3. Unzip the file and copy the `SCRIPTS` folder to the root the new drive
4. Eject the drive
5. Unplug the USB cable

SD Card Method

1. Power off your transmitter
2. Remove the SD card and plug it into a computer
3. Unzip the file and copy the `SCRIPTS` folder to the root of the SD card
4. Eject the SD card
5. Reinsert your SD card into the transmitter
6. Power up your transmitter

If you copied the files correctly, you can now go into the *Tools* menu on your transmitter and access the *WingFlight* tool. The first time you run the script, a message 'Compiling...' will appear in the display before the script is started. This is normal and is done to minimise the RAM usage of the script.

## Usage

Start the tool using the *Tool* menu of your transmitter or by setting the *WF Tool* widget to *Full Screen* mode. Feel free to look around, changes will only be saved if you explicitly select *Save*:
- On color radios there is a *Save* button in the upper right corner.
- On black and white radios, select the *Save* option after long pressing the wheel/roller.

For more information, see the [Wingflight documentation](https://doc.wingflight.org).

## Background script
The optional background script `wfbg.lua` features *Real Time FC Clock synchronization*, the *Adjustment Teller* and *CRSF/ELRS custom telemetry*.
- RTC synchronization will send the time of the transmitter to the flight controller. The script will beep if RTC synchronization has been completed. Blackbox logs and files created by the FC will now have the correct timestamp.
- *CRSF/ELRS custom telemetry* enables all available WingFlight telemetry sensors when using ELRS.
- The *Adjustment Teller* will [tell you](https://www.youtube.com/watch?v=rbMiiWhzhqI) what adjustment you just made. It supports all adjustments except profile adjustments.

There are two ways to run the background script:
1. Either configure the *WF Tool* widget. This only works on color radios running EdgeTX.
2. Or configure `wfbg` to run as a special or global function in EdgeTX/OpenTX.

### 1. Configure the *WF Tool* widget

If you have a color radio running EdgeTX 2.11 or higher, then you can use the *WF Tool* widget. Running this widget has several benefits:
- It will automatically show the name of the connected model.
- *WF Tool* can also always display one sensor value of your liking. I like *Vcel* (cell voltage) to be displayed always, so I don't completely exhaust my batteries while tuning.
- *WF Tool* defines an API that can also be used by other widgets, which makes programming WingFlight widgets easier. The *WF Stats* widget for example uses the *WF Tool* API, and displays/updates flight statistics.
- You don't need to configure a function for running the background script anymore.

In the image below you can see the *WF Tool* widget in the upper left part, while the *WF Stats* widget sits in the lower right part of the screen.

![EdgeTX script setup](https://raw.githubusercontent.com/WingFlight/wingflight-lua-edgetx/master/docs/assets/images/rotorflight-widgets.png)

Here's a video that explains [how to set up the widget](https://www.youtube.com/watch?v=t72pQoBngGs).

### 2. Or run the background script as a function
In OpenTX, configure your special function as follows to run the script automatically as soon as the model is selected ('ON').

![OpenTX script setup](https://raw.githubusercontent.com/WingFlight/wingflight-lua-edgetx/master/docs/assets/images/background_script_setup.png)

On EdgeTX, make also sure to set *Repeat* to *On*:

![EdgeTX script setup](https://raw.githubusercontent.com/WingFlight/wingflight-lua-edgetx/master/docs/assets/images/background_script_edgetx.png)


## Adjustment Teller

The *Adjustment Teller* can be enabled under Settings > Wfbg Options > Adjustment Teller. The teller uses telemetry for getting the adjustment function and value:
- S.port/F.port: the telemetry sensors 5110 and 5111 should be available. Discover or add them if they aren't.
- CRSF: the telemetry sensor FM should be available. Also do a `set crsf_flight_mode_reuse = ADJFUNC` in the CLI and `save`.
- CRSF/ELRS custom telemetry: make sure you include the *Adjustment Function* sensor.

> [!IMPORTANT]
> Some black & white radios (e.g. the Jumper T-LITE running EdgeTX 2.11) don't have enough memory for running both the *Adjustment Teller* and *CRSF/ELRS custom telemetry*. The user interface will then randomly freeze.


## Building from source on Linux

- Be sure to have `make` and `luac` in version 5.2 installed in the path.
- Run `make` from the root folder.
- The installation files will be created in the `obj` folder. Copy the files to your transmitter as instructed in the [Installation](#installation) section as if you unzipped from a downloaded file.


## Contributing

Wingflight is an open-source community project. Anybody can join in and help to make it better by:

* helping other users in [GitHub Discussions](https://github.com/WingFlight) or other online forums
* [reporting](https://github.com/WingFlight) bugs and issues, and suggesting improvements
* testing new software versions, new features and fixes; and providing feedback
* participating in discussions on new features
* contributing to the software development - fixing bugs, implementing new features and improvements
* translating WingFlight scripts into a new language, or helping to maintain an existing translation


## Origins

Wingflight is software that is **open source** and is available free of charge without warranty.

This tool is a fixed-wing fork of the [Rotorflight](https://github.com/rotorflight) Lua scripts for EdgeTX/OpenTX. Rotorflight is itself forked from [Betaflight](https://github.com/betaflight), which in turn is forked from [Cleanflight](https://github.com/cleanflight).

Big thanks to everyone who has contributed along the journey!

> Note: some screenshots/assets above are still carried over from the upstream Rotorflight project and haven't been retaken for WingFlight branding yet.


## Contact

Team Wingflight can be contacted via [GitHub Issues and Discussions](https://github.com/WingFlight).
