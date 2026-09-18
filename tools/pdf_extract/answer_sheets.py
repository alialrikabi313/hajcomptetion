# -*- coding: utf-8 -*-
"""Stack the answer lines that OCR could not read, for reading by eye."""
import io, os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fitz
import verify_answers as V
from PIL import Image, ImageDraw

BASE = os.path.dirname(os.path.abspath(__file__))
PER = 12


def main():
    res = json.load(io.open(os.path.join(BASE, 'answer_check.json'), encoding='utf-8'))
    todo = [x for x in res if x['status'] in ('ORDINAL_UNREAD', 'NO_ANSWER_LINE')]
    pdfq = {'%s#%d' % (q['file'], q['num']): q
            for q in json.load(io.open(os.path.join(BASE, 'pdf_questions.json'),
                                       encoding='utf-8'))}
    mad = {'مدرك#%d' % q['num']: q
           for q in json.load(io.open(os.path.join(BASE, 'madrak_questions.json'),
                                      encoding='utf-8'))}
    rows = []
    for x in todo:
        key = x['key']
        madrak = key.startswith('مدرك')
        q = mad.get(key) if madrak else pdfq.get(key)
        name = V.MADRAK if madrak else q['file']
        loc = V.answer_line(name, q['raw'][0])
        if loc is None:
            rows.append((x, None))
            continue
        doc = V.doc_of(name)
        page = doc[loc[0] - 1]
        clip = fitz.Rect(15, max(0, loc[1] - 16), page.rect.width - 10, loc[1] + 7)
        pix = page.get_pixmap(matrix=fitz.Matrix(2.2, 2.2), clip=clip)
        rows.append((x, Image.frombytes('RGB', (pix.width, pix.height), pix.samples)))
    made = []
    for s in range(0, len(rows), PER):
        chunk = rows[s:s + PER]
        imgs = [im for _, im in chunk if im is not None]
        if not imgs:
            continue
        W = max(im.width for im in imgs) + 70
        H = sum((im.height if im else 30) + 12 for _, im in chunk) + 10
        sheet = Image.new('RGB', (W, H), (255, 255, 255))
        dr = ImageDraw.Draw(sheet)
        y = 6
        for x, im in chunk:
            dr.text((6, y + 8), '#%d' % x['i'], fill=(0, 0, 200))
            if im is not None:
                sheet.paste(im, (66, y))
                y += im.height + 12
            else:
                dr.text((66, y + 8), 'NO ANSWER LINE', fill=(200, 0, 0))
                y += 30 + 12
            dr.line([(0, y - 6), (W, y - 6)], fill=(210, 210, 210))
        p = os.path.join(BASE, 'ans%02d.png' % (s // PER))
        sheet.save(p)
        made.append(p)
    json.dump([x['i'] for x, _ in rows], io.open(os.path.join(BASE, 'ans_order.json'),
                                                 'w', encoding='utf-8'))
    print(len(rows), 'rows in', len(made), 'sheets')


if __name__ == '__main__':
    main()
