# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0](https://github.com/Ratamacue9112/CopperDC/tree/v1.2.0) (2024-08-09)

### Added
- Added the `remove_command` and `remove_commands` functions.
- Added command history with up and down navigation.
- Added the `is_console_visible` function.
- Added the `set_pause_on_open` function.
- Added the `open_cfg_dir` command.
- Added the `help` command.

### Changed
- The console now automatically resizes.
- Command hints are now clickable.
- Renamed `show_log` to `show_mini_log`.
- Renamed `show_monitor` to `set_monitor_visible`.
- The `add_command`, `add_command_setvar` and `DebugCommand.new` functions all now take a string `helpText` parameter. This is what shows up when using the `help` command.
  - ***Please note that updating may cause some errors. The `helpText` parameter comes before `get_function` as it will most likely be used more. All you need to do is add empty quotes or your help message before the `getFunction` parameter.***

### Fixed
- Fixed bool parameter type not working.
- Fixed log not wrapping on long messages.

### Removed
- Removed unnecessary commented out code.
- The `icon.png` file is no longer part of the downloaded plugin.

## [1.1.1](https://github.com/Ratamacue9112/CopperDC/tree/v1.1.1) (2024-01-08)

### Changed
- Put plugin inside an `addons` folder.
- Sorted the main `debug_console.gd` script with code regions.

### Removed
- Removed placeholder text in log.

## [1.1.0](https://github.com/Ratamacue9112/CopperDC/tree/v1.1.0) (2023-11-26)

### Added
- Added `add_command_setvar` function.
- Added `getFunction` parameter to DebugCommand class.
- Added `show_console` and `hide_console` functions.
- Added `show_stats` command.
- Added `show_log` command.
- Added `exec` command.
- Added `setup_cfg` function.
- Added `DebugConsole.Monitor` class.
- Added `show_monitor` command.
- Added ability to hide monitors by setting the `visible` parameter in the `add_monitor` function. This is set to `true` by default.
- Added `set_monitor_visible` function .
- Added 6 new built-in monitors. All 6 and the "Physics Process" monitor are hidden by default, only the "FPS" monitor is visible.

### Changed
- Moved the `clear` command from `debug_console.gd` to `built_in_commands.gd`.
- Changed how hiding and showing the console works, to allow for some elements to stay visible.
- Renamed plugin entry script to `dc_entry.gd`.
- Delayed the initializing of the built-in commands by 0.05 seconds to ensure all cfgs and monitors from other scripts have loaded.
- Monitors are now identified with an ID, a display name is given on creation. All functions have been changed accordingly.
- Updated .gitignore.

### Fixed
- Fixed bool parameter type not working.
- Fixed log not wrapping on long messages.

### Removed
- Removed "Monitor {name} already exists." error message.
- Removed unnecessary .tmp files.
  
## [1.0.0](https://github.com/Ratamacue9112/CopperDC/tree/v1.0.0) (2023-11-22)
Initial release.
