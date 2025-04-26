REM This script is used to build the ACE tools 
cd game/deps/ace/tools
mkdir build
cd build
cmake ..  -G "MinGW Makefiles" -DCMAKE_C_COMPILER="gcc" -DCMAKE_MAKE_PROGRAM="mingw32-make.exe"
cmake --build .