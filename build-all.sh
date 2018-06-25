#!/bin/bash

set -e

# builds an Arduino core library for each known board.
# Run the script from the build directory.
toolchain_file=$HOME/loseavr/src/avr-cmake/generic-gcc-avr.cmake
install_prefix=$HOME/loseavr/toolchain/arduino_cores
script_folder=$(cd $(dirname $0) && pwd)

mkdir -p build
cd build

for board_name in $(grep '\(.*\)\.name=' $script_folder/boards.txt | cut -d . -f 1)
do
	mkdir -p $board_name
	cd $board_name
	cmake $script_folder -DBOARD=$board_name -DCMAKE_TOOLCHAIN_FILE=$toolchain_file -G"MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$install_prefix/$board_name
	mingw32-make -j1 install
	cd ..
done
