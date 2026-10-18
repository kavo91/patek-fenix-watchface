#!/usr/bin/env python3
"""Build the store images from evidence/store-*.png (416x416 simulator captures of the 92 % builds).
Every output stays under the Connect IQ Store's 150 KB limit: palette PNG when it fits, JPEG otherwise."""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EV = os.path.join(ROOT, 'evidence')
OUT = os.path.join(ROOT, 'store')
FONT = os.path.expanduser('~/Library/Fonts/Roboto-Medium.ttf')

LIMIT = 150000   # Connect IQ Store: every image must be under 150 KB (count 1000-byte KB to be safe)

def save_small(im, base):
    """Write base.png (256-colour palette) if it fits under the store limit, else base.jpg at the highest quality that fits."""
    png = base + '.png'
    im.convert('RGB').quantize(colors=256, method=Image.MEDIANCUT, dither=Image.NONE).save(png, optimize=True)
    if os.path.getsize(png) < LIMIT:
        print('wrote', os.path.basename(png), os.path.getsize(png) // 1024, 'KB')
        return png
    os.remove(png)
    jpg = base + '.jpg'
    for q in (95, 92, 90, 88, 85, 80, 75):
        im.convert('RGB').save(jpg, quality=q, optimize=True, subsampling=0)
        if os.path.getsize(jpg) < LIMIT:
            break
    print('wrote', os.path.basename(jpg), os.path.getsize(jpg) // 1024, 'KB', 'q', q)
    return jpg

def masked(name, r=196):
    im = Image.open(os.path.join(EV, name)).convert('RGB')
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).ellipse((208 - r, 208 - r, 208 + r, 208 + r), fill=255)
    black = Image.new('RGB', im.size, (0, 0, 0))
    return Image.composite(im, black, mask)

shots = {
    'screen-1-light.png': 'store-light.png',
    'screen-2-dark.png': 'store-dark.png',
    'screen-3-fields.png': 'store-alt.png',
    'screen-4-always-on.png': 'store-aod.png',
}
faces = {}
for out, src in shots.items():
    im = masked(src)
    save_small(im, os.path.join(OUT, out[:-4]))
    faces[out] = im

dark = faces['screen-2-dark.png']
light = faces['screen-1-light.png']

# cover: dark face filling a 500 square
save_small(dark.resize((500, 500), Image.LANCZOS), os.path.join(OUT, 'cover-500x500'))

# icon: dark face at 128
dark.resize((128, 128), Image.LANCZOS).save(os.path.join(OUT, 'icon-128.png'), optimize=True)
print('wrote icon-128.png', os.path.getsize(os.path.join(OUT, 'icon-128.png')) // 1024, 'KB')

# hero: both faces on black with the name
hero = Image.new('RGB', (1440, 720), (0, 0, 0))
size = 560
hero.paste(light.resize((size, size), Image.LANCZOS), (120, 80))
hero.paste(dark.resize((size, size), Image.LANCZOS), (760, 80))
d = ImageDraw.Draw(hero)
try:
    f1 = ImageFont.truetype(FONT, 44)
    f2 = ImageFont.truetype(FONT, 22)
except OSError:
    f1 = f2 = ImageFont.load_default()
title = 'Patek FENIX'
sub = 'Analog watch face for the fēnix 9 Pro 43mm'
w1 = d.textlength(title, font=f1)
w2 = d.textlength(sub, font=f2)
d.text(((1440 - w1) / 2, 660 - 44), title, font=f1, fill=(200, 203, 208))
d.text(((1440 - w2) / 2, 660 + 6), sub, font=f2, fill=(138, 142, 148))
save_small(hero, os.path.join(OUT, 'hero-1440x720'))
