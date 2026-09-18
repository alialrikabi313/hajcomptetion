# -*- coding: utf-8 -*-
"""Render a batch of question blocks into stacked sheets for visual checking."""
import sys, os, io, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fitz
from PIL import Image, ImageDraw
import shot as S

BASE = os.path.dirname(os.path.abspath(__file__))


def render_one(name, num, zoom=2.4):
    parts = S.locate(name, num)
    if not parts:
        return None
    d, _ = S._doc(name)
    ims = []
    for pno, y0, y1 in parts:
        page = d[pno]
        clip = fitz.Rect(30, max(0, y0), page.rect.width - 20, min(page.rect.height, y1))
        if clip.height < 5:
            continue
        pix = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), clip=clip)
        ims.append(Image.frombytes('RGB', (pix.width, pix.height), pix.samples))
    if not ims:
        return None
    W = max(i.width for i in ims)
    H = sum(i.height for i in ims)
    out = Image.new('RGB', (W, H), (255, 255, 255))
    y = 0
    for im in ims:
        out.paste(im, (0, y))
        y += im.height
    # trim tall empty tails
    return out


def sheet(items, path, per=3, maxh=1500):
    imgs = []
    for name, num in items:
        im = render_one(name, num)
        if im is None:
            print('MISSING', name, num)
            continue
        if im.height > maxh:
            im = im.crop((0, 0, im.width, maxh))
        imgs.append((name, num, im))
    if not imgs:
        return []
    made = []
    for s in range(0, len(imgs), per):
        chunk = imgs[s:s + per]
        W = max(i[2].width for i in chunk)
        H = sum(i[2].height + 34 for i in chunk)
        sh = Image.new('RGB', (W, H), (250, 250, 250))
        dr = ImageDraw.Draw(sh)
        y = 0
        for name, num, im in chunk:
            dr.rectangle([0, y, W, y + 26], fill=(40, 60, 120))
            dr.text((8, y + 8), f'{name}  #  {num}', fill=(255, 255, 255))
            y += 30
            sh.paste(im, (0, y))
            y += im.height + 4
            dr.line([(0, y - 2), (W, y - 2)], fill=(120, 120, 120), width=2)
        p = path % (s // per)
        sh.save(p)
        made.append(p)
    return made


if __name__ == '__main__':
    items = json.load(io.open(sys.argv[1], encoding='utf-8'))
    print(sheet([tuple(x) for x in items], sys.argv[2], per=int(sys.argv[3])))
