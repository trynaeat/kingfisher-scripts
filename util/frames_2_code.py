import click
import imageio.v3 as iio
from pathlib import Path
import cv2
import numpy as np

def toLuaCode(dict):
    str = ''
    for rgb in dict:
        pixels = ''
        for pixel in dict[rgb]:
            pixels += f'{pixel},'
        pixels = pixels[:-1]
        str += f'={rgb}={pixels}'
    return str

def encode16 (pixel):
    return pixel[0] * 256 + pixel[1]

def encodeRGB16 (rgb):
    return rgb[0] * 256 * 256 + rgb[1] * 256 + rgb[2]

# img is a numpy array of RGBs
# Returns dict with <color> -> <mask>
def colorMask (img):
    masks = dict()
    (w, h, _) = img.shape
    colors = np.unique(img.reshape(-1, 3), axis=0)
    print(colors)
    for c in colors:
        (r, g, b) = c
        if np.all(c==[255,255,255]):
            continue
        print(f'Color: {c}')
        mask = np.zeros((h, w), np.uint8)
        mask[np.all(img==c, axis=-1)] = 255
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


@click.command()
@click.argument('dir')
@click.option('--gamma-correction', type=float, default=2.1, show_default=True)
@click.option('--test-image', type=int)
@click.option('--filesize', type = int, default=4096, show_default=True)
@click.option('--out', type=str, default="out", show_default=True)
def frames2Code(dir, gamma_correction, test_image, filesize, out):
    images = list()
    codeOut = ''
    for file in sorted(Path(dir).iterdir()):
        click.echo(file.name)
        if not file.is_file():
            continue
        img = iio.imread(file)
        masks = colorMask(img)
        invGamma = gamma_correction
        table = np.array([((i / 255.0) ** invGamma) * 255
            for i in np.arange(0, 256)]).astype("uint8")
        img = cv2.LUT(img, table)
        images.append(img)
    for i, img in enumerate(images):
        imgCode = dict()
        for y, row in enumerate(img):
            for x, val in enumerate(row):
                rgb = hex(encodeRGB16(val))[2:]
                if rgb != '0':
                    if not rgb in imgCode:
                        imgCode[rgb] = list()
                    pixelHex = hex(encode16((x, y)))
                    imgCode[rgb].append(pixelHex[2:])
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