import click
import imageio.v3 as iio
from pathlib import Path
import cv2
import numpy as np

class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

class Rect:
    def __init__(self, x, y, width, height):
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    def __str__(self):
        return f'({self.x},{self.y},{self.width},{self.height})'

def toLuaCode(dict):
    str = ''
    for rgb in dict:
        pixels = ''
        for pixel in dict[rgb]:
            pixels += f'{pixel},'
        pixels = pixels[:-1]
        str += f'={rgb}={pixels}'
    return str
    
# Encodes in 4 bytes:
# x,y,width,height
def encode16 (rect):
    return rect.x * 256 * 256 * 256 + rect.y * 256 * 256 + rect.width * 256 + rect.height

def encodeRGB16 (rgb):
    return rgb[0] * 256 * 256 + rgb[1] * 256 + rgb[2]

# img is a numpy array of RGBs
# Returns dict with <color> -> <mask>
def colorMask (img, debug):
    masks = dict()
    (h, w, _) = img.shape
    colors = np.unique(img.reshape(-1, 3), axis=0)
    for c in colors:
        (r, g, b) = c
        if np.all(c==[0,0,0]):
            continue
        mask = np.zeros((h, w), np.uint8)
        mask[np.all(img==c, axis=-1)] = 255
        if debug:
            imgName = f'DEBUG-{c[0]}-{c[1]}-{c[2]}'
            iio.imwrite(f'{imgName}.png', mask)
        masks[(r, g, b)] = mask
    return masks

# Split img into islands by color
# we create a b/w mask for each individual color first with colorMask, then run this on it
def getIslands(img):
    n, labels = cv2.connectedComponents(img.astype('uint8'))
    islands = [labels == i for i in range(1, n)]
    return islands

# Check if any of the rects already include this point
def rectsContain(rects, point):
    for r in rects:
        if point.x >= r.x and point.x < r.x + r.width and point.y >= r.y and point.y < r.y + r.height:
            return True
    return False

def getRect(rects, img, startPoint):
    (h, w) = img.shape
    endX = startPoint.x
    endY = startPoint.y
    # Check contiguous white pixels to the right
    for x in range(startPoint.x + 1, w):
        if img[startPoint.y, x] == 0 or rectsContain(rects, Point(x, startPoint.y)):
            break
        endX = x
    
    # Check contiguous white pixels downwards
    for y in range(startPoint.y + 1, h):
        row_continues = True
        for x in range(startPoint.x, endX + 1):
            if img[y, x] == 0 or rectsContain(rects, Point(x, y)):
                row_continues = False
                break
        if row_continues:
            endY = y
        else:
            break
    
    return Rect(startPoint.x, startPoint.y, endX - startPoint.x + 1, endY - startPoint.y + 1)

# Split a black/white island into rectangles
# (x, y, width, height)
def getRects(img):
    rects = []
    (h, w) = img.shape
    for y in range(0,h):
        for x in range(0, w):
            point = Point(x, y)
            isWhite = img[point.y][point.x]
            if isWhite and not rectsContain(rects, point):
                rects.append(getRect(rects, img, point))
    return rects
    
# Test drawing out generated rects in 2 tones
def debugDrawRects(rects, width, height):
    i = 0
    colorWheel = [[255, 0, 0], [0, 255, 0], [0, 0, 255], [128, 128, 128]]
    img = np.zeros([height, width, 3], dtype=np.uint8)
    for c in rects.keys():
        rArr = rects[c]
        for r in rArr:
            tone = colorWheel[i % len(colorWheel)]
            for x in range(r.x, r.x + r.width):
                for y in range(r.y, r.y + r.height):
                    img[y][x] = c
            i = i + 1
    iio.imwrite(f'DEBUG_rects.png', img)
    
# Apply gamma function to image
def fixGamma(img, gamma):
    invGamma = gamma
    table = np.array([((i / 255.0) ** invGamma) * 255 for i in np.arange(0, 256)]).astype("uint8")
    img = cv2.LUT(img, table)
    return img

@click.command()
@click.argument('dir')
@click.option('--gamma-correction', type=float, default=2.1, show_default=True)
@click.option('--test-image', type=int)
@click.option('--filesize', type=int, default=4096, show_default=True)
@click.option('--out', type=str, default="out", show_default=True)
@click.option('--debug', type=bool, default=False)
def frames2Code(dir, gamma_correction, test_image, filesize, out, debug):
    images = list()
    colorIslands = dict()
    codeOut = ''
    # If it's a gif just read all the frames in
    if dir.endswith('.gif'):
        click.echo(dir)
        frames = iio.imread(dir, pilmode="RGBA", mode="F")
        for img in frames:
            # Get rid of A channel. Anything transparent gets turned into black (0,0,0)
            (h, w, _) = img.shape
            img[np.where(img[:, :, 3] == 0)] = [0, 0, 0, 1]
            img = cv2.cvtColor(img, cv2.COLOR_RGBA2RGB)
            img = fixGamma(img, gamma_correction)
            images.append(img)
    else:
        # Read all files and gamma correct
        for file in sorted(Path(dir).iterdir()):
            click.echo(file.name)
            if not file.is_file():
                continue
            img = iio.imread(file, pilmode="RGB", mode="F")
            img = fixGamma(img, gamma_correction)
            images.append(img)
    for i, img in enumerate(images):
        rects = dict()
        (h, w, _) = img.shape
        imgCode = dict()
        # split into color islands
        masks = colorMask(img, debug)
        colorIslands = {}  # Clear colorIslands for each frame
        for k in masks.keys():
            islands = getIslands(masks[k])
            colorIslands[k] = islands
        # Then get rects for each island
        for k in colorIslands.keys():
            islands = colorIslands[k]
            for isl in islands:
                r = getRects(isl)
                if not k in rects:
                    rects[k] = []
                rects[k] = rects[k] + r
        if debug:
            debugDrawRects(rects, w, h)
        for color in rects.keys():
            rgb = hex(encodeRGB16(color))[2:]
            imgCode[rgb] = list()
            for r in rects[color]:
                rectHex = hex(encode16(r))
                imgCode[rgb].append(rectHex[2:])
        frameCode = toLuaCode(imgCode)
        if codeOut == '':
            codeOut = frameCode
        else:
            codeOut = '|'.join([codeOut, frameCode])
    # Wrap whole array of frames into its own table
    codeOut = f'{{{codeOut}}}'
    # Split code into 4k files
    chunkSize = filesize
    chunks = []
    if chunkSize == 0:
        chunks = [codeOut]
    else:
        chunks = [codeOut[i:i+chunkSize] for i in range(0, len(codeOut), chunkSize)]
    if test_image:
        testImg = images[test_image]
        iio.imwrite("./test.png", testImg)
    for i, chunk in enumerate(chunks):
        with open(f'{out}{i}.txt', 'w') as text_file:
            click.echo(f'Writing: {out}{i}.txt')
            text_file.write(chunk)

if __name__ == '__main__':
    frames2Code()
