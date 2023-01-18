# What's this
This configuration is based on [Pololu A-Star configuration](https://github.com/pololu/a-star) and is customized for VIVIWARE Cell Custom and Branch which can be installed on Arduino IDE.

# How to setup
Refer to [README on VivicoreSerial library](https://github.com/vivitainc/VivicoreSerial#how-to-setup).

# Version history
- 6.3.0-rc1 (2023-01-18): Support VIVIWARE Custom Cell v4 board and v3 as deprecated.
- 6.2.0 (2022-06-19): Support VIVIWARE Custom Cell v3 board.
- 6.1.0 (2022-06-03): Add SPI1 library copied from [MCUdude/MiniCore](https://github.com/MCUdude/MiniCore).
                      Add new option for UserBranch
- 6.0.2 (2021-09-01): Fixed LED_BUILTIN macro definition.
- 6.0.1 (2021-06-23): VIVITA, Inc. -> VIVIWARE JAPAN, Inc.
                      and rename package_vivita_index.json -> package_viviware_index.json.
- 6.0.0 (2021-04-01): Add customized ATmegaBOOT
                      and support VIVIWARE Cell Custom and Branch boards.
- 4.0.2 (2018-04-17): Fixed an unquoted path in build flags that could cause an
                      error when compiling for the 328PB.
- 4.0.1 (2018-04-11): 328PB interrupt vectors should be linked into sketch more
                      reliably.
- 4.0.0 (2018-03-21): Moved selection of A-Star 328PB versions to custom menu.
- 3.1.0 (2018-02-20): Added support for A-Star 328PB.
- 3.0.1 (2016-12-01): Fixed A-Star 32U4 bootloader unlock/lock bits.
- 3.0.0 (2015-12-15): Restructured repository to work with the Arduino Boards
                      Manager.
- 2.0.0 (2015-09-01): Separated Arduino libraries into their own repositories
                      and removed them from this repository.
