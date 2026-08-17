# 0.0.12

Version bump for release alignment; no EdgeTX Lua-relevant changes this cycle.

# 0.0.11

Version bump for release alignment; no EdgeTX Lua-relevant changes this cycle.

# 0.0.10

This is the first _development snapshot_ of the Wingflight Lua Scripts for EdgeTX and OpenTX.

## Notes

Wingflight is a fork of Rotorflight, refocused exclusively on fixed-wing aircraft. This
tool is the fixed-wing counterpart of Rotorflight's EdgeTX/OpenTX Lua scripts, rebuilt
against wingflight-firmware and entering the shared Wingflight release numbering already
at 0.0.10, alongside the firmware and the Ethos Lua suite.

This version is intended to be used for beta-testing only. It is not fully working nor
stable, and should not be used by end-users.

For more information, please join the [Wingflight Discord](https://discord.gg/aEyyAJTXRw/) chat.

## Changes since forking from Rotorflight

- Renamed the tool and its Lua namespace from `RF2`/`rf2` to `WF`/`wf`, and the Tools-menu
  entry from *Rotorflight 2* to *WingFlight*.
- Removed the *Governor*, *Profile - Governor* and *Profile - Rescue* pages and their MSP
  calls: the corresponding heli-only MSP commands no longer exist on wingflight-firmware.
- Rebuilt the *Mixer* page and MSP layer for wingflight-firmware's rule-based mixer
  (replacing Rotorflight's helicopter swashplate mixer): added *Mixer Inputs* and
  *Mixer Rules* pages backed by the firmware's `MSP_MIXER_INPUTS`/`MSP_MIXER_RULES` API.
- Realigned the PID profile fields with the firmware's current wire format: renamed fields
  the firmware repurposed for fixed-wing use (I-term decay, Attitude Hold gain/deadband),
  dropped now-dead heli-only fields (cyclic cross-coupling, tail-rotor stop gains, etc.)
  from the UI, and added the new fixed-wing fields the firmware sends (TPA gain/curve,
  master gains, auto-hover, cross-axis relax).
- Fixed the Rates page to stop relying on the firmware's now-inert rate-curve-flavor
  selector, and removed the dead heli collective-axis and cyclic ring/polar fields.
- Added a VS Code deploy workflow for copying the scripts straight to an EdgeTX radio's
  SD card during development.

## Downloads

The download locations are:

- [Wingflight Firmware](https://github.com/WingFlight/wingflight-firmware/releases/tag/snapshot/0.0.10)
- [Wingflight Configurator](https://github.com/WingFlight/wingflight-configurator/releases/tag/snapshot/0.0.10)
- [Wingflight Lua Suite for FrSky Ethos](https://github.com/WingFlight/wingflight-lua-ethos-suite/releases/tag/snapshot/0.0.10)
