import os
import sys

try:
    from PIL import Image
except ImportError:
    response = input("This script requires the image processing package, Pillow. \nWould you like to download it? (y/n) ")
    if response.strip() == "y":
        os.system("pip3 install pillow")
        from PIL import Image
    else:
        sys.exit()

if len(sys.argv) != 2:
    print("Usage: pictomem.py FileName.jpg")
    sys.exit()

imageName = sys.argv[1]
path = ""

file = Image.open(imageName)
img = file.quantize(256)
pixels = img.load()

pal = [color >> 4 for color in img.getpalette()]
colors = [pal[3 * n:3 * (n + 1)] for n in range(len(pal) // 3)]

with open(path + "colors.mem", "w") as memFile:
    for n in range(len(colors) // 8):
        row = [hex(c[0])[2:] + hex(c[1])[2:] + hex(c[1])[2:] for c in colors[8 * n:8 * (n + 1)]]
        memFile.write(" ".join(row) + "\n")

with open(path + "image.mem", "w") as memFile:
    for y in range(img.size[1]):
        row = [hex(pixels[x, y])[2:] for x in range(img.size[0])]
        memFile.write(" ".join(row) + "\n")
