#!/bin/sh
export __GLX_VENDOR_LIBRARY_NAME=mesa MESA_LOADER_DRIVER_OVERRIDE=zink GALLIUM_DRIVER=zink

python3 ../shadertoy-render.py --output 1.mov --vispy_use=egl --size=3840x2160 --rate=1 --duration=1.0 --time=6969.69 --bitrate=8M main_image.glsl

rm -rf frames
mkdir frames
ffmpeg -i 1.mov -vf fps=1 "frames/out%d.png"


# remember to set alpha in shader
# this shader edited alpha set to 1.0, else image would be translarent.


