# -*- coding: utf-8 -*-
"""Structured extraction of question records from the decoded PDF text."""
import io, os, re, glob, json, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import parse as P

BASE = os.path.dirname(os.path.abspath(__file__))
AR2EN = str.maketrans('٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹', '01234567890123456789')
D = '[٠-٩۰-۹0-9]'

Q_START = re.compile(r'^[\.\s]*(' + D + r'+)\s*[\.\s]*'
                     r'(?:(?:[سص]|من)\s*(?:[:/]\s*(' + D + r'+)|(' + D + r'+)\s*[:/]|'
                     r'\s*(' + D + r'+)\s+)'
                     r'|/\s*(' + D + r'+)\s+)')
ALT_START = re.compile(r'^\s*[سص]\s*(?:/\s*' + D + r'+|' + D + r'+\s*/)\s*')
OPT_LINE = re.compile(r'^\s*(?:([أابجد])(?:\s*[ـ\-–\.]\s*|\s+)'
                      r'|[-–]\s*([١1٢2٣3٤4])\s+'
                      r'|([١1٢2٣3٤4])\s*[-ـ–]\s*)')
OPT_INLINE = re.compile(r'\s+(?=[بجد]\s*[ـ\-–\.]\s*[^\s])'
                        r'|(?<=[\.\؟])\s+(?=[بجد]\s[^\s])')
YEAR = re.compile(r'^في\s*سنة\s*' + D + r'+\s*$')
SECTION = re.compile(r'^(مسالة|مسألة|صفحة)\s*' + D + r'+\s*$')
ANSWER_HEAD = re.compile(r'الج[وا]{1,3}بالصحيح')
ORD_WORDS = re.compile(r'(الأول|الاول|الثاني|الثانى|الثالث|الرابع)')
LABELS = {'أ': 0, 'ا': 0, 'ب': 1, 'ج': 2, 'د': 3,
          '١': 0, '1': 0, '٢': 1, '2': 1, '٣': 2, '3': 2, '٤': 3, '4': 3}
FOOT = re.compile(r'^\)' + D + r'+\(')


DIAC = 'ًٌٍَُِّْٰٓـ'


class Line:
    """a raw line plus a diacritic-free view with an index map back to the raw"""

    def __init__(self, raw):
        self.raw = raw
        chars, idx = [], []
        for i, ch in enumerate(raw):
            if ch in DIAC:
                continue
            chars.append(ch)
            idx.append(i)
        self.s = ''.join(chars)
        self.idx = idx
        ns, nsidx = [], []
        for ch, i in zip(chars, idx):
            if ch.isspace():
                continue
            ns.append(ch)
            nsidx.append(i)
        self.ns = ''.join(ns)          # no diacritics, no spaces
        self.nsidx = nsidx

    def raw_from(self, pos):
        """raw text starting at stripped position `pos`"""
        if pos >= len(self.idx):
            return ''
        return self.raw[self.idx[pos]:]

    def ns_raw_from(self, pos):
        if pos >= len(self.nsidx):
            return ''
        return self.raw[self.nsidx[pos]:]

    def ns_raw_upto(self, pos):
        if pos >= len(self.nsidx):
            return self.raw
        return self.raw[:self.nsidx[pos]]

    def raw_upto(self, pos):
        if pos >= len(self.idx):
            return self.raw
        return self.raw[:self.idx[pos]]


def load_lines(path):
    """path is the decoded .json file: {'lines':[{page,y,text}], 'highlights':[...]}"""
    data = json.load(io.open(path, encoding='utf-8'))
    raw_pages = {}
    for r in data['lines']:
        raw_pages.setdefault(r['text'].strip(), set()).add(r['page'])
    npages = max((max(v) for v in raw_pages.values() if v), default=1)
    repeated = {t for t, pgs in raw_pages.items()
                if len(pgs) >= max(3, npages * 0.25) and len(t) > 8
                and 'الجواب' not in t and 'ينظر' not in t
                and not OPT_LINE.match(Line(t).s) and not Q_START.match(Line(t).s)}

    body = 14.0
    out, foot = [], []
    for r in data['lines']:
        t = r['text'].strip()
        if not t:
            continue
        if r.get('size', body) < 12.3 and 'الجواب' not in t:
            m = re.match(r'^\)(' + D + r'+)\(\s*(.+)$', t)
            if m and len(re.sub(r'[\s.،؛:]+', '', m.group(2))) >= 3:
                foot.append({'page': r['page'], 'num': m.group(1), 'text': m.group(2).strip()})
                continue
            # a marker may carry a stray dot: ")٣(." — still just a marker
            m2 = re.match(r'^\)(' + D + r'+)\(\s*[.،؛:]*\s*$', t)
            if m2:
                # a bare footnote marker inline in the question/option text —
                # keep it so it can still be matched to its footnote below
                out.append((r['page'], r['y'], '@@MARK ' + m2.group(1)))
                continue
            # a footnote's text sometimes wraps onto a second small-size line
            if (foot and foot[-1]['page'] == r['page'] and not P.is_noise(t)
                    and '/' not in t and '........' not in t):
                foot[-1]['text'] = (foot[-1]['text'] + ' ' + t).strip()
            continue                      # footnote / page furniture
        if P.is_noise(t):
            continue
        ln = Line(t)
        if YEAR.match(ln.s):
            out.append((r['page'], r['y'], '@@YEAR ' + t))
            continue
        if SECTION.match(ln.s):
            continue
        if FOOT.match(ln.s) and len(t) < 12:
            continue
        if t in repeated:
            continue
        out.append((r['page'], r['y'], t))
    return out, data['highlights'], foot


def split_inline(raw):
    """one physical line may hold several options"""
    parts = [raw]
    while True:
        new, changed = [], False
        for p in parts:
            ln = Line(p)
            m = OPT_INLINE.search(ln.s)
            if m:
                new.append(ln.raw_upto(m.start()).strip())
                new.append(ln.raw_from(m.start()).strip())
                changed = True
            else:
                new.append(p)
        parts = new
        if not changed:
            break
    return parts


def parse_file(path):
    lines, highlights, footnotes = load_lines(path)
    blocks, cur = [], None
    year = ''
    for page, ly, t in lines:
        if t.startswith('@@YEAR '):
            m = re.search(r'(' + D + r'{4})', t)
            year = m.group(1).translate(AR2EN) if m else ''
            continue
        if t.startswith('@@MARK '):
            if cur is not None:
                cur['markers'].append((page, t[len('@@MARK '):]))
            continue
        ln = Line(t)
        m = Q_START.match(ln.s)
        if not m and cur and len(t) > 25:
            alt = ALT_START.match(ln.s)
            if alt:
                blocks.append(cur)
                cur = {'file': os.path.basename(path)[:-5], 'page': page,
                       'num': cur['num'] + 1, 'qnum': '', 'year': year,
                       'lines': [(page, ly, ln.raw_from(alt.end()).strip())], 'raw': [t],
                       'markers': []}
                continue
        if m:
            if cur:
                blocks.append(cur)
            cur = {'file': os.path.basename(path)[:-5], 'page': page,
                   'num': int(m.group(1).translate(AR2EN)),
                   'qnum': (m.group(2) or m.group(3) or m.group(4)
                            or m.group(5) or '').translate(AR2EN),
                   'year': year,
                   'lines': [(page, ly, ln.raw_from(m.end()).strip())], 'raw': [t],
                   'markers': []}
            continue
        if cur is None:
            continue
        cur['lines'].append((page, ly, t))
        cur['raw'].append(t)
    if cur:
        blocks.append(cur)

    out = []
    for b in blocks:
        qtext, opts, ans_ord, ans_text, ref = [], [], None, None, []
        ans_hl = False
        state = 'q'
        src = []
        for pg, ly, line in b['lines']:
            ln = Line(line)
            ah = ANSWER_HEAD.search(ln.ns)
            if ah and ah.start() > 0 and ln.ns_raw_upto(ah.start()).strip():
                head = ln.ns_raw_upto(ah.start()).strip()
                if len(head) > 14 or not head.endswith(':'):
                    src.append((pg, ly, head))
                src.append((pg, ly, ln.ns_raw_from(ah.start()).strip()))
            else:
                src.append((pg, ly, line))
        opt_pos = []
        for pg, ly, line in src:
            ln = Line(line)
            ah = ANSWER_HEAD.search(ln.ns)
            if state != 'ans' and ah:
                state = 'ans'
                ref.append(line)
                flat = ln.ns[ah.end():][:60]
                mo = ORD_WORDS.search(flat)
                mx = re.search(r'الخيار\)?([أابجد])\(?', flat)
                if mo:
                    ans_ord = P.ORD[mo.group(1)]
                elif mx:
                    ans_ord = LABELS.get(mx.group(1))
                else:
                    mt = re.search(r'\)([^)]{4,})\(', ln.s[ah.end():])
                    if mt:
                        ans_text = mt.group(1).strip()
                continue
            if state == 'ans':
                ref.append(line)
                continue
            pieces = (split_inline(line)
                      if (state == 'opt' or OPT_LINE.match(Line(line).s))
                      else [line])
            for piece in pieces:
                pl = Line(piece)
                mo = OPT_LINE.match(pl.s)
                if mo:
                    label = mo.group(1) or mo.group(2) or mo.group(3)
                    opts.append([LABELS.get(label, len(opts)),
                                 pl.raw_from(mo.end()).strip()])
                    opt_pos.append((pg, ly))
                    state = 'opt'
                elif state == 'opt' and opts:
                    opts[-1][1] += ' ' + piece.strip()
                else:
                    qtext.append(piece.strip())
        if ans_ord is None and opts:
            marked = [k for k, (pg, ly) in enumerate(opt_pos)
                      if any(h['page'] == pg and h['y0'] - 3 <= ly <= h['y1'] + 3
                             for h in highlights)]
            if len(marked) == 1:          # a single highlighted option marks the answer
                ans_ord = marked[0]
                ans_hl = True
        marks = set(b.get('markers', []))          # (page, num) pairs, page-exact
        notes = [f['text'] for f in footnotes
                 if (f['page'], f['num']) in marks]
        if notes:
            ref = ref + notes
        out.append({'file': b['file'], 'page': b['page'], 'num': b['num'], 'qnum': b['qnum'],
                    'year': b.get('year', ''),
                    'question': re.sub(r'\s+', ' ', ' '.join(qtext)).strip(),
                    'labels': [o[0] for o in opts],
                    'options': [re.sub(r'\s+', ' ', o[1]).strip() for o in opts],
                    'ans': ans_ord, 'ans_text': ans_text, 'ans_from_highlight': ans_hl,
                    'ref': re.sub(r'\s+', ' ', ' '.join(ref)).strip(),
                    'raw': b['raw']})
    return out


if __name__ == '__main__':
    allq = []
    for f in sorted(glob.glob(os.path.join(BASE, 'txt', '*.json'))):
        if 'مدرك' in f:
            continue
        qs = parse_file(f)
        nums = [q['num'] for q in qs]
        miss = [n for n in range(1, max(nums) + 1) if n not in nums] if nums else []
        noans = [q['num'] for q in qs if q['ans'] is None]
        fewopt = [q['num'] for q in qs if len(q['options']) < 3]
        badlab = [q['num'] for q in qs if q['labels'] != sorted(set(q['labels']))]
        print(os.path.basename(f)[:34], 'Q', len(qs), '| gaps', miss,
              '| no-ord', noans, '| <3opts', fewopt, '| labels', badlab)
        allq += qs
    json.dump(allq, io.open(os.path.join(BASE, 'pdf_questions.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    print('TOTAL', len(allq))
