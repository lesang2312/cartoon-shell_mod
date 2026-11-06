#!/bin/sh
# Biên dịch lại shader Liquid Glass (cần qsb từ qt6-shadertools / qt6-shader-baker).
cd "$(dirname "$0")" || exit 1
mkdir -p qsb
qsb --glsl "150,300 es,330,430" --hlsl 50 --msl 12 -o qsb/liquid_glass.frag.qsb liquid_glass.frag
