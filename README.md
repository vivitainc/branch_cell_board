# What's this
This configuration is based on [Pololu A-Star configuration](https://github.com/pololu/a-star) and is customized for VIVIWARE Cell Custom and Branch which can be installed on Arduino IDE.

# How to setup
Refer to [README on VivicoreSerial library](https://github.com/vivitainc/VivicoreSerial#how-to-setup).

# Version history
- 5.3.0 : GPIO0 |= 1 to notify firmware app if reset condition is watchdog refs #2113
- 5.2.0 : Fix the issue to avoid repeating bootloader reboot infinitely if watchdog reset happens in FW Apps refs #646
- 5.1.0 : Consolidate bootloader both for 328P and 328PB from v5.1 release tag refs #553
- 5.0.0 : Customized bootloader for 328p and 328pb from v5.0 release tag refs #540
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
