# -*- coding: utf-8 -*-
"""Sort the OCR verification results into things a human must look at."""
import io, os, json, sys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
BASE = os.path.dirname(os.path.abspath(__file__))

r = json.load(io.open(os.path.join(BASE, 'verify_results.json'), encoding='utf-8'))
bad_answer = [x for x in r if x.get('answer_ok') is False]
no_ord = [x for x in r if x.get('answer_ok') is None and x['status'] == 'OK']
bad_q = [x for x in r if x.get('q_score', 1) < 0.75]
opt_all_bad = [x for x in r if x.get('opt_scores') and
               all(s < 0.7 for s in x['opt_scores'])]
opt_some_bad = [x for x in r if x.get('opt_scores') and
                any(s < 0.55 for s in x['opt_scores']) and x not in opt_all_bad]
unloc = [x for x in r if x['status'] != 'OK']

print('total', len(r))
print('ANSWER mismatch      :', len(bad_answer))
print('ordinal unreadable   :', len(no_ord))
print('question text < .75  :', len(bad_q))
print('all options < .70    :', len(opt_all_bad))
print('an option < .55      :', len(opt_some_bad))
print('unlocated            :', len(unloc))

todo = []
seen = set()
for group, name in ((bad_answer, 'ANSWER'), (unloc, 'UNLOCATED'), (opt_all_bad, 'OPTIONS'),
                    (bad_q, 'QUESTION'), (opt_some_bad, 'OPTION'), (no_ord, 'ORDINAL')):
    for x in group:
        if x['i'] in seen:
            continue
        seen.add(x['i'])
        todo.append({'i': x['i'], 'why': name, 'src': x.get('src'),
                     'q': x['question'][:90], 'q_score': x.get('q_score'),
                     'opt': x.get('opt_scores'), 'ocr_ord': x.get('ocr_ord'),
                     'bank_idx': x.get('bank_idx')})
json.dump(todo, io.open(os.path.join(BASE, 'todo.json'), 'w', encoding='utf-8'),
          ensure_ascii=False, indent=1)
print('to review by eye:', len(todo))
print(collections.Counter(t['why'] for t in todo))
