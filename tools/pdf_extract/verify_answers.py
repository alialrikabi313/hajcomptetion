# -*- coding: utf-8 -*-
"""OCR just the answer line of every question and confirm the ordinal matches
the correct answer stored in the app."""
import io, os, re, sys, json, subprocess, tempfile, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fitz
import parse as P
import build as B
from extract2 import Line, Q_START, ALT_START

BASE = os.path.dirname(os.path.abspath(__file__))
PROJ = r'C:\Users\msi\StudioProjects\hajcomptetion'
TESS = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
MADRAK = 'مدرك_اجوبة_اسئلة_المرشدين_لسنة_1447_1'
ORDS = ['الاول', 'الثاني', 'الثالث', 'الرابع']
ORD_RX = re.compile(r'(الاولى|الاول|الثاني|الثالث|الرابع)')
_lines, _docs = {}, {}


def lines_of(name):
    if name not in _lines:
        _lines[name] = json.load(io.open(os.path.join(BASE, 'txt', name + '.json'),
                                         encoding='utf-8'))['lines']
    return _lines[name]


def doc_of(name):
    if name not in _docs:
        _docs[name] = fitz.open(os.path.join(PROJ, 'assets', name + '.pdf'))
    return _docs[name]


def answer_line(name, first_line):
    """(page, y) of the 'الجواب الصحيح' line that belongs to this question"""
    lines = lines_of(name)
    start = next((k for k, r in enumerate(lines)
                  if r['text'].strip() == first_line.strip()), None)
    if start is None:
        return None
    for r in lines[start + 1:]:
        t = r['text'].strip()
        ln = Line(t)
        if Q_START.match(ln.s) or (len(t) > 25 and ALT_START.match(ln.s)):
            return None
        if B.ORD_RE.search(ln.s):
            return r['page'], r['y']
    return None


def ocr_line(doc, page_no, y, zoom=6.0):
    page = doc[page_no - 1]
    clip = fitz.Rect(15, max(0, y - 15), page.rect.width - 10,
                     min(page.rect.height, y + 6))
    pix = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), clip=clip)
    with tempfile.TemporaryDirectory() as d:
        png = os.path.join(d, 'l.png')
        pix.save(png)
        out = os.path.join(d, 'o')
        subprocess.run([TESS, png, out, '-l', 'ara', '--psm', '7'],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            return io.open(out + '.txt', encoding='utf-8').read()
        except FileNotFoundError:
            return ''


def main():
    bank = json.load(io.open(os.path.join(PROJ, 'assets', 'haj_questions.json'),
                             encoding='utf-8'))
    srcmap = json.load(io.open(os.path.join(BASE, 'bank_src_map.json'), encoding='utf-8'))
    pdfq = {'%s#%d' % (q['file'], q['num']): q
            for q in json.load(io.open(os.path.join(BASE, 'pdf_questions.json'),
                                       encoding='utf-8'))}
    mad = {'مدرك#%d' % q['num']: q
           for q in json.load(io.open(os.path.join(BASE, 'madrak_questions.json'),
                                      encoding='utf-8'))}
    res, stats = [], collections.Counter()
    for i, b in enumerate(bank):
        key = srcmap[i]
        madrak = key.startswith('مدرك')
        q = mad.get(key) if madrak else pdfq.get(key)
        name = MADRAK if madrak else q['file']
        idx = b['options'].index(b['correct_answer'])
        loc = answer_line(name, q['raw'][0])
        rec = {'i': i, 'key': key, 'bank_idx': idx, 'question': b['question'][:70]}
        if loc is None:
            rec['status'] = 'NO_ANSWER_LINE'
            stats['no_line'] += 1
        else:
            text = ocr_line(doc_of(name), loc[0], loc[1])
            flat = re.sub(r'\s+', '', P.norm(text))
            m = ORD_RX.search(flat)
            rec['ocr'] = text.strip()[:90]
            if not m:
                rec['status'] = 'ORDINAL_UNREAD'
                stats['unread'] += 1
            else:
                word = m.group(1)
                got = 0 if word.startswith('الاول') else ORDS.index(word)
                rec['ocr_idx'] = got
                if got == idx:
                    rec['status'] = 'OK'
                    stats['ok'] += 1
                else:
                    rec['status'] = 'MISMATCH'
                    stats['mismatch'] += 1
        res.append(rec)
        if (i + 1) % 100 == 0:
            print('%d/%d %s' % (i + 1, len(bank), dict(stats)), flush=True)
    json.dump(res, io.open(os.path.join(BASE, 'answer_check.json'), 'w',
                           encoding='utf-8'), ensure_ascii=False, indent=1)
    print('FINAL', dict(stats))


if __name__ == '__main__':
    main()
