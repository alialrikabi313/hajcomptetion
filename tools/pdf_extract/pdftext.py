import re
# -*- coding: utf-8 -*-
"""Decode Arabic text from PDFs whose ToUnicode maps are broken,
by reversing the embedded subset font's cmap (gid -> presentation form)
and decomposing GSUB ligatures."""
import io, unicodedata
import fitz
from fontTools.ttLib import TTFont


def _collect_gsub(font):
    """returns (ligatures: out -> [components], singles: out -> in)"""
    ligs, singles = {}, {}
    if 'GSUB' not in font:
        return ligs, singles
    gs = font['GSUB'].table
    for lk in gs.LookupList.Lookup:
        for st in lk.SubTable:
            t = lk.LookupType
            sub = st
            if t == 7:
                t = st.ExtensionLookupType
                sub = st.ExtSubTable
            if t == 4:
                for first, lst in sub.ligatures.items():
                    for lg in lst:
                        ligs.setdefault(lg.LigGlyph, [first] + list(lg.Component))
            elif t == 1:
                for src, dst in sub.mapping.items():
                    if dst != src:
                        singles.setdefault(dst, src)
            elif t == 3:
                for src, alt in sub.alternates.items():
                    for dst in alt:
                        if dst != src:
                            singles.setdefault(dst, src)
            elif t == 2:
                for src, seq in sub.mapping.items():
                    glyphs = seq.Substitute if hasattr(seq, 'Substitute') else seq
                    if len(glyphs) == 1 and glyphs[0] != src:
                        singles.setdefault(glyphs[0], src)
    return ligs, singles


def font_decoder(doc, fontfile_xref):
    data = doc.xref_stream(fontfile_xref)
    f = TTFont(io.BytesIO(data), lazy=False)
    order = f.getGlyphOrder()
    name2gid = {n: i for i, n in enumerate(order)}
    rev = {}
    try:
        cm = f.getBestCmap()
    except Exception:
        cm = {}
    for u, n in cm.items():
        g = name2gid.get(n)
        if g is not None and g not in rev:
            rev[g] = chr(u)
    ligs, singles = _collect_gsub(f)

    def resolve(gname, depth=0):
        g = name2gid.get(gname)
        if g is not None and g in rev:
            return rev[g]
        if depth > 4:
            return ''
        comps = ligs.get(gname)
        if comps:
            return ''.join(resolve(c, depth + 1) for c in comps)
        src = singles.get(gname)
        if src and src != gname:
            return resolve(src, depth + 1)
        if gname.startswith('uni') and len(gname) >= 7:
            try:
                return chr(int(gname[3:7], 16))
            except ValueError:
                pass
        return ''

    table = {}
    for gname, g in name2gid.items():
        s = resolve(gname)
        if s:
            table[g] = s
    return table


def build_tables(doc):
    """gid tables keyed by font basename"""
    tables = {}
    for xref in range(1, doc.xref_length()):
        try:
            sub = doc.xref_get_key(xref, 'Subtype')
        except Exception:
            continue
        if not sub or sub[0] != 'name' or sub[1] not in ('/CIDFontType2', '/TrueType'):
            continue
        desc = doc.xref_get_key(xref, 'FontDescriptor')
        if not desc or desc[0] != 'xref':
            continue
        dref = int(desc[1].split()[0])
        ff = doc.xref_get_key(dref, 'FontFile2')
        if not ff or ff[0] != 'xref':
            continue
        base = doc.xref_get_key(xref, 'BaseFont')[1].lstrip('/')
        if '+' in base:
            base = base.split('+', 1)[1]
        base = base.replace('#20', ' ')
        try:
            tbl = font_decoder(doc, int(ff[1].split()[0]))
        except Exception:
            tbl = {}
        if len(tbl) > len(tables.get(base, {})):
            tables[base] = tbl
    return tables


AR_DIACRITICS = set('\u064b\u064c\u064d\u064e\u064f\u0650\u0651\u0652\u0653\u0654\u0655\u0670')


def normalize_forms(s):
    out = []
    for ch in s:
        d = unicodedata.normalize('NFKD', ch)
        out.append(d if d else ch)
    return ''.join(out)


LTR = re.compile(r'[0-9A-Za-z٠-٩۰-۹]'
                 r'[0-9A-Za-z٠-٩۰-۹.,:/\-]*')


def fix_runs(s):
    """digits/latin were stored visually; flip each run back to logical order"""
    return LTR.sub(lambda m: m.group(0)[::-1], s)


GLOBAL = {}

# glyphs the font's cmap/GSUB cannot resolve, identified by rendering them
OVERRIDES = {
    'Sakkal Majalla': {632: 'ه', 634: 'ه', 1672: 'ه', 1730: 'هي'},
    'Sakkal Majalla,Bold': {632: 'ه', 634: 'ه', 1672: 'ه', 1730: 'هي'},
}


def load_global(paths):
    """merge gid tables of the same font across files (Word keeps original gids)"""
    for f in paths:
        d = fitz.open(f)
        for base, tbl in build_tables(d).items():
            g = GLOBAL.setdefault(base, {})
            for gid, ch in tbl.items():
                g.setdefault(gid, ch)
        d.close()
    return GLOBAL


def page_lines(doc, tables, pno, ytol=3.0):
    """decoded text lines; combining marks are re-attached to their base letter"""
    page = doc[pno]
    bases, marks = [], []
    for sp in page.get_texttrace():
        base = sp['font']
        tbl = dict(GLOBAL.get(base, {}))
        tbl.update(tables.get(base) or {})
        tbl.update(OVERRIDES.get(base, {}))
        for ucs, gid, org, bbox in sp['chars']:
            if gid == -1:
                continue
            t = tbl[gid] if gid in tbl else (chr(ucs) if ucs else '')
            if not t:
                continue
            w = bbox[2] - bbox[0]
            item = {'y': org[1], 'x': org[0], 'x0': bbox[0], 'x1': bbox[2], 't': t,
                    'cx': (bbox[0] + bbox[2]) / 2,
                    'color': sp['color'], 'size': sp['size']}
            if t.strip('ـ') and all(unicodedata.combining(c) or c == 'ٔ'
                                          or c == 'ٕ' for c in t):
                marks.append(item)
            else:
                bases.append(item)

    lines = []
    for b in sorted(bases, key=lambda i: i['y']):
        for ln in lines:
            if abs(ln['y'] - b['y']) <= ytol:
                ln['items'].append(b)
                break
        else:
            lines.append({'y': b['y'], 'items': [b]})

    for ln in lines:
        ln['marks'] = []
    for m in marks:
        if not lines:
            break
        # a mark sits above its baseline (or just below it for kasra/shadda)
        def covers(l):
            return any(i.get('x0', i['x']) - 1 <= m['cx'] <= i['x1'] + 1
                       for i in l['items'])

        below = [l for l in lines if 0 <= l['y'] - m['y'] <= 13]
        near = [l for l in lines if abs(l['y'] - m['y']) <= 5]
        pool = [l for l in below if covers(l)] or [l for l in near if covers(l)]             or below or near
        if not pool:
            continue
        ln = min(pool, key=lambda l: abs(l['y'] - m['y']))
        ln['marks'].append(m)

    out = []
    for ln in sorted(lines, key=lambda l: l['y']):
        items = sorted(ln['items'], key=lambda i: -i['x'])
        for m in ln['marks']:
            # attach each mark right after the letter it sits on
            host = None
            for k, it in enumerate(items):
                if it.get('x0', it['x']) - 0.2 <= m['cx'] <= it['x1'] + 0.2:
                    host = k
                    break
            if host is None:
                # mark sits in a gap: it belongs to the letter on its left,
                # i.e. the next letter in reading order
                left = [k for k, it in enumerate(items) if it['x1'] <= m['cx']]
                if left:
                    host = max(left, key=lambda k: items[k]['x1'])
                elif items:
                    host = min(range(len(items)),
                               key=lambda k: abs(items[k].get('cx', items[k]['x']) - m['cx']))
            items.insert((host + 1) if host is not None else 0, m)
        txt = unicodedata.normalize(
            'NFC', fix_runs(normalize_forms(''.join(i['t'] for i in items))))
        txt = txt.replace('ـ', '')                     # kashida is decorative
        txt = txt.replace('ىي', 'ي')          # ligature artefact: نسىي -> نسي
        txt = txt.replace('ھ', 'ه').replace('ی', 'ي')
        txt = re.sub(r'\s+([ً-ْٰ])', lambda m: m.group(1), txt)
        txt = re.sub(r'[ 	]{2,}', ' ', txt)
        cols = {i['color'] for i in items}
        sizes = [i['size'] for i in items if i['t'].strip()]
        size = round(max(sizes), 1) if sizes else 0
        out.append((round(ln['y'], 1), txt, cols, size))
    return out
