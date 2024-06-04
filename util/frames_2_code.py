import click
import imageio.v3 as iio
from pathlib import Path
import cv2
import numpy as np

@click.command()
@click.argument('dir')
@click.option('--gamma-correction', type=float, default=2.1, show_default=True)

def frames2Code(dir, gamma_correction):
    images = list()
    codeOut = dict()
    for file in Path(dir).iterdir():
        if not file.is_file():
            continue
        img = iio.imread(file)
        invGamma = gamma_correction
        table = np.array([((i / 255.0) ** invGamma) * 255
            for i in np.arange(0, 256)]).astype("uint8")
        img = cv2.LUT(img, table)
        images.append(img)
        print(len(images))
    testImg = images[20]
    for y, row in enumerate(testImg):
        for x, val in enumerate(row):
            rgb = (val[0], val[1], val[2])
            if rgb != (0, 0, 0):
                if not rgb in codeOut:
                    codeOut[rgb] = list()
                codeOut[rgb].append((x, y))
    iio.imwrite("./test.png", testImg)
    with open("./test.txt", 'w') as text_file:
        text_file.write(str(codeOut))

if __name__ == '__main__':
    frames2Code()