#!/bin/bash

rm -rf build && mkdir build && cd build && \
cmake .. && \
cmake --build . -j$(sysctl -n hw.ncpu)