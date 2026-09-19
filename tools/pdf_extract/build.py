# -*- coding: utf-8 -*-
"""Rebuild assets/haj_questions.json straight from the source PDFs."""
import io, os, re, sys, json, difflib, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import parse as P
from compare import TOPIC_OF_FILE
from extract2 import Line

BASE = os.path.dirname(os.path.abspath(__file__))
PROJ = r'C:\Users\msi\StudioProjects\hajcomptetion'
HAYD = 'أحكام الحائض والمستحاضة'

def _spaced(word):
    return r'\s*'.join(word)


ORD_RE = re.compile(r'الج\s*[وا\s]{1,4}ب\s*' + _spaced('الصحيح') +
                    r'.{0,45}?(' + '|'.join(_spaced(w) for w in
                                            ('الأولى', 'الاولى', 'الأول', 'الاول',
                                             'الثاني', 'الثانى', 'الثالث',
                                             'الرابع')) + r')(?![ىة])')
STOP_RE = re.compile(r'(?:^|\s)(?:الجواب\s*:|السؤال\s*:)')
YEAR_TAIL = re.compile(r'\s*في\s*سنة\s*[٠-٩۰-۹0-9]+.*$')
PARENS = str.maketrans({'(': ')', ')': '('})
HAYD_WORDS = re.compile(r'حائض|الحيض|حاضت|تحيض|المستحاضة|استحاضة|النفساء|نفاس|طهرها|'
                        r'الدم\s|دم\s+الحيض|المرأة\s+الحائض')


LETTER = 'بتثجحخدذرزسشصضطظعغفقكلمنهيةى'
MARKS = 'ً-ْ'
# Word splits words for justification; these glue the pieces back together
GLUE_NEXT = re.compile(r'(?<=\s)([' + LETTER + '][' + MARKS + r']?)\s+'
                       r'(?=[' + LETTER + r'][' + MARKS + r']?(?:\s|$|[.،:؟]))')
GLUE_PREV = re.compile(r'(?<=\S)\s+([' + LETTER + '][' + MARKS + r']?)(?=\s|$|[.،:؟])')
GLUE_ALEF = re.compile(r'([' + MARKS + r'])\s+ا(?=\s|$|[.،:؟])')
GLUE_ALEF2 = re.compile(r'(?<=[' + LETTER + r'])\s+ا(?=\s|$|[.،:؟])')


def _reglue(t):
    for _ in range(3):
        t2 = GLUE_NEXT.sub(lambda m: m.group(1), t)
        t2 = GLUE_ALEF.sub(lambda m: m.group(1) + 'ا', t2)
        t2 = GLUE_ALEF2.sub('ا', t2)
        t2 = GLUE_PREV.sub(lambda m: m.group(1), t2)
        if t2 == t:
            break
        t = t2
    return t


def clean(t):
    t = (t or '').translate(PARENS)
    t = t.replace('ک', 'ك').replace('ی', 'ي').replace('ھ', 'ه')
    t = t.replace('هيي', 'هي').replace('ىي', 'ي')
    t = t.replace('سات رة', 'ساترة')      # كلمة شطرها التنسيق في الأصل
    t = re.sub(r'\s+', ' ', t).strip()
    t = re.sub(r'\s+([،.؟:؛])', r'', t)
    t = re.sub(r'\(\s+', '(', t)
    t = re.sub(r'\s+\)', ')', t)
    t = _reglue(t)
    return t


def clean_ref(raw):
    t = raw or ''
    ln = Line(t)
    m = ORD_RE.search(ln.s)
    if m:
        # «الجواب الصحيح حسب كتاب المناسك هو …» — التقييد جزء من الحكم فيبقى
        qualifier = ln.s[m.start():m.end()]
        if 'حسب' not in qualifier:
            t = ln.raw_from(m.end())
    st = STOP_RE.search(t)
    if st and st.start() > 20:
        t = t[:st.start()]
    t = YEAR_TAIL.sub('', t)
    t = clean(t)
    t = re.sub(r'^[\-–:،.\s]+', '', t)
    return t


def sim(a, b):
    return difflib.SequenceMatcher(None, P.norm(a), P.norm(b)).ratio()


def ordered_options(q):
    if q['labels'] and len(q['labels']) == len(q['options']):
        order = sorted(range(len(q['options'])), key=lambda i: q['labels'][i])
        return [q['options'][i] for i in order]
    return list(q['options'])


def main():
    pdfq = json.load(io.open(os.path.join(BASE, 'pdf_questions.json'), encoding='utf-8'))
    mad = json.load(io.open(os.path.join(BASE, 'madrak_questions.json'), encoding='utf-8'))
    ov = json.load(io.open(os.path.join(BASE, 'overrides.json'), encoding='utf-8'))
    old = json.load(io.open(os.path.join(PROJ, 'assets', 'haj_questions.json'), encoding='utf-8'))

    old_by_topic = collections.defaultdict(list)
    for b in old:
        old_by_topic[b['topic']].append(b)
    madrak_topics = [t for t in old_by_topic if t not in TOPIC_OF_FILE.values()]
    old_madrak = [b for t in madrak_topics for b in old_by_topic[t]]

    def match_old(question, pool):
        best, sc = None, 0.0
        for b in pool:
            s = sim(question, b['question'])
            if s > sc:
                best, sc = b, s
        return (best, sc) if sc >= 0.75 else (None, sc)

    out, notes = [], []
    # ---------- the eleven topic files ----------
    for q in pdfq:
        key = '%s|%d' % (q['file'], q['num'])
        o = ov.get(key, {})
        if o.get('skip'):
            notes.append({'kind': 'skipped', 'file': q['file'], 'num': q['num'],
                          'why': o.get('note', '')})
            continue
        question = clean(o.get('question', q['question']))
        opts = [clean(x) for x in (o['options'] if 'options' in o else ordered_options(q))]
        ans = o['ans'] if 'ans' in o else q['ans']
        ref = clean_ref(o.get('ref', q['ref']))
        topic = TOPIC_OF_FILE[q['file']]
        pool = old_by_topic[topic]
        prev, sc = match_old(question, pool)
        if ans is None or not (0 <= ans < len(opts)) or len(opts) < 2:
            notes.append({'kind': 'dropped_no_answer', 'file': q['file'],
                          'num': q['num'], 'question': question,
                          'was_in_app': bool(prev)})
            continue
        rec = {'topic': topic, 'question': question, 'options': opts,
               'correct_answer': opts[ans], 'answer_reference': ref,
               '_year': q.get('year', ''), '_src': '%s#%d' % (q['file'], q['num'])}
        if prev and prev.get('topics'):
            rec['topics'] = prev['topics']
        out.append(rec)

    # ---------- the 1447 exam booklet (مدرك) ----------
    for q in mad:
        key = 'مدرك|%d' % q['num']
        o = ov.get(key, {})
        question = clean(o.get('question', q['question']))
        opts = [clean(x) for x in (o['options'] if 'options' in o else ordered_options(q))]
        ans = o['ans'] if 'ans' in o else q['ans']
        ref = clean_ref(o.get('ref', q['ref']))
        prev, sc = match_old(question, old_madrak)
        if prev is None:
            notes.append({'kind': 'madrak_unmatched', 'num': q['num'], 'question': question})
            continue
        if ans is None or not (0 <= ans < len(opts)):
            notes.append({'kind': 'dropped_no_answer', 'file': 'مدرك',
                          'num': q['num'], 'question': question, 'was_in_app': True})
            continue
        rec = {'topic': prev['topic'], 'question': question, 'options': opts,
               'correct_answer': opts[ans],
               'answer_reference': ref or prev.get('answer_reference', ''),
               '_year': '1447', '_src': 'مدرك#%d' % q['num']}
        if prev.get('topics'):
            rec['topics'] = prev['topics']
        out.append(rec)

    # ---------- الحائض والمستحاضة: keep the cross-topic grouping ----------
    for rec in out:
        if rec['topic'] == HAYD:
            continue
        blob = rec['question'] + ' ' + ' '.join(rec['options'])
        if HAYD_WORDS.search(blob):
            tp = rec.get('topics') or [rec['topic']]
            if HAYD not in tp:
                tp = tp + [HAYD]
            rec['topics'] = tp

    # ---------- de-duplicate on the question text, newest year wins ----------
    best = {}
    for rec in out:
        k = P.norm(rec['question'])
        cur = best.get(k)
        if cur is None:
            best[k] = rec
            continue
        keep, drop = (rec, cur) if rec.get('_year', '') > cur.get('_year', '') else (cur, rec)
        notes.append({'kind': 'duplicate', 'question': drop['question'],
                      'dropped_src': drop.get('_src'), 'dropped_year': drop.get('_year'),
                      'kept_src': keep.get('_src'), 'kept_year': keep.get('_year')})
        best[k] = keep
    order = {P.norm(rec['question']): i for i, rec in enumerate(out)}
    final = sorted(best.values(), key=lambda r: order[P.norm(r['question'])])
    srcmap = [rec.get('_src') for rec in final]
    json.dump(srcmap, io.open(os.path.join(BASE, 'bank_src_map.json'), 'w',
                              encoding='utf-8'), ensure_ascii=False)
    for rec in final:
        rec.pop('_year', None)
        rec.pop('_src', None)

    json.dump(final, io.open(os.path.join(BASE, 'new_bank.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    json.dump(notes, io.open(os.path.join(BASE, 'build_notes.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    c = collections.Counter(n['kind'] for n in notes)
    print('new bank:', len(final), '| old bank:', len(old))
    print('notes:', dict(c))
    tc = collections.Counter(rec['topic'] for rec in final)
    for t, n in tc.most_common():
        print('   %-46s %d' % (t, n))
    print('with topics[]:', sum(1 for r in final if r.get('topics')))
    print('with reference:', sum(1 for r in final if r['answer_reference']))


if __name__ == '__main__':
    main()
