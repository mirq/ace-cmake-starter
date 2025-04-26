#!/bin/bash
# This script is used to build the ACE tools
cd game/deps/ace/tools
mkdir -p build
cd build
cmake .. -DCMAKE_C_COMPILER="gcc"
cmake --build .