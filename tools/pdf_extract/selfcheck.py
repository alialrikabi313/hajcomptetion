# -*- coding: utf-8 -*-
"""Character-level check that the parser neither dropped nor invented text:
recompose every bank entry and compare it with the decoded source block."""
import io, os, re, sys, json, difflib, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import parse as P
import build as B
from extract2 import (Line, Q_START, ALT_START, OPT_LINE, YEAR, SECTION, D,
                      split_inline, load_lines)

BASE = os.path.dirname(os.path.abspath(__file__))
PROJ = r'C:\Users\msi\StudioProjects\hajcomptetion'
_lines = {}


def lines_of(name):
    if name not in _lines:
        _lines[name] = json.load(io.open(os.path.join(BASE, 'txt', name + '.json'),
                                         encoding='utf-8'))['lines']
    return _lines[name]


_rep = {}


def repeated_of(name):
    if name not in _rep:
        data = json.load(io.open(os.path.join(BASE, 'txt', name + '.json'),
                                 encoding='utf-8'))
        seen = {}
        for r in data['lines']:
            seen.setdefault(r['text'].strip(), set()).add(r['page'])
        npages = max(r['page'] for r in data['lines'])
        _rep[name] = {t for t, pgs in seen.items()
                      if len(pgs) >= max(3, npages * 0.25) and len(t) > 8
                      and 'الجواب' not in t and 'ينظر' not in t}
    return _rep[name]


YEAR2 = re.compile(r'^في\s*سنة\s*' + D + r'+')


def block_of(name, first_line):
    lines = lines_of(name)
    start = next((k for k, r in enumerate(lines)
                  if r['text'].strip() == first_line.strip()), None)
    if start is None:
        return None
    out = [lines[start]]
    for r in lines[start + 1:]:
        t = r['text'].strip()
        if r.get('size', 14.0) < 12.3:
            continue
        ln = Line(t)
        if Q_START.match(ln.s) or (len(t) > 25 and ALT_START.match(ln.s)):
            break
        if YEAR2.match(ln.s) or SECTION.match(ln.s):
            continue
        if P.is_noise(t) or t in repeated_of(name):
            continue
        out.append(r)
    return out


SIG = re.compile(r'[^\u0621-\u064a]')          # keep bare Arabic letters only


def sig(s):
    return SIG.sub('', P.strip_diac(B.clean(s)))


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
    bad = []
    stats = collections.Counter()
    for i, b in enumerate(bank):
        key = srcmap[i]
        if key.startswith('مدرك'):
            stats['madrak_skipped'] += 1        # different layout, checked separately
            continue
        q = pdfq.get(key)
        if q is None:
            bad.append({'i': i, 'why': 'NO_SOURCE', 'key': key})
            continue
        blk = block_of(q['file'], q['raw'][0])
        if blk is None:
            bad.append({'i': i, 'why': 'NO_BLOCK', 'key': key})
            continue
        parts = []
        for k, r in enumerate(blk):
            t = r['text'].strip()
            ln = Line(t)
            if k == 0:
                m = Q_START.match(ln.s)
                if m:
                    t = ln.raw_from(m.end())
                    ln = Line(t)
            pieces = []
            for piece in split_inline(t):
                pl = Line(piece)
                mo = OPT_LINE.match(pl.s)
                pieces.append(pl.raw_from(mo.end()) if mo else piece)
            t = ' '.join(pieces)
            ln = Line(t)
            ma = B.ORD_RE.search(ln.s)
            if ma:
                t = ln.raw_from(ma.end())
            parts.append(t)
        expected = sig(' '.join(parts))
        actual = sig(' '.join([b['question']] + b['options'] + [b['answer_reference']]))
        # the parser legitimately drops the numbering, the option labels and the
        # "الجواب الصحيح هو الأول" lead-in; compare what is left as a sequence
        if expected == actual:
            stats['exact'] += 1
            continue
        sm = difflib.SequenceMatcher(None, expected, actual)
        missing = ''.join(expected[i1:i2] for tag, i1, i2, j1, j2 in sm.get_opcodes()
                          if tag in ('delete', 'replace'))
        extra = ''.join(actual[j1:j2] for tag, i1, i2, j1, j2 in sm.get_opcodes()
                        if tag in ('insert', 'replace'))
        if not missing and not extra:
            stats['exact'] += 1
            continue
        stats['diff'] += 1
        bad.append({'i': i, 'why': 'DIFF', 'key': key,
                    'missing': missing[:160], 'extra': extra[:160],
                    'ratio': round(sm.ratio(), 4), 'question': b['question'][:80]})
    json.dump(bad, io.open(os.path.join(BASE, 'selfcheck.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    print(dict(stats))
    print('flagged:', len(bad))
    for x in bad[:15]:
        print(' •', x['key'], x.get('ratio'), '|', x.get('question', ''))
        if x.get('missing'):
            print('    ناقص:', x['missing'][:110])
        if x.get('extra'):
            print('    زائد :', x['extra'][:110])


if __name__ == '__main__':
    main()
