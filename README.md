# What's this
This configuration is based on [Pololu A-Star configuration](https://github.com/pololu/a-star) and is customized for VIVIWARE Cell Custom and Branch which can be installed on Arduino IDE.

# How to setup
Refer to [README on VivicoreSerial library](https://github.com/vivitainc/VivicoreSerial#how-to-setup).

# Version history
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
