# frames_2_code

## Purpose
This is a quick and dirty utility I made to convert a gif (or directory of PNGs) into a simple text format describing a set of rectangles for every color in the image. It will spit out this text out to files in chunks (default 4kb each, AFAIK the largest allowed size for a text property in stormworks). Data format described at the end of this README. Each chunk is placed as a text property on the script (gets around hard script length limitation of 4kb). You can then parse this data back in Lua code to get all of the frames and play it back. See `animation_test.lua` for an implementation of this.

## Usage

(First Time) Create a Python venv in this directory

`python3 -m venv ./`

(Subsequent Times) Activate the venv

`source bin/activate`

Install Dependencies

`pip install -r requirements.txt`

Run it

`python ./frames_2_code.py <file.gif_or_directory>`

Full list of options

`python ./frames_2_code.py --help`

## Data Format
It's a kinda ad-hoc format that accomplishes a somewhat compact size and is also simple to parse with regex.
The basic layout is like so:
`{<frame1>|<frame2>|...|<frameN>}`

Where each frame contains the following:
`=<color1>=<rect1>,<rect2>,...,<rectN>=<color2>=<rect1>,<rect2>,...,<rectN>...`

Each color described above is a 3 byte hex integer. From left to right the bytes are the R, G, and B channels.

Each rect is a 4 byte hex integer. From left to right the bytes are X, Y, Width, Height.

## Limitations
If you read the data format bit above you'll notice X, Y, Width, Height are all stored in 1 byte. That means at most they can store a value from 0-255, in other words it can only work on images of size 255x255 or less (8x8 monitor in Stormworks)
