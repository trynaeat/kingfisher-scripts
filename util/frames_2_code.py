import click
import imageio.v3 as iio
from pathlib import Path
import cv2
import numpy as np

def toLuaCode(dict):
    str = '{'
    for rgb in dict:
        pixels = ''
        for pixel in dict[rgb]:
            pixels += f'{{{pixel[0]},{pixel[1]}}},'
        pixels = pixels[:-1]
        str += f'{{{rgb[0]},{rgb[1]},{rgb[2]}}}={{{pixels}}},'
    str = str[:-1]
    str += '}'
    return str


@click.command()
@click.argument('dir')
@click.option('--gamma-correction', type=float, default=2.1, show_default=True)
def frames2Code(dir, gamma_correction):
    images = list()
    filesOut = list()
    filesOut.append('')
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
    testImg = images[13]
    for i, img in enumerate(images):
        imgCode = dict()
        for y, row in enumerate(img):
            for x, val in enumerate(row):
                rgb = (val[0], val[1], val[2])
                if rgb != (0, 0, 0):
                    if not rgb in imgCode:
                        imgCode[rgb] = list()
                    imgCode[rgb].append((x, y))
        codeIn = ''
        if len(filesOut) > 0:
            codeIn = filesOut[-1]
        frameCode = f'{{{toLuaCode(imgCode)}}}'
        length = len(''.join(codeIn)) + len(frameCode)
        if length <= 4000:
            if codeIn == '':
                codeOut = frameCode
            else:
                codeOut = ','.join([codeIn, frameCode])
            filesOut[-1] = codeOut
        else:
            # Start a new file for this frame
            codeOut = frameCode
            filesOut.append(codeOut)
    # Wrap up all files (each has a list of comma separated frames) into a table
    for i,file in enumerate(filesOut):
        filesOut[i] = f'{{{file}}}'

    iio.imwrite("./test.png", testImg)
    for i, file in enumerate(filesOut):
        with open(f'test{i}.txt', 'w') as text_file:
            click.echo(f'test{i}.txt')
            text_file.write(file)

if __name__ == '__main__':
    frames2Code()