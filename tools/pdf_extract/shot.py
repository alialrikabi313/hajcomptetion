# -*- coding: utf-8 -*-
"""Render the page region of a given question number from a source PDF."""
import sys, os, io, json, glob, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fitz, pdftext, parse as P
from extract2 import Q_START, Line
from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))
PROJ = r'C:\Users\msi\StudioProjects\hajcomptetion'
AR2EN = str.maketrans('٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹', '01234567890123456789')
_cache = {}


def _doc(name):
    if name not in _cache:
        path = os.path.join(PROJ, 'assets', name + '.pdf')
        d = fitz.open(path)
        pdftext.load_global([path])
        _cache[name] = (d, pdftext.build_tables(d))
    return _cache[name]


def locate(name, num):
    """returns list of (page, y0, y1) covering the question block"""
    d, t = _doc(name)
    hits = []
    for pno in range(d.page_count):
        for y, txt, col, size in pdftext.page_lines(d, t, pno):
            m = Q_START.match(Line(txt.strip()).s)
            if m and int(m.group(1).translate(AR2EN)) in (num, num + 1):
                hits.append((pno, y, int(m.group(1).translate(AR2EN))))
    start = next((h for h in hits if h[2] == num), None)
    if start is None:
        return []
    nxt = next((h for h in hits if h[2] == num + 1), None)
    if nxt and nxt[0] == start[0]:
        return [(start[0], start[1] - 22, nxt[1] + 4)]
    out = [(start[0], start[1] - 22, 850)]
    if nxt:
        for p in range(start[0] + 1, nxt[0]):
            out.append((p, 0, 850))
        out.append((nxt[0], 0, nxt[1] + 4))
    return out


def shot(name, num, out_png, zoom=2.6):
    parts = locate(name, num)
    if not parts:
        print('NOT FOUND', name, num)
        return None
    d, _ = _doc(name)
    ims = []
    for pno, y0, y1 in parts:
        page = d[pno]
        clip = fitz.Rect(0, max(0, y0), page.rect.width, min(page.rect.height, y1))
        if clip.height < 5:
            continue
        pix = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), clip=clip)
        ims.append(Image.frombytes('RGB', (pix.width, pix.height), pix.samples))
    if not ims:
        return None
    W = max(i.width for i in ims)
    H = sum(i.height for i in ims) + 6 * (len(ims) - 1)
    sheet = Image.new('RGB', (W, H), (255, 255, 255))
    y = 0
    for im in ims:
        sheet.paste(im, (0, y))
        y += im.height + 6
    sheet.save(out_png)
    return out_png


if __name__ == '__main__':
    name, num, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
    print(shot(name, num, out))
