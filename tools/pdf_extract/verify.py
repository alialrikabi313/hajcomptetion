# -*- coding: utf-8 -*-
"""Independent check of the built bank: render each question's block from the
source PDF, OCR it with tesseract (a path that shares nothing with the font
decoder), and compare question / options / answer ordinal."""
import io, os, re, sys, json, difflib, subprocess, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fitz
import parse as P
from extract2 import Line, Q_START, ALT_START
from compare import TOPIC_OF_FILE

AR = str.maketrans('٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹', '01234567890123456789')
_index, _docs = {}, {}


def lines_of(name):
    if ('L', name) not in _index:
        data = json.load(io.open(os.path.join(BASE, 'txt', name + '.json'),
                                 encoding='utf-8'))
        _index[('L', name)] = data['lines']
    return _index[('L', name)]


def locate_by_text(name, first_line):
    """block bounds found by matching the question's own first line"""
    lines = lines_of(name)
    start = None
    for k, r in enumerate(lines):
        if r['text'].strip() == first_line.strip():
            start = k
            break
    if start is None:
        return []
    p0, y0 = lines[start]['page'], lines[start]['y']
    nxt = None
    for r in lines[start + 1:]:
        if r.get('size', 14.0) < 12.3:
            continue
        ln = Line(r['text'].strip())
        if Q_START.match(ln.s) or (len(r['text'].strip()) > 25 and ALT_START.match(ln.s)):
            nxt = r
            break
    if nxt and nxt['page'] == p0:
        return [(p0 - 1, y0 - 20, nxt['y'] + 2)]
    out = [(p0 - 1, y0 - 20, 830)]
    if nxt:
        for p in range(p0 + 1, nxt['page']):
            out.append((p - 1, 0, 830))
        out.append((nxt['page'] - 1, 0, nxt['y'] + 2))
    return out


def index_of(name):
    """{num: (page, y)} for every question start in a decoded source file"""
    if name not in _index:
        data = json.load(io.open(os.path.join(BASE, 'txt', name + '.json'),
                                 encoding='utf-8'))
        starts, last = {}, 0
        for r in data['lines']:
            t = r['text'].strip()
            if r.get('size', 14.0) < 12.3:
                continue
            ln = Line(t)
            m = Q_START.match(ln.s)
            if m:
                last = int(m.group(1).translate(AR))
                starts.setdefault(last, (r['page'], r['y']))
            elif last and len(t) > 25 and ALT_START.match(ln.s):
                last += 1
                starts.setdefault(last, (r['page'], r['y']))
        _index[name] = starts
    return _index[name]


def doc_of(name):
    if name not in _docs:
        _docs[name] = fitz.open(os.path.join(PROJ, 'assets', name + '.pdf'))
    return _docs[name]


def locate(name, num):
    idx = index_of(name)
    if num not in idx:
        return []
    p0, y0 = idx[num]
    nxt = idx.get(num + 1)
    if nxt and nxt[0] == p0:
        return [(p0 - 1, y0 - 20, nxt[1] + 2)]
    out = [(p0 - 1, y0 - 20, 830)]
    if nxt:
        for p in range(p0 + 1, nxt[0]):
            out.append((p - 1, 0, 830))
        out.append((nxt[0] - 1, 0, nxt[1] + 2))
    return out

BASE = os.path.dirname(os.path.abspath(__file__))
PROJ = r'C:\Users\msi\StudioProjects\hajcomptetion'
TESS = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
MADRAK = 'مدرك_اجوبة_اسئلة_المرشدين_لسنة_1447_1'
ORD_WORDS = ['الاول', 'الثاني', 'الثالث', 'الرابع']


def norm(s):
    s = P.norm(s or '')
    return re.sub(r'[^\u0621-\u064a]', '', s)


def ratio(a, b):
    return difflib.SequenceMatcher(None, a, b).ratio()


def best_window(hay, needle):
    """best similarity of `needle` against any window of `hay` of its length"""
    if not needle:
        return 1.0
    n = len(needle)
    if len(hay) <= n:
        return ratio(hay, needle)
    best = 0.0
    step = max(1, n // 8)
    for i in range(0, len(hay) - n + 1, step):
        best = max(best, ratio(hay[i:i + n + step], needle))
        if best > 0.97:
            break
    return best


def ocr(pix):
    with tempfile.TemporaryDirectory() as d:
        png = os.path.join(d, 'p.png')
        pix.save(png)
        out = os.path.join(d, 'o')
        subprocess.run([TESS, png, out, '-l', 'ara', '--psm', '6'],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            return io.open(out + '.txt', encoding='utf-8').read()
        except FileNotFoundError:
            return ''


def madrak_locate(num, doc, tables, lines):
    """(page, y0, y1) of a مدرك question block"""
    starts = []
    pat = re.compile(r'^\s*(?:س|من)\s*[:\s/]*([٠-٩۰-۹0-9]+)')
    ar = str.maketrans('٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹', '01234567890123456789')
    for r in lines:
        m = pat.match(Line(r['text'].strip()).s)
        if m and len(r['text']) > 12:
            starts.append((int(m.group(1).translate(ar)), r['page'], r['y']))
    cur = next((s for s in starts if s[0] == num), None)
    if not cur:
        return []
    nxt = next((s for s in starts if s[0] == num + 1), None)
    if nxt and nxt[1] == cur[1]:
        return [(cur[1] - 1, cur[2] - 20, nxt[2] + 2)]
    return [(cur[1] - 1, cur[2] - 20, 830)]


def main():
    bank = json.load(io.open(os.path.join(PROJ, 'assets', 'haj_questions.json'), encoding='utf-8'))
    pdfq = json.load(io.open(os.path.join(BASE, 'pdf_questions.json'), encoding='utf-8'))
    mad = json.load(io.open(os.path.join(BASE, 'madrak_questions.json'), encoding='utf-8'))
    srcmap = json.load(io.open(os.path.join(BASE, 'bank_src_map.json'), encoding='utf-8'))
    by_src = {}
    for q in pdfq:
        by_src['%s#%d' % (q['file'], q['num'])] = q
    for q in mad:
        by_src['مدرك#%d' % q['num']] = dict(q, file='مدرك')

    mdoc = doc_of(MADRAK)
    mlines = json.load(io.open(os.path.join(BASE, 'txt', MADRAK + '.json'),
                               encoding='utf-8'))['lines']

    results = []
    for i, b in enumerate(bank):
        q = by_src.get(srcmap[i]) if i < len(srcmap) else None
        rec = {'i': i, 'topic': b['topic'], 'question': b['question']}
        if q is None:
            rec['status'] = 'NO_SOURCE'
            results.append(rec)
            continue
        rec['src'] = '%s#%s' % (q['file'], q['num'])
        try:
            if q['file'] == 'مدرك':
                parts = madrak_locate(q['num'], mdoc, None, mlines)
                doc = mdoc
            else:
                parts = locate_by_text(q['file'], q['raw'][0]) or locate(q['file'], q['num'])
                doc = doc_of(q['file'])
        except Exception as e:
            rec['status'] = 'LOCATE_ERROR: %s' % e
            results.append(rec)
            continue
        if not parts:
            rec['status'] = 'NOT_LOCATED'
            results.append(rec)
            continue
        text = ''
        for pno, y0, y1 in parts:
            page = doc[pno]
            clip = fitz.Rect(20, max(0, y0), page.rect.width - 15,
                             min(page.rect.height, y1))
            if clip.height < 6:
                continue
            text += ocr(page.get_pixmap(matrix=fitz.Matrix(300 / 72, 300 / 72), clip=clip))
        hay = norm(text)
        rec['q_score'] = round(best_window(hay, norm(b['question'])), 3)
        rec['opt_scores'] = [round(best_window(hay, norm(o)), 3) for o in b['options']]
        # answer ordinal
        idx = b['options'].index(b['correct_answer'])
        flat = re.sub(r'\s+', '', P.norm(text))
        m = re.search(r'الجوابالصحيح.{0,40}?(' + '|'.join(ORD_WORDS) + r')', flat)
        rec['ocr_ord'] = ORD_WORDS.index(m.group(1)) if m else None
        rec['bank_idx'] = idx
        rec['answer_ok'] = (rec['ocr_ord'] == idx) if rec['ocr_ord'] is not None else None
        rec['status'] = 'OK'
        results.append(rec)
        if (i + 1) % 25 == 0:
            print('%d/%d' % (i + 1, len(bank)), flush=True)
    json.dump(results, io.open(os.path.join(BASE, 'verify_results.json'), 'w',
                               encoding='utf-8'), ensure_ascii=False, indent=1)
    bad_q = [r for r in results if r.get('q_score', 1) < 0.75]
    bad_o = [r for r in results if any(s < 0.7 for s in r.get('opt_scores', []))]
    bad_a = [r for r in results if r.get('answer_ok') is False]
    no_a = [r for r in results if r.get('answer_ok') is None and r['status'] == 'OK']
    print('checked', len(results))
    print('question mismatch:', len(bad_q))
    print('option mismatch  :', len(bad_o))
    print('ANSWER mismatch  :', len(bad_a))
    print('ordinal not read :', len(no_a))
    print('unlocated        :', len([r for r in results if r['status'] != 'OK']))


if __name__ == '__main__':
    main()
