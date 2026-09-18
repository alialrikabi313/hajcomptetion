# -*- coding: utf-8 -*-
"""Extract the questions of the مدرك (1447 exam) PDF."""
import io, os, re, json, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import parse as P
from extract2 import Line, LABELS, ORD_WORDS, ANSWER_HEAD, OPT_LINE, split_inline

BASE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(BASE, 'txt', 'مدرك_اجوبة_اسئلة_المرشدين_لسنة_1447_1.json')
AR2EN = str.maketrans('٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹', '01234567890123456789')
D = '[٠-٩۰-۹0-9]'
Q_START = re.compile(r'^\s*(?:س|من)\s*[:\s/]*(' + D + r'+)\s*[:\-/]?\s*')
OPT = re.compile(r'^\s*([أابجد])\s*[ـ\-–]\s*')
SUPPORT = re.compile(r'^\s*(السؤال|الجواب\s*:|ملاحظة|مسألة|جواب\s*:)')


def main():
    data = json.load(io.open(SRC, encoding='utf-8'))
    recs = [r for r in data['lines'] if r['text'].strip()
            and (r.get('size', 14.0) >= 12.3 or 'الجواب' in r['text'])]
    seen = {}
    for r in recs:
        seen.setdefault(r['text'].strip(), set()).add(r['page'])
    npages = max(r['page'] for r in recs)
    repeated = {t for t, pgs in seen.items()
                if len(pgs) >= max(3, npages * 0.25) and len(t) > 8
                and 'الجواب' not in t}
    recs = [r for r in recs if r['text'].strip() not in repeated]
    blocks, cur = [], None
    for r in recs:
        t = r['text'].strip()
        ln = Line(t)
        m = Q_START.match(ln.s)
        if m and len(t) > 12:
            if cur:
                blocks.append(cur)
            cur = {'num': int(m.group(1).translate(AR2EN)), 'page': r['page'],
                   'lines': [ln.raw_from(m.end()).strip()], 'raw': [t]}
            continue
        if cur is None:
            continue
        cur['lines'].append(t)
        cur['raw'].append(t)
    if cur:
        blocks.append(cur)

    out = []
    for b in blocks:
        qtext, opts, ans, ref = [], [], None, ''
        state = 'q'
        for line in b['lines']:
            ln = Line(line)
            if state != 'done' and ANSWER_HEAD.search(ln.ns):
                ah = ANSWER_HEAD.search(ln.ns)
                mo = ORD_WORDS.search(ln.ns[ah.end():][:60])
                if mo:
                    ans = P.ORD[mo.group(1)]
                ref = line
                state = 'done'
                continue
            if state == 'done':
                continue
            if SUPPORT.match(ln.s):
                state = 'done'
                continue
            pieces = (split_inline(line)
                      if (state == 'opt' or OPT_LINE.match(ln.s)) else [line])
            for piece in pieces:
                pl = Line(piece)
                mo = OPT_LINE.match(pl.s)
                if mo:
                    label = mo.group(1) or mo.group(2) or mo.group(3)
                    opts.append([LABELS.get(label, len(opts)),
                                 pl.raw_from(mo.end()).strip()])
                    state = 'opt'
                elif state == 'opt' and opts:
                    opts[-1][1] += ' ' + piece.strip()
                else:
                    qtext.append(piece.strip())
        out.append({'file': 'مدرك', 'num': b['num'], 'page': b['page'],
                    'question': re.sub(r'\s+', ' ', ' '.join(qtext)).strip(),
                    'labels': [o[0] for o in opts],
                    'options': [re.sub(r'\s+', ' ', o[1]).strip() for o in opts],
                    'ans': ans, 'ref': ref, 'raw': b['raw']})
    nums = [q['num'] for q in out]
    print('questions:', len(out), 'max', max(nums))
    print('gaps:', [n for n in range(1, max(nums) + 1) if n not in nums])
    print('dups:', sorted({n for n in nums if nums.count(n) > 1}))
    print('no-ans:', [q['num'] for q in out if q['ans'] is None])
    print('bad-opts:', [q['num'] for q in out if len(q['options']) < 3])
    json.dump(out, io.open(os.path.join(BASE, 'madrak_questions.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)


if __name__ == '__main__':
    main()
