# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0](https://github.com/Ratamacue9112/CopperDC/tree/v1.1.0) (2023-11-26)

### Added
- Added `add_command_setvar` function ([#16](https://github.com/Ratamacue9112/CopperDC/tree/8124c9ff34eed450ed88ec831ed8d6d8cef482e4) and [#24](https://github.com/Ratamacue9112/CopperDC/tree/2fc8e36cea7c040a031e85895d55da3160d354b8)). 
- Added `getFunction` parameter to DebugCommand class ([#18](https://github.com/Ratamacue9112/CopperDC/tree/2715eed8afd6fe23497911d01d47aa6a1996293c)).
- Added `show_console` and `hide_console` functions ([#20](https://github.com/Ratamacue9112/CopperDC/tree/6a7f5c835179bb42c60b0af47795ea7fa2fce8dd)).
- Added `show_stats` command ([#20](https://github.com/Ratamacue9112/CopperDC/tree/6a7f5c835179bb42c60b0af47795ea7fa2fce8dd) and [#21](https://github.com/Ratamacue9112/CopperDC/tree/94c54fc7e4bba6e54a4ced9fc992c13b7a3ffa77)).
- Added `show_log` command ([#21](https://github.com/Ratamacue9112/CopperDC/tree/94c54fc7e4bba6e54a4ced9fc992c13b7a3ffa77)).
- Added `exec` command ([#22](https://github.com/Ratamacue9112/CopperDC/tree/e085fdf82f043cf686b8f3bee868b41973771c11)).
- Added `setup_cfg` function ([#22](https://github.com/Ratamacue9112/CopperDC/tree/e085fdf82f043cf686b8f3bee868b41973771c11)).
- Added `DebugConsole.Monitor` class ([#25](https://github.com/Ratamacue9112/CopperDC/tree/120fba03bc8c93e88177410ba1933fc040a856ca)).
- Added `show_monitor` command ([#25](https://github.com/Ratamacue9112/CopperDC/tree/120fba03bc8c93e88177410ba1933fc040a856ca)).
- Added ability to hide monitors by setting the `visible` parameter in the `add_monitor` function. This is set to `true` by default ([#25](https://github.com/Ratamacue9112/CopperDC/tree/120fba03bc8c93e88177410ba1933fc040a856ca)).
- Added `set_monitor_visible` function ([#25](https://github.com/Ratamacue9112/CopperDC/tree/120fba03bc8c93e88177410ba1933fc040a856ca)).
- Added 6 new built-in monitors. All 6 and the "Physics Process" monitor are hidden by default, only the "FPS" monitor is visible ([#25](https://github.com/Ratamacue9112/CopperDC/tree/120fba03bc8c93e88177410ba1933fc040a856ca)).
  
### Changed
- Moved the `clear` command from `debug_console.gd` to `built_in_commands.gd` ([#19](https://github.com/Ratamacue9112/CopperDC/tree/959d6b624e10a0278d01160b51381a42220398b8)).
- Changed how hiding and showing the console works, to allow for some elements to stay visible ([#20](https://github.com/Ratamacue9112/CopperDC/tree/6a7f5c835179bb42c60b0af47795ea7fa2fce8dd)).
- Renamed plugin entry script to `dc_entry.gd` ([#23](https://github.com/Ratamacue9112/CopperDC/tree/3e21a1f44b51b5ac5a89e58574bd277ae0fa03df)).
- Delayed the initializing of the built-in commands by 0.05 seconds to ensure all cfgs and monitors from other scripts have loaded ([#25](https://github.com/Ratamacue9112/CopperDC/tree/120fba03bc8c93e88177410ba1933fc040a856ca)).
- Monitors are now identified with an ID, a display name is given on creation. All functions have been changed accordingly ([#26](https://github.com/Ratamacue9112/CopperDC/tree/616159de923cc9ff7bc3f2beba23d0abcf1a8c6b)).
- Updated .gitignore ([#27](https://github.com/Ratamacue9112/CopperDC/tree/15982e91d76ff556c13187f171ecb387fb79ffdc)).

### Fixed
- Fixed bool parameter type not working ([#21](https://github.com/Ratamacue9112/CopperDC/tree/94c54fc7e4bba6e54a4ced9fc992c13b7a3ffa77)).
- Fixed log not wrapping on long messages ([#22](https://github.com/Ratamacue9112/CopperDC/tree/e085fdf82f043cf686b8f3bee868b41973771c11)).

### Removed
- Removed "Monitor {name} already exists." error message ([#25](https://github.com/Ratamacue9112/CopperDC/tree/120fba03bc8c93e88177410ba1933fc040a856ca)).
- Removed unnecessary .tmp files ([#28](https://github.com/Ratamacue9112/CopperDC/tree/b1ad0ec28fdab807710c628be650f83e31b02897)).

## [1.0.0](https://github.com/Ratamacue9112/CopperDC/tree/v1.0.0) (2023-11-22)
Initial release
