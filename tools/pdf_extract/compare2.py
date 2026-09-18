# -*- coding: utf-8 -*-
import io, os, re, json, sys, difflib, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import parse as P
from compare import TOPIC_OF_FILE

BASE = os.path.dirname(os.path.abspath(__file__))
PROJ = r'C:\Users\msi\StudioProjects\hajcomptetion'


def sim(a, b):
    return difflib.SequenceMatcher(None, P.norm(a), P.norm(b)).ratio()


pdfq = json.load(io.open(os.path.join(BASE, 'pdf_questions.json'), encoding='utf-8'))
for q in pdfq:                      # options in label order (أ ب ج د)
    if q['labels'] and len(q['labels']) == len(q['options']):
        order = sorted(range(len(q['options'])), key=lambda i: q['labels'][i])
        q['options'] = [q['options'][i] for i in order]
bank = json.load(io.open(os.path.join(PROJ, 'assets', 'haj_questions.json'), encoding='utf-8'))
by_topic = collections.defaultdict(list)
for q in pdfq:
    by_topic[TOPIC_OF_FILE[q['file']]].append(q)

rows = []
for i, b in enumerate(bank):
    topic = b['topic']
    if topic not in by_topic:
        continue
    best, score = None, 0.0
    for c in by_topic[topic]:
        s = sim(b['question'], c['question'])
        if s > score:
            best, score = c, s
    r = {'idx': i, 'topic': topic, 'score': round(score, 3),
         'pdf_num': best['num'] if best else None,
         'bank_q': b['question'], 'pdf_q': best['question'] if best else '',
         'bank_opts': b['options'], 'pdf_opts': best['options'] if best else [],
         'bank_ans': b['correct_answer'],
         'pdf_ans': (best['options'][best['ans']] if best and best['ans'] is not None
                     and best['ans'] < len(best['options']) else None),
         'pdf_ans_idx': best['ans'] if best else None,
         'pdf_ans_text': best.get('ans_text') if best else None,
         'bank_ref': b.get('answer_reference', ''), 'pdf_ref': best['ref'] if best else ''}
    flags = []
    if score < 0.7:
        flags.append('NO_MATCH')
    else:
        if score < 0.95:
            flags.append('QTEXT')
        # option sets
        bo, po = b['options'], best['options']
        if len(bo) != len(po):
            flags.append('OPTCOUNT')
        unmatched = []
        for o in bo:
            if not po or max(sim(o, p) for p in po) < 0.9:
                unmatched.append(o)
        if unmatched:
            flags.append('OPTTEXT')
        # answer
        if r['pdf_ans'] is None:
            flags.append('NOANS')
        elif sim(b['correct_answer'], r['pdf_ans']) < 0.85:
            flags.append('ANSWER')
    r['flags'] = flags
    if flags:
        rows.append(r)

json.dump(rows, io.open(os.path.join(BASE, 'report2.json'), 'w', encoding='utf-8'),
          ensure_ascii=False, indent=1)
c = collections.Counter(f for r in rows for f in r['flags'])
print('checked', sum(1 for b in bank if b['topic'] in by_topic), 'flagged', len(rows))
for k, v in c.most_common():
    print('   ', k, v)
