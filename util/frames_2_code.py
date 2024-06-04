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


@click.command()
@click.argument('dir')
@click.option('--gamma-correction', type=float, default=2.1, show_default=True)
@click.option('--test-image', type=int)
def frames2Code(dir, gamma_correction, test_image):
    images = list()
    codeOut = ''
    for file in sorted(Path(dir).iterdir()):
        click.echo(file.name)
        if not file.is_file():
            continue
        img = iio.imread(file)
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
    chunkSize = 4096
    chunks = [codeOut[i:i+chunkSize] for i in range(0, len(codeOut), chunkSize)]

    if test_image:
        testImg = images[test_image]
        iio.imwrite("./test.png", testImg)
    for i, chunk in enumerate(chunks):
        with open(f'test{i}.txt', 'w') as text_file:
            click.echo(f'test{i}.txt')
            text_file.write(chunk)

if __name__ == '__main__':
    frames2Code()